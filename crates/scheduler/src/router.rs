use crate::task::{create_task, list_tasks};
use axum::{
    routing::{get, post},
    Router,
};

pub fn get_task_router() -> Router {
    Router::new()
        .route("/list", get(list_tasks))
        .route("/create", post(create_task))
}
