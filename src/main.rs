pub mod models;
pub mod schema;
pub mod db;
pub mod generate;
pub mod hand_off;

use clap::{Arg, ArgAction, Command};
use log::{debug, info};
use dotenvy::dotenv;

fn cli() -> Command {
    Command::new("mmg")
        .about("Automatically generate TikTok compatable videos with an LLM.")
        .version("1.0")
        .author("Milo Banks (Isacc Barker) <milo banks at rowland hall dot org>")
        .arg(
            Arg::new("base-dir")
                .short('s')
                .long("base-dir")
                .help("Path to base asset directory.")
                .required(true)
        )
        .arg(
            Arg::new("no-db")
                .short('d')
                .long("no-db")
                .help("Disable recording actions in SQL database.")
                .action(ArgAction::SetTrue)
        )
        .arg(
            Arg::new("initial")
                .short('i')
                .long("initial")
                .help("Initial text to feed to prediction algorithm.")
                .required(true)
        )
}

#[tokio::main]
async fn main() {
    env_logger::init();

    let matches = cli().get_matches();
    let base_dir = matches.get_one::<String>("base-dir").unwrap().to_owned();
    let initial = matches.get_one::<String>("initial").unwrap().to_owned();

    info!("Starting generation process!");

    debug!("Reading environment variables.");
    dotenv().ok();

    if ! matches.get_flag("no-db") {
        debug!("Connecting to Postgres SQL database (disable with --no-db flag).");
        db::init_db();
    }

    info!("Generating script.");
    let script = generate::generate_entry(initial, 1.1, 10.0, 0.7, 3).await;

    info!("Handing video creation off.");
    hand_off::generate_video(&script.script, &base_dir);

    info!("Recording in database.");

    info!("Cleaning up.");
}
