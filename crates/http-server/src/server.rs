use crate::tracing::{MyMakeSpan, MyOnRequest, MyOnResponse, REQUEST_ID_HEADER};
use axum::{headers::HeaderName, Router, Server};
use std::net::SocketAddr;
use tower::ServiceBuilder;
use tower_http::request_id::{PropagateRequestIdLayer, SetRequestIdLayer};
use tower_http::{request_id::MakeRequestUuid, trace::TraceLayer};

pub async fn run_server(address: SocketAddr, router: Router) -> anyhow::Result<()> {
    let app = set_tracing(router);
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

fn set_tracing(router: Router) -> Router {
    let request_id = HeaderName::from_static(REQUEST_ID_HEADER);
    let middleware_stack = ServiceBuilder::new()
        .layer(SetRequestIdLayer::new(request_id.clone(), MakeRequestUuid))
        .layer(
            TraceLayer::new_for_http()
                .on_request(MyOnRequest {})
                .on_response(MyOnResponse {})
                .make_span_with(MyMakeSpan {}),
        )
        .layer(PropagateRequestIdLayer::new(request_id));

    router.layer(middleware_stack)
}
