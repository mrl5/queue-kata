use axum::response::Json;
use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct Health {
    status: HealthStatus,
}

#[derive(Eq, Debug, Hash, PartialEq, Serialize)]
pub enum HealthStatus {
    Healthy,
}

pub async fn run_healthcheck() -> Json<Health> {
    let check = Health {
        status: HealthStatus::Healthy,
    };
    tracing::info!("{:?}", check);
    Json(check)
}
