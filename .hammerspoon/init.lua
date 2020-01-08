local mash = {"cmd", "alt", "ctrl"}
local smash = {"cmd", "alt", "ctrl", "shift"}

-- Window management --

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

-- Defeat paste blocking --

hs.hotkey.bind({"cmd", "alt"}, "v", function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)

-- Debugging --

-- hs.hotkey.bind(mash, "d", function()
-- end)

-- Spoons --

hs.loadSpoon("Quitter")
spoon.Quitter.quitAppsAfter = {
  -- mdls -name kMDItemCFBundleIdentifier -r /path/to/app
  ["com.apple.iChat"]           = 600,
  ["com.freron.MailMate"]       = 600,
  ["com.kapeli.dashdoc"]        = 600,
  ["com.reederapp.macOS"]       = 600,
  ["com.tinyspeck.slackmacgap"] = 600,
}
spoon.Quitter:start()

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

hs.notify.new({
  title = "Hammerspoon",
  informativeText = "Config loaded",
  withdrawAfter = 2,
}):send()
