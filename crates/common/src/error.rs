use axum::{
    body::{self, BoxBody},
    http::StatusCode,
    response::IntoResponse,
    response::Response,
    Json,
};
use sqlx::migrate::MigrateError;
use thiserror::Error;

pub type JsonResult<T> = std::result::Result<Json<T>, Error>;

#[derive(Debug, Error)]
pub enum Error {
    #[error("Bad config: {0}")]
    BadConfig(String),
    #[error("Connecting to database: {0}")]
    ConnectingToDatabase(String),
    #[error("Sql error: {0}")]
    SqlErr(#[from] sqlx::Error),
    #[error("Migrating database: {0}")]
    DatabaseMigration(#[from] MigrateError),
    #[error("Bad request: {0}")]
    BadRequest(String),
    #[error(transparent)]
    Anyhow(#[from] anyhow::Error),
}

impl Error {
    /// https://docs.rs/anyhow/1/anyhow/struct.Error.html#display-representations
    pub fn alt(&self) -> String {
        format!("{:#}", self)
    }
}

pub fn to_anyhow<T: 'static + std::error::Error + Send + Sync>(e: T) -> anyhow::Error {
    From::from(e)
}

impl IntoResponse for Error {
    fn into_response(self) -> Response<BoxBody> {
        let e = &self;
        let body = body::boxed(body::Full::from(e.to_string()));
        let status = match self {
            Self::SqlErr(_) | Self::BadRequest(_) => StatusCode::BAD_REQUEST,
            _ => StatusCode::INTERNAL_SERVER_ERROR,
        };
        tracing::error!(error = e.to_string());
        Response::builder()
            .header("Content-Type", "text/plain")
            .status(status)
            .body(body)
            .unwrap()
    }
}
