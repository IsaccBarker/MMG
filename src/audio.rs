use log::error;
use rand::seq::IteratorRandom;
use std::process::Command;

pub fn generate_video(script: &str, dir: &str) -> String {
    let output = match Command::new(format!("{}/scripts/generate_video.sh", dir))
        .arg(script)
        .output() {
            Ok(o) => o,
            Err(e) => {
                error!("Failed to hand off and generate video: {}", e);
                std::process::exit(1);
            }
        };

    return std::str::from_utf8(&output.stdout).unwrap().to_owned().trim().to_owned();
}

