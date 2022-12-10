use common::db;
use http_server::router::get_router;
use http_server::server::run_server;
use scheduler::router::get_task_router;
use std::net::SocketAddr;
use tracing::Level;
use tracing_subscriber::FmtSubscriber;

const DEFAULT_PORT: &str = "8000";

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .finish();
    tracing::subscriber::set_global_default(subscriber).expect("setting default subscriber failed");

    tracing::debug!("tracing initiated");
    let port = std::env::var("API_PORT").unwrap_or_else(|_| DEFAULT_PORT.to_owned());

    let db = db::connect().await?;
    db::migrate(&db).await?;

    let server_f = async {
        let address = SocketAddr::from(([0, 0, 0, 0], port.parse()?));
        let router = get_router().nest("/task", get_task_router());
        run_server(address, router, db.clone()).await?;
        Ok(()) as anyhow::Result<()>
    };
    futures::try_join!(server_f)?;
    Ok(())
}
