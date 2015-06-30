local mash = {"cmd", "alt", "ctrl"}

-- Application shortcuts

hs.hotkey.bind({"cmd", "shift"}, "{", function()
  current_app():selectMenuItem({"Window", "Select Previous Tab"})
end)

hs.hotkey.bind({"cmd", "shift"}, "}", function()
  current_app():selectMenuItem({"Window", "Select Previous Tab"})
end)

-- Window management

hs.hotkey.bind(mash, "h", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
  win:setFrame(f)
end)

hs.hotkey.bind(mash, "l", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 2)
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
  win:setFrame(f)
end)

function current_app()
  return hs.window.application()
end

function reload_config(files)
    hs.reload()
end

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reload_config):start()
hs.alert.show("Config loaded")
