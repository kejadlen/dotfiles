extern crate alphred;
extern crate serde;
#[macro_use]
extern crate serde_json;

use alphred::Item;

fn main() {
    let items: Vec<_> = vec![
        // Enter fullscreen mode for focused container
        "tiling::window --toggle fullscreen",
        // Change focus between tiling/floating windows
        "tiling::window --toggle float",
        // Change layout of desktop
        "tiling::desktop --layout bsp",
        "tiling::desktop --layout monocle",
        // Change focus
        "tiling::window --focus west",
        "tiling::window --focus south",
        "tiling::window --focus north",
        "tiling::window --focus east",
        "tiling::window --focus prev",
        "tiling::window --focus next",
        // Swap focused window
        "tiling::window --swap west",
        "tiling::window --swap south",
        "tiling::window --swap north",
        "tiling::window --swap east",
        // Move focused window
        "tiling::window --warp west",
        "tiling::window --warp south",
        "tiling::window --warp north",
        "tiling::window --warp east",
        "tiling::desktop --rotate 90",
        // Equalize window size
        "tiling::desktop --equalize",
        // float next window to be tiled
        "set window_float_next 1",
    ].iter()
        .map(|&x| {
            let m: String = x.split(|x: char| !x.is_alphanumeric())
                .collect::<Vec<_>>()
                .join(" ");
            Item::new(format!("chunkc {}", x)).arg(x).match_(&m)
        })
        .collect();

    let json = json!({ "items": items });
    println!("{}", json);
}
