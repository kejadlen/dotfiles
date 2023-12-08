use alphred::{Item, Workflow};
use std::{env, process::Command};

use color_eyre::eyre::Result;

fn main() -> Result<()> {
    color_eyre::install()?;

    let workflow = Workflow::new(|| {
        let input = match env::args().nth(1) {
            Some(arg) => arg,
            None => String::from_utf8(
                Command::new("sh")
                    .arg("-c")
                    .arg("echo hello")
                    .output()?
                    .stdout,
            )?,
        };
        let input = input.trim();
        let output: String = input
            .chars()
            .map(|c| {
                if c.is_ascii_alphabetic() {
                    let origin = if c.is_lowercase() {
                        b'a'
                    } else if c.is_uppercase() {
                        b'A'
                    } else {
                        unimplemented!()
                    };
                    ((((c as u8) - origin) + 13) % 26 + origin) as char
                } else {
                    c
                }
            })
            .collect();
        let item = Item::new(&output).arg(&output).subtitle(input);
        Ok(vec![item])
    });

    println!("{}", workflow);

    Ok(())
}
