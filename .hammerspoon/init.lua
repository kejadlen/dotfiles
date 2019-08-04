local mash = {"cmd", "alt", "ctrl"}
local smash = {"cmd", "alt", "ctrl", "shift"}

-- Window management

-- TODO implement desktop and window gaps
hs.urlevent.bind("wm", function(eventName, params)
  local log = hs.logger.new("wm", "debug")

  local win = hs.window.focusedWindow() -- TODO figure out why focusedWindow doesn't work
  -- local win = hs.window.frontmostWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  local t = {
    left = function(f) return hs.layout.left50 end,
    right = function(f) return hs.layout.right50 end,
    ne = function(f) return { 0.5, 0, 0.5, 0.5 } end,
    nw = function(f) return { 0, 0, 0.5, 0.5 } end,
    se = function(f) return { 0.5, 0.5, 0.5, 0.5 } end,
    sw = function(f) return { 0, 0.5, 0.5, 0.5 } end,
    max = function(f) return hs.layout.maximized end,
  }

  local unitRect = hs.geometry(t[params["layout"]](f))
  local frame = unitRect:fromUnitRect(max)
  win:setFrame(frame)
  -- win:focus()
end)

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

hs.alert.show("Config loaded")
