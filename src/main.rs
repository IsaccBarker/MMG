pub mod models;
pub mod schema;
pub mod db;
pub mod generate;
pub mod audio;

use clap::{Arg, ArgAction, Command};
use log::{debug, info};
use dotenvy::dotenv;

fn cli() -> Command {
    Command::new("mmg")
        .about("Automatically generate TikTok compatable videos with an LLM.")
        .version("1.0")
        .author("Milo Banks (Isacc Barker) <milo banks at rowland hall dot org>")
        .arg(
            Arg::new("script-dir")
                .short('s')
                .long("script-dir")
                .help("Path to scripts directory.")
                .required(true)
        )
        .arg(
            Arg::new("no-db")
                .short('d')
                .long("no-db")
                .help("Disable recording actions in SQL database.")
                .action(ArgAction::SetTrue)
        )
}

#[tokio::main]
async fn main() {
    env_logger::init();

    let matches = cli().get_matches();

    info!("Starting generation process!");

    debug!("Reading environment variables.");
    dotenv().ok();

    if ! matches.get_flag("no-db") {
        debug!("Connecting to Postgres SQL database (disable with --no-db flag).");
        db::init_db();
    }

    info!("Generating script.");
    // let script = generate::generate_entry(1.1, 10.0, 0.7, 3).await;
    let script_str = "Bob didn't come home from work. He didn't come back to his family, nor did he even leave the building he worked in. If you looked in the places he frequened (the bar, mainly) you couldn't find him. You could only find him if you looked in the morgue. He had been killed by the same person who killed his wife and son. The killer had a gun and a knife. He was wearing a mask and gloves, but he had a tattoo on his left arm. The tattoo was of a skull and crossbones. The killer had been caught, but the police didn't know who he was. They had no idea what he looked like, and they didn't have any evidence to prove it. They only had the tattoo on his arm. They had to find the killer before he killed again. They had to find him before he killed another family. The killer had been caught, but the police couldn't find him. The killer had been caught, but the police didn't know who he was. The killer had been caught, but the police didn't know what he looked like. The killer had been caught, but the police didn't have any evidence to".to_owned();

    info!("Generating script audio.");
    let audio_path = audio::generate_audio(script_str, matches.get_one::<String>("script-dir").unwrap().to_owned());

    info!("Generating script background video.");
    info!("Generating final video.");
    info!("Recording in database.");

    info!("Cleaning up.");
    // Shouldn't fail unless something *very* weird happens.
    std::fs::remove_file(audio_path).unwrap();
}
