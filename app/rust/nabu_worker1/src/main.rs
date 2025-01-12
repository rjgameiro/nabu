#[allow(unused_imports)]
use tracing::{ trace, debug, info, warn, error, instrument };

#[warn(unused_imports)]
use tracing_subscriber::EnvFilter;
use tokio::signal;
use tokio::time::{self, Duration};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::signal::unix;
use tokio::signal::unix::SignalKind;
use tracing::level_filters::LevelFilter;
use nabu_core::server::running_in_terminal;

#[tokio::main]
async fn main() {
    // Initialize the logger (you can customize this as needed)
    let env_filter = EnvFilter::builder()
        .with_default_directive(LevelFilter::INFO.into())
        .from_env_lossy();
    if running_in_terminal() {
        tracing_subscriber::fmt::fmt()
            .compact()
            .without_time() // Remove timestamp
            .with_target(false)
            .with_env_filter(env_filter)// Remove the binary name
            .init();
    } else {
        tracing_subscriber::fmt()
            .with_ansi(false)
            .with_env_filter(env_filter)
            .init();
    }

    info!("starting");

    // Create a shared atomic flag for shutdown
    let shutdown_flag = Arc::new(AtomicBool::new(false));
    let shutdown_clone = shutdown_flag.clone();

    // Spawn a task to handle signals
    tokio::spawn(async move {
        handle_signals(shutdown_clone).await;
    });

    // Main task: Log message every 60 seconds
    let mut interval = time::interval(Duration::from_secs(30));

    while !shutdown_flag.load(Ordering::Relaxed) {
        interval.tick().await;
        info!("alive and kicking");
    }

    info!("shutdown");
}

#[cfg(unix)]
async fn handle_signals(shutdown_flag: Arc<AtomicBool>) {
    #[cfg(unix)]
    let mut sigterm = match unix::signal(SignalKind::terminate()) {
        Ok(signal) => signal,
        Err(err) => {
            warn!("failed to set up SIGTERM handler (will proceed anyway): {}", err);
            warn!("if running in a container, stopping the main process with SIGTERM will not work as expected");
            return;
        }
    };
    #[cfg(unix)]
    let mut sighup = match unix::signal(SignalKind::hangup()) {
        Ok(signal) => signal,
        Err(err) => {
            warn!("failed to set up SIGHUP handler (will proceed anyway): {}", err);
            warn!("if running in a container, reloading the main process with SIGHUP will not work as expected");
            return;
        }
    };
    loop {
        tokio::select! {
            _ = signal::ctrl_c() => {
                warn!("received CTRL-C");
                break;
            }
            _ = sigterm.recv() => {
                warn!("received SIGTERM");
                break;
            }
            _ = sighup.recv() => {
                warn!("received SIGHUP - reconfigure");
            }
        }
    }

    // Set the shutdown flag
    shutdown_flag.store(true, Ordering::Relaxed);

    info!("waiting for orderly termination");
}