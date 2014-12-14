hs.hotkey.bind({"cmd", "shift"}, "{", function()
    current_app():selectMenuItem({"Window", "Select Previous Tab"})
end)

hs.hotkey.bind({"cmd", "shift"}, "}", function()
    current_app():selectMenuItem({"Window", "Select Previous Tab"})
end)

function current_app()
  return hs.window.application()
end

function reload_config(files)
    hs.reload()
end

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reload_config):start()
hs.alert.show("Config loaded")
