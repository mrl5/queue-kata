use crate::task::{create_task, delete_task, get_task, list_tasks};
use axum::{
    routing::{get, post},
    Router,
};

pub fn get_task_router() -> Router {
    Router::new()
        .route("/:id", get(get_task).delete(delete_task))
        .route("/list", get(list_tasks))
        .route("/create", post(create_task))
}
