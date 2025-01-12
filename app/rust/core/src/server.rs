#[allow(unused_imports)]
use tracing::{ trace, debug, info, warn, error, instrument };
#[warn(unused_imports)]

use std::env;
use std::net::SocketAddr;
use std::process::exit;
use std::sync::Arc;
use axum::Router;
use futures::future::join_all;
use tokio::signal::unix::{SignalKind};
use tokio::sync::Notify;
use tokio::signal;
use signal::unix;
use nix::unistd::{isatty};
use nix::sys::termios;
use std::os::unix::io::BorrowedFd;

enum ExitReason {
    InvalidPort = 11,
    InvalidIPAddress,
    BindFailed,
}

impl From<ExitReason> for i32 {
    fn from(reason: ExitReason) -> i32 {
        reason as i32
    }
}

const ENV_BIND_ADDRESSES: &str = "BIND_ADDRESSES";
const ENV_BIND_PORT: &str = "BIND_PORT";

const DEFAULT_PORT: u16 = 8000;
const DEFAULT_BIND_ADDRESS_IPV4: &str = "127.0.0.1";
const DEFAULT_BIND_ADDRESS_IPV6: &str = "[::1]";

/// Resolve the socket addresses to bind to from the environment variables
/// (BIND_ADDRESS, BIND_ADDRESSES, BIND_PORT).
fn resolve_socket_addresses() -> Vec<String> {
    // Read and validate the port
    let port = env::var(ENV_BIND_PORT).unwrap_or_else(|_| DEFAULT_PORT.to_string());
    let port: u16 = match port.parse() {
        Ok(port) if port > 0 => port,
        _ => {
            error!("bind port ({}) must be a valid number between 1 and 65535.", port);
            exit(ExitReason::InvalidPort as i32);
        }
    };

    // Fetch environment variables
    let bind_addresses = env::var(ENV_BIND_ADDRESSES).ok();
    // Determine the addresses to use
    if let Some(addresses) = bind_addresses {
        addresses
            .split(',')
            .map(|addr| validate_and_format(addr.trim().to_string(), port))
            .collect() // Use BIND_ADDRESSES if set
    } else {
        vec![
            format!("{}:{}", DEFAULT_BIND_ADDRESS_IPV4, port), // Default to IPv4 loopback
            format!("{}:{}", DEFAULT_BIND_ADDRESS_IPV6, port),    // Default to IPv6 loopback
        ]
    }

}

/// Validate and format the ip address and port pair.
fn validate_and_format(addr: String, port: u16) -> String {
    let socket = format!("{}:{}", addr, port);
    let parsed_socket: SocketAddr = socket.parse().unwrap_or_else(|_| {
        error!("\"{}\" is not a valid IPv4 or IPv6 address.", addr);
        exit(ExitReason::InvalidIPAddress as i32);
    });
    parsed_socket.to_string()
}


pub fn running_in_terminal() -> bool {
    if isatty(libc::STDOUT_FILENO).unwrap_or(false) {
        // Wrap the raw file descriptor in a `BorrowedFd`.
        let fd = unsafe { BorrowedFd::borrow_raw(libc::STDOUT_FILENO) };
        // Use the wrapped file descriptor with `tcgetattr`.
        match termios::tcgetattr(fd) {
            // If `tcgetattr` succeeds, we are running in a terminal.
            Ok(_) => true,
            // If `tcgetattr` fails, we are not running in a terminal.
            Err(_) => false,
        }
    } else {
        // If `isatty` fails, we are not running in a terminal.
        false
    }
}

pub async fn serve(app: Router) {

    let socket_addresses = resolve_socket_addresses();

    let mut listeners = Vec::new();
    for addr in socket_addresses {
        match tokio::net::TcpListener::bind(&addr).await {
            Ok(listener) => {
                debug!("listening on {}", addr);
                listeners.push(listener);
            }
            Err(e) => warn!("failed to bind to {}: {}", addr, e),
        }
    }

    if listeners.is_empty() {
        error!("unable to bind to at least one ip:port pair, refusing to continue");
        exit(ExitReason::BindFailed as i32);
    }

    let shutdown_notify = Arc::new(Notify::new());
    // Spawn a task to listen for SIGTERM or SIGINT
    let shutdown_notify_clone = Arc::clone(&shutdown_notify);
    tokio::spawn(async move {
        listen_for_shutdown().await;
        shutdown_notify_clone.notify_waiters();
    });

    // Spawn a task for each listener
    let server_tasks: Vec<_> = listeners
        .into_iter()
        .map(|listener| {
            let local_addr = listener.local_addr().unwrap();
            let app = app.clone(); // Clone the app for each server
            let shutdown_notify = Arc::clone(&shutdown_notify); // Clone the shutdown notifier for each server

            tokio::spawn(async move {
                info!("serving on {}", local_addr);

                axum::serve(listener, app)
                    .with_graceful_shutdown(async move {
                        shutdown_notify.notified().await;
                    })
                    .await
                    .unwrap();

                info!("server on {} stopped", local_addr);
            })
        })
        .collect();

    join_all(server_tasks).await;
}

#[cfg(unix)]
#[instrument(name = "listen_for_shutdown")]
/// Listens for a shutdown signal (`SIGTERM` or `SIGINT`)
async fn listen_for_shutdown() {
    #[cfg(unix)]
    let mut sigterm = match unix::signal(SignalKind::terminate()) {
        Ok(signal) => signal,
        Err(err) => {
            warn!("failed to set up SIGTERM handler (will proceed anyway): {}", err);
            warn!("if running in a container, stopping the main process with SIGTERM will not work as expected");
            return;
        }
    };
    tokio::select! {
        // Handle Ctrl+C
        _ = signal::ctrl_c() => {
            warn!("received SIGINT (Ctrl+C), shutting down");
        }
        // Handle SIGTERM (Unix only)
        _ = sigterm.recv() => {
            warn!("received SIGTERM, shutting down");
        }
    }
}
