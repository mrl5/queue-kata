use axum::{
    extract::{Path, Query},
    http::StatusCode,
    Extension, Json,
};
use chrono::{DateTime, Utc};
use common::{
    db::DB,
    error::{Error, JsonResult},
    utils::{paginate, Pagination},
};
use serde::{Deserialize, Serialize};
use sqlx::{Postgres, QueryBuilder};
use ulid::Ulid;
use uuid::Uuid;

pub mod model;

pub async fn get_task(
    Extension(db): Extension<DB>,
    Path(id): Path<Uuid>,
) -> JsonResult<model::Task> {
    let task = sqlx::query_as!(
        model::Task,
        r#"
        SELECT
            id,
            typ,
            state,
            created_at,
            not_before,
            inactive_since
        FROM task_state
        WHERE id = $1::uuid
        "#,
        id,
    )
    .fetch_optional(&db)
    .await?;

    if let Some(t) = task {
        Ok(Json(t))
    } else {
        Err(Error::NotFound(id.to_string()))
    }
}

pub async fn delete_task(
    Extension(db): Extension<DB>,
    Path(id): Path<Uuid>,
) -> JsonResult<model::TaskSnapshot> {
    let forbidden_states = vec![model::TaskState::Processing.to_string()];
    let task = sqlx::query_as!(
        model::TaskSnapshot,
        r#"
        WITH deleted_task as (
            UPDATE task
            SET inactive_since = now(), state = $1
            FROM (
                SELECT id as task_id FROM task_state
                WHERE id = $2::uuid
                    AND state != ANY($3)
                    AND inactive_since IS NULL
            ) as t
            WHERE id = t.task_id
            RETURNING id, state, inactive_since
        ) SELECT id, state, inactive_since FROM (
        SELECT id, state, inactive_since FROM deleted_task
        UNION ALL
        SELECT id, state, inactive_since FROM task
        WHERE id = $2::uuid AND state = $1
        ) t
        "#,
        model::TaskState::Deleted.to_string(),
        id,
        &forbidden_states,
    )
    .fetch_optional(&db)
    .await?;

    if let Some(t) = task {
        Ok(Json(t))
    } else {
        let task = sqlx::query!(
            r#"
            SELECT 1 as t FROM task WHERE id = $1::uuid
            "#,
            id,
        )
        .fetch_optional(&db)
        .await?;
        if task.is_none() {
            return Err(Error::NotFound(id.to_string()));
        }
        Err(Error::Forbidden(format!("{} can't be deleted anymore", id)))
    }
}

#[derive(Deserialize)]
pub struct TaskFilter {
    pub typ: Option<model::TaskType>,
    pub state: Option<model::TaskState>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct ListTasksResp {
    pub tasks: Vec<model::TaskSummary>,
    pub anchor: Option<Uuid>,
    pub per_page: usize,
}

pub async fn list_tasks(
    Extension(db): Extension<DB>,
    Query(pagination): Query<Pagination>,
    Query(task_filter): Query<TaskFilter>,
) -> JsonResult<ListTasksResp> {
    let (per_page, anchor) = paginate(pagination);
    let mut query: QueryBuilder<Postgres> = QueryBuilder::new(
        r#"
        SELECT
            id,
            typ,
            state
        FROM task_state_cached
        "#,
    );
    query = task_filter.append_query_with_fragment(query, anchor);
    query
        .push(" ORDER BY id desc")
        .push(" LIMIT ")
        .push_bind(per_page as i64);
    let rows = query
        .build_query_as::<model::TaskSummary>()
        .fetch_all(&db)
        .await?;

    let mut new_anchor = None;
    if rows.len() >= per_page {
        if let Some(last_row) = rows.last() {
            new_anchor = Some(last_row.id);
        }
    }

    let resp = ListTasksResp {
        tasks: rows,
        anchor: new_anchor,
        per_page,
    };
    Ok(Json(resp))
}

#[derive(Deserialize)]
pub struct CreateTaskReq {
    pub task_type: model::TaskType,
    pub not_before: Option<DateTime<Utc>>,
}

pub async fn create_task(
    Extension(db): Extension<DB>,
    Json(body): Json<CreateTaskReq>,
) -> Result<(StatusCode, Json<model::TaskId>), Error> {
    let id: Uuid = Ulid::new().into();

    tracing::info!("creating task {:#?} ...", &body.task_type);

    let task = sqlx::query_as!(
        model::TaskId,
        r#"
        INSERT INTO task (
            id,
            typ,
            not_before
        )
        VALUES (
            $1,
            $2,
            $3
        )
        RETURNING id
        "#,
        id,
        body.task_type.to_string(),
        body.not_before
    )
    .fetch_one(&db)
    .await?;

    tracing::info!("created task {}", id);
    Ok((StatusCode::ACCEPTED, Json(task)))
}

impl TaskFilter {
    pub fn append_query_with_fragment(
        self,
        mut query: QueryBuilder<Postgres>,
        anchor: Option<Uuid>,
    ) -> QueryBuilder<Postgres> {
        if anchor.is_none() && self.typ.is_none() && self.state.is_none() {
            return query;
        } else {
            query.push(" WHERE ");
            let mut separated = query.separated(" AND ");
            if let Some(a) = anchor {
                separated.push("id < ").push_bind_unseparated(a);
            }
            if let Some(t) = self.typ {
                separated
                    .push("typ = ")
                    .push_bind_unseparated(t.to_string());
            }
            if let Some(s) = self.state {
                separated
                    .push("state = ")
                    .push_bind_unseparated(s.to_string());
            }
        }

        query
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_should_serialize_into_where_sql_fragment() {
        let test_sql = "SELECT id FROM task";
        let anchor: Uuid = Ulid::new().into();
        let test_cases = vec![
            (
                None,
                TaskFilter {
                    typ: None,
                    state: None,
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task",
            ),
            (
                None,
                TaskFilter {
                    typ: Some(model::TaskType::TypeA),
                    state: None,
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task WHERE typ = $1",
            ),
            (
                None,
                TaskFilter {
                    typ: None,
                    state: Some(model::TaskState::Pending),
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task WHERE state = $1",
            ),
            (
                None,
                TaskFilter {
                    typ: Some(model::TaskType::TypeA),
                    state: Some(model::TaskState::Pending),
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task WHERE typ = $1 AND state = $2",
            ),
            (
                Some(anchor),
                TaskFilter {
                    typ: None,
                    state: None,
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task WHERE id < $1",
            ),
            (
                Some(anchor),
                TaskFilter {
                    typ: Some(model::TaskType::TypeA),
                    state: None,
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task WHERE id < $1 AND typ = $2",
            ),
            (
                Some(anchor),
                TaskFilter {
                    typ: None,
                    state: Some(model::TaskState::Pending),
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task WHERE id < $1 AND state = $2",
            ),
            (
                Some(anchor),
                TaskFilter {
                    typ: Some(model::TaskType::TypeA),
                    state: Some(model::TaskState::Pending),
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task WHERE id < $1 AND typ = $2 AND state = $3",
            ),
        ];

        for (anchor, filter, query, expected) in test_cases {
            let result = filter.append_query_with_fragment(query, anchor);
            assert_eq!(result.sql(), expected);
        }
    }
}
