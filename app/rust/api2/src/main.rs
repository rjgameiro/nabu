#[allow(unused_imports)]
use tracing::{ trace, debug, info, warn, error, instrument };

#[warn(unused_imports)]
use tracing_subscriber::EnvFilter;
use tower_http::cors::Any;
use tower_http::cors::CorsLayer;
use axum::extract::Query;
use axum::response::IntoResponse;
use axum::http::StatusCode;
use axum::Router;
use axum::routing::get;
use axum::Json;
use tracing::level_filters::LevelFilter;
use core::server::serve;
use core::server::running_in_terminal;
use core::TextQuery;
use core::MessageResponse;

const API_PREFIX: &str = "/api/v1/api2";

async fn upper_handler(Query(query): Query<TextQuery>) -> impl IntoResponse {
    // Check if the `text` parameter was provided
    let response = match query.text.as_deref() {
        None | Some("") => Json(MessageResponse { result: None, error: Some("No text was provided.".into()) }),
        Some(text) => Json(MessageResponse { result: Some(text.to_uppercase()), error: None }),
    };
    info!("upper_handler called - query: {:?}, response: {:?}", query, response);
    // Return the response as JSON
    (StatusCode::OK, response)
}

#[tokio::main]
async fn main() {

    let env_filter = EnvFilter::builder()
        .with_default_directive(LevelFilter::INFO.into())
        .from_env_lossy();
    if running_in_terminal() {
        tracing_subscriber::fmt::fmt()
            .compact()
            .without_time()
            .with_target(false)
            .with_env_filter(env_filter)
            .init();
    } else {
        tracing_subscriber::fmt()
            .with_ansi(false)
            .with_env_filter(env_filter)
            .init();
    }

    info!("starting...");

    let cors = CorsLayer::new()
        .allow_origin(Any) // Allow requests from any origin
        .allow_methods(Any) // Allow any HTTP method
        .allow_headers(Any); // Allow any headers

    // Build the router
    let app = Router::new()
        .route(&format!("{}/{}", API_PREFIX, "upper"), get(upper_handler))
        .layer(cors);

    serve(app).await;

    info!("shutdown.");
}