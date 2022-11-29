use log::error;
use std::process::{Command, Stdio};
use std::io::{BufRead, BufReader};

pub fn generate_video(script: &str, dir: &str) {
    let output = Command::new(format!("{}/scripts/generate_video.sh", dir))
        .arg(script)
        .stdout(Stdio::piped())
        .spawn()
        .unwrap()
        .stdout
        .ok_or_else(|| {
            error!("Could not capture standard output.");
            std::process::exit(1);
        }).unwrap();

    let reader = BufReader::new(output);

    reader
        .lines()
        .filter_map(|line| line.ok())
        .for_each(|line| println!("hello {}", line));
}

