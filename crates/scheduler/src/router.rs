use crate::task::list_tasks;
use axum::{routing::get, Router};

pub fn get_task_router() -> Router {
    Router::new().route("/list", get(list_tasks))
}
