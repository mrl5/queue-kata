use crate::health_check::run_healthcheck;
use axum::{routing::get, Router};

pub fn get_router() -> Router {
    Router::new().route("/health", get(run_healthcheck))
}
