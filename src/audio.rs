use std::process::Command;

pub fn generate_audio(script: String, dir: String) -> String {
    let output = Command::new(format!("{}/flite.sh", dir))
        .arg(script)
        .output()
        .expect("Failed to execute command");

    return std::str::from_utf8(&output.stdout).unwrap().to_owned().trim().to_owned();
}
