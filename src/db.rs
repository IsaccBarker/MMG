use diesel::pg::PgConnection;
use diesel::prelude::*;
use log::{debug, error};
use std::env;

pub fn init_db() {
    let database_url = match env::var("DATABASE_URL") {
        Ok(d) => d,
        Err(e) => {
            error!("Failed to fetch DATABASE_URL from environment source: {}", e);
            std::process::exit(1);
        }
    };

    debug!("Connecting to database {} as denoted in environment source.", database_url);
    debug!("Establishing connection.");

    PgConnection::establish(&database_url)
        .unwrap_or_else(|_| panic!("Error connecting to {}", database_url));
}
