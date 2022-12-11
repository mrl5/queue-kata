use crate::error::Error;
use sqlx::{postgres::PgPoolOptions, Pool, Postgres};
use std::time::Duration;

pub const DEFAULT_MAX_CONNECTIONS: u32 = 100;

pub type DB = Pool<Postgres>;

pub async fn migrate(db: &DB) -> Result<(), Error> {
    match sqlx::migrate!("../../migrations").run(db).await {
        Ok(_) => Ok(()),
        Err(err) => Err(err),
    }?;

    Ok(())
}

pub async fn connect(app_name: Option<&str>) -> anyhow::Result<DB> {
    use anyhow::Context;

    let database_url = std::env::var("DATABASE_URL")
        .map_err(|_| Error::BadConfig("DATABASE_URL env var is missing".to_string()))?;

    let max_connections = match std::env::var("DATABASE_CONNECTIONS") {
        Ok(n) => n.parse::<u32>().context("invalid DATABASE_CONNECTIONS")?,
        Err(_) => DEFAULT_MAX_CONNECTIONS,
    };

    Ok(pool_db(&database_url, max_connections, app_name).await?)
}

async fn pool_db(
    database_url: &str,
    max_connections: u32,
    app_name: Option<&str>,
) -> Result<DB, Error> {
    PgPoolOptions::new()
        .max_connections(max_connections)
        .max_lifetime(Duration::from_secs(5 * 60))
        .connect(
            format!(
                "{database_url}&application_name={}",
                app_name.unwrap_or(env!("CARGO_PKG_NAME"))
            )
            .as_str(),
        )
        .await
        .map_err(|err| Error::ConnectingToDatabase(err.to_string()))
}
