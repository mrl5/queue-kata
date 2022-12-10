use axum::{Extension, Json};
use common::{db::DB, error::JsonResult};
use serde::{Deserialize, Serialize};

pub mod model;

#[derive(Serialize, Deserialize, Debug)]
pub struct ListTasks {
    pub tasks: Vec<model::Task>,
}

pub async fn list_tasks(Extension(db): Extension<DB>) -> JsonResult<ListTasks> {
    // todo: pagination
    // todo: filtering by state
    // todo: filtering by type
    let rows = sqlx::query_as!(
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
        "#
    )
    .fetch_all(&db)
    .await?;

    let resp = ListTasks { tasks: rows };
    Ok(Json(resp))
}
