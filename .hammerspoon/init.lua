local mash = {"cmd", "alt", "ctrl"}
local smash = {"cmd", "alt", "ctrl", "shift"}

function current_app()
  return hs.application.frontmostApplication()
end

-- Application shortcuts

local wf = hs.window.filter
safari_esc = hs.hotkey.new({}, "escape", function() end, function()
  if current_app():name() == "Safari" then
    safari_opt_esc:disable()
    hs.eventtap.keyStroke({"alt"}, "escape")
    safari_opt_esc:enable()
  end
end)
safari_opt_esc = hs.hotkey.new({"alt"}, "escape", function() end, function()
  if current_app():name() == "Safari" then
    safari_esc:disable()
    hs.eventtap.keyStroke({}, "escape")
    safari_esc:enable()
  end
end)

wf.new("Safari"):subscribe(wf.windowFocused, function()
  safari_esc:enable()
  safari_opt_esc:enable()
end):subscribe(wf.windowUnfocused, function()
  safari_esc:disable()
  safari_opt_esc:disable()
end)

-- hs.hotkey.bind({"cmd", "shift"}, "[", function()
--   current_app():selectMenuItem({"Window", "Select Previous Tab"})
-- end)

-- hs.hotkey.bind({"cmd", "shift"}, "]", function()
--   current_app():selectMenuItem({"Window", "Select Next Tab"})
-- end)

-- Window management

local throw_left = function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
  win:setFrame(f)
end

local throw_right = function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 2)
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
  win:setFrame(f)
end

hs.hotkey.bind(mash, "h", throw_left)
hs.hotkey.bind(mash, "left", throw_left)
hs.hotkey.bind(mash, "l", throw_right)
hs.hotkey.bind(mash, "right", throw_right)

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function()
  hs.reload()
end):start()

hs.alert.show("Config loaded")
