use crate::tracing::MyOnResponse;
use axum::{Server, Router};
use std::net::SocketAddr;
use tower::ServiceBuilder;
use tower_http::trace::TraceLayer;

pub async fn run_server(address: SocketAddr, router: Router) -> anyhow::Result<()> {
    let middleware_stack = ServiceBuilder::new().layer(
        TraceLayer::new_for_http()
            .on_request(())
            .on_response(MyOnResponse {}),
    );

    let app = router.layer(middleware_stack);

    tracing::info!("Starting server ...");
    let server = async {
        Server::bind(&address)
            .serve(app.into_make_service())
            .await?;
        Ok(()) as anyhow::Result<()>
    };

    println!("Server running at http://{}", address);
    server.await?;
    Ok(())
}
