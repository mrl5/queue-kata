use hyper::{Request, Response};
use svix_ksuid::{KsuidLike, KsuidMs};
use tower_http::trace::{MakeSpan, OnRequest, OnResponse};
use tracing::Span;

pub const REQUEST_ID_HEADER: &str = "x-request-id";

#[derive(Clone)]
pub struct MyMakeSpan {}

impl<B> MakeSpan<B> for MyMakeSpan {
    fn make_span(&mut self, request: &hyper::Request<B>) -> Span {
        let internal_request_id = KsuidMs::new(None, None).to_string();
        tracing::info_span!(
            "request",
            method = %request.method(),
            uri = %request.uri(),
            int_id = internal_request_id,
        )
    }
}

#[derive(Clone)]
pub struct MyOnRequest {}

impl<B> OnRequest<B> for MyOnRequest {
    fn on_request(&mut self, request: &Request<B>, _span: &Span) {
        let request_id = request.headers()[REQUEST_ID_HEADER]
            .to_str()
            .unwrap_or("unknown");
        let user_agent = request.headers()["User-Agent"]
            .to_str()
            .unwrap_or("unknown");

        tracing::info!(
            user_agent = %user_agent,
            request_id = %request_id,
            "request"
        )
    }
}

#[derive(Clone)]
pub struct MyOnResponse {}

impl<B> OnResponse<B> for MyOnResponse {
    fn on_response(self, response: &Response<B>, latency: std::time::Duration, _span: &Span) {
        let request_id = response.headers()[REQUEST_ID_HEADER]
            .to_str()
            .unwrap_or("unknown");
        tracing::info!(
            latency = latency.as_millis(),
            request_id = %request_id,
            status = response.status().as_u16(),
            "response"
        )
    }
}
