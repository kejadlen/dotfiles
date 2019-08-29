local mash = {"cmd", "alt", "ctrl"}
local smash = {"cmd", "alt", "ctrl", "shift"}

-- Window management
wm = {
  left = hs.layout.left50,
  right = hs.layout.right50,
  ne = { 0.5, 0, 0.5, 0.5 },
  nw = { 0, 0, 0.5, 0.5 },
  se = { 0.5, 0.5, 0.5, 0.5 },
  sw = { 0, 0.5, 0.5, 0.5 },
  max = hs.layout.maximized,
}

function move(key)
  local win = hs.window.focusedWindow()
  local geo = wm[key]
  win:move(geo, nil, true)
end

hs.hotkey.bind(mash, "h", function() move("left") end)
hs.hotkey.bind(mash, "l", function() move("right") end)
hs.hotkey.bind(mash, "m", function() move("max") end)

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

hs.alert.show("Config loaded")
