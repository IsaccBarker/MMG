use log::{debug, error};
use reqwest::header::HeaderMap;
use serde_json::json;
use std::env;

pub struct GeneratedEntry {
    pub script: String,
}

// https://www.dotnetperls.com/word-count-rust
fn count_words(s: &str) -> usize {
    let mut total = 0;
    let mut previous = char::MAX;

    for c in s.chars() {
        if previous.is_ascii_whitespace() {
            if c.is_ascii_alphabetic() || c.is_ascii_digit() || c.is_ascii_punctuation() {
                total += 1;
            }
        }

        previous = c;
    }

    if s.len() >= 1 {
        total += 1
    }

    total
}

pub async fn generate_entry(temperature: f32,
                            repetition_penalty: f32,
                            top_p: f32,
                            top_k: i32) -> GeneratedEntry {
    // TODO: Once I get this running on higher-end hardware, let's try and run the model locally.
    let client = reqwest::Client::new();
    let mut headers = HeaderMap::new();
    let api_key = match env::var("HF_BLOOM_API_KEY") {
        Ok(d) => d,
        Err(e) => {
            error!("Failed to fetch HF_BLOOM_API_KEY from environment source: {}", e);
            std::process::exit(1);
        }
    };

    headers.insert("Authorization", format!("Bearer {api_key}").parse().unwrap());

    // let mut script = "This is the story of a man named Stanley. Stanley worked for a company in a big building where he was Employee #427. Employee #427's job was simple: he sat at his desk in Room 427 and he pushed buttons on a keyboard. Orders came to him through a monitor on his desk telling him what buttons to push, how long to push them, and in what order. This is what Employee #427 did every day of every month of every year, and although others may have considered it soul rending, Stanley relished every moment that the orders came in, as though he had been made exactly for this job. And Stanley was happy. And then one day, something very peculiar happened:".to_owned();
    let mut script = "Bob didn't come home from work. He didn't come back to his family, nor did he even leave the building he worked in. If you looked in the places he frequened (the bar, mainly) you couldn't find him. You could only find him if you looked in the morgue.".to_owned();
    let mut i = 0;
    let mut last_length = count_words(&script);
    let script_max_words = count_words(&script) + 150;
    loop {
        // https://huggingface.co/docs/api-inference/detailed_parameters#text-generation-task
        let request_body = json!({
            "inputs": &script,
            "parameters": {
                "temperature": temperature,
                "repetition_penalty": repetition_penalty,
                "top_p": top_p,
                "top_k": top_k
            },
            "options": {
                "wait_for_model": true
            }
        });

        debug!("Querying API for response (iteration {i}, length {}).", count_words(&script));
        let resp = match client.post("https://api-inference.huggingface.co/models/bigscience/bloom")
            .body(request_body.to_string())
            .headers(headers.clone())
            .send()
            .await {
                Ok(r) => r,
                Err(e) => {
                    error!("Failed to fetch response from API endpoint: {}", e);
                    std::process::exit(1);
                }
        };

        if resp.status() != 200 {
            error!("API returned HTTP code {} (!= 200).", resp.status());
            std::process::exit(1);
        }

        let text = &resp.text().await.unwrap();
        let returned_json = json::parse(text).unwrap();
        let returned_text = returned_json[0]["generated_text"].to_string().replace("\n", " ");
        script = returned_text;
        if count_words(&script) >= script_max_words {
            break;
        } else if count_words(&script) == last_length {
            error!("LLM didn't generate new characters.");
            std::process::exit(1);
        }

        last_length = count_words(&script);

        // Don't overwhelm the API.
        std::thread::sleep(std::time::Duration::from_secs(1));

        i += 1;
    }

    debug!("Script: {}", script);
    GeneratedEntry { script }
}
