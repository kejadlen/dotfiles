local mash = {"cmd", "alt", "ctrl"}
local mash = {"cmd", "alt", "ctrl", "shift"}

-- Application shortcuts

local wf = hs.window.filter
local safari_esc = hs.hotkey.new({}, "escape", function() end, function()
  if current_app():name() == "Safari" then
    hs.eventtap.keyStroke({"alt"}, "escape")
  end
end)

wf.new("Safari"):subscribe(wf.windowFocused, function()
  safari_esc:enable()
end):subscribe(wf.windowUnfocused, function()
  safari_esc:disable()
end)


-- hs.hotkey.bind({"cmd", "shift"}, "[", function()
--   current_app():selectMenuItem({"Window", "Select Previous Tab"})
-- end)

-- hs.hotkey.bind({"cmd", "shift"}, "]", function()
--   current_app():selectMenuItem({"Window", "Select Next Tab"})
-- end)

-- Window management

-- hs.hotkey.bind(mash, "h", function()
--   local win = hs.window.focusedWindow()
--   local f = win:frame()
--   local screen = win:screen()
--   local max = screen:frame()

--   f.x = max.x
--   f.y = max.y
--   f.w = max.w / 2
--   f.h = max.h
--   win:setFrame(f)
-- end)

-- hs.hotkey.bind(mash, "l", function()
--   local win = hs.window.focusedWindow()
--   local f = win:frame()
--   local screen = win:screen()
--   local max = screen:frame()

--   f.x = max.x + (max.w / 2)
--   f.y = max.y
--   f.w = max.w / 2
--   f.h = max.h
--   win:setFrame(f)
-- end)

function current_app()
  return hs.application.frontmostApplication()
end

function reload_config(files)
    hs.reload()
end

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reload_config):start()
hs.alert.show("Config loaded")
