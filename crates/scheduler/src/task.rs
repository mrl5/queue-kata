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
            typ as "typ: model::TaskType",
            state as "state: model::TaskState",
            created_at,
            deleted_at,
            not_before
        FROM task
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

#[derive(Serialize)]
pub struct DeleteTaskResp {
    id: Uuid,
    state: model::TaskState,
}
pub async fn delete_task(
    Extension(db): Extension<DB>,
    Path(id): Path<Uuid>,
) -> JsonResult<DeleteTaskResp> {
    let task = sqlx::query_as!(
        DeleteTaskResp,
        r#"
        UPDATE task
        SET deleted_at = now(), state = 'deleted'
        WHERE id = $1::uuid AND state != 'deleted'
        RETURNING
            id,
            state as "state: model::TaskState"
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

#[derive(sqlx::Type, Deserialize)]
pub struct TaskFilter {
    pub typ: Option<model::TaskType>,
    pub state: Option<model::TaskState>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct ListTasksResp {
    pub tasks: Vec<model::TaskSummary>,
    pub page: usize,
    pub per_page: usize,
}

pub async fn list_tasks(
    Extension(db): Extension<DB>,
    Query(pagination): Query<Pagination>,
    Query(task_filter): Query<TaskFilter>,
) -> JsonResult<ListTasksResp> {
    let (per_page, offset, page) = paginate(pagination);
    let mut query: QueryBuilder<Postgres> = QueryBuilder::new(
        r#"
        SELECT
            id,
            typ,
            state
        FROM task
        "#,
    );
    query = task_filter.append_query_with_fragment(query);
    query
        .push(" ORDER BY id desc")
        .push(" LIMIT ")
        .push_bind(per_page as i64)
        .push(" OFFSET ")
        .push_bind(offset as i64);
    let rows = query
        .build_query_as::<model::TaskSummary>()
        .fetch_all(&db)
        .await?;

    let resp = ListTasksResp {
        tasks: rows,
        page,
        per_page,
    };
    Ok(Json(resp))
}

#[derive(Deserialize)]
pub struct CreateTaskReq {
    pub task_type: model::TaskType,
    pub not_before: Option<DateTime<Utc>>,
}

#[derive(Serialize)]
pub struct CreateTaskResp {
    task_id: Uuid,
    task_state: model::TaskState,
}

pub async fn create_task(
    Extension(db): Extension<DB>,
    Json(body): Json<CreateTaskReq>,
) -> Result<(StatusCode, Json<CreateTaskResp>), Error> {
    let id: Uuid = Ulid::new().into();

    tracing::info!("creating task {:#?} ...", &body.task_type);

    let task = sqlx::query_as!(
        model::CreatedTask,
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
        RETURNING
            id,
            state as "state: model::TaskState"
        "#,
        id,
        body.task_type as model::TaskType,
        body.not_before
    )
    .fetch_one(&db)
    .await?;

    tracing::info!("created task {}", &task.id);

    let resp = CreateTaskResp {
        task_id: task.id,
        task_state: task.state,
    };
    Ok((StatusCode::ACCEPTED, Json(resp)))
}

impl TaskFilter {
    pub fn append_query_with_fragment(
        self,
        mut query: QueryBuilder<Postgres>,
    ) -> QueryBuilder<Postgres> {
        if self.typ.is_none() && self.state.is_none() {
            return query;
        } else if self.typ.is_none() && self.state.is_some() {
            query
                .push(" WHERE state = ")
                .push_bind(self.state)
                .push("::task_state");
        } else if self.typ.is_some() && self.state.is_none() {
            query
                .push(" WHERE typ = ")
                .push_bind(self.typ)
                .push("::task_type");
        } else if self.typ.is_some() && self.state.is_some() {
            query
                .push(" WHERE typ = ")
                .push_bind(self.typ)
                .push("::task_type")
                .push(" AND state = ")
                .push_bind(self.state)
                .push("::task_state");
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
        let test_cases = vec![
            (
                TaskFilter {
                    typ: None,
                    state: None,
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task",
            ),
            (
                TaskFilter {
                    typ: Some(model::TaskType::TypeA),
                    state: None,
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task WHERE typ = $1::task_type",
            ),
            (
                TaskFilter {
                    typ: None,
                    state: Some(model::TaskState::Pending),
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task WHERE state = $1::task_state",
            ),
            (
                TaskFilter {
                    typ: Some(model::TaskType::TypeA),
                    state: Some(model::TaskState::Pending),
                },
                QueryBuilder::new(test_sql) as QueryBuilder<Postgres>,
                "SELECT id FROM task WHERE typ = $1::task_type AND state = $2::task_state",
            ),
        ];

        for (input, query, expected) in test_cases {
            let result = input.append_query_with_fragment(query);
            assert_eq!(result.sql(), expected);
        }
    }
}
