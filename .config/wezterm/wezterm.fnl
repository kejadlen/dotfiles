(local wezterm (require "wezterm"))
(local config (wezterm.config_builder))

; (tset config :color_scheme "Apprentice (base16)")
(tset config :color_scheme "Ashes (base16)")

(tset config :enable_tab_bar false)

(tset config :font (wezterm.font "Source Code Pro"))
(tset config :font_size 13)

config
