(local wezterm (require :wezterm))
(local config (wezterm.config_builder))

(tset config :enable_tab_bar false)

(tset config :font (wezterm.font "Source Code Pro"))
(tset config :font_size 13)

config

