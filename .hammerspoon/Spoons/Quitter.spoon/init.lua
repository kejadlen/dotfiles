--- === Quitter ===
--
-- Quits apps if they have not been used since a specified amount of time.

local obj = {}
obj.__index = obj

-- Metadata

obj.name = "Quitter"
obj.version = "0.1"
obj.author = "Alpha Chen <alpha@kejadlen.dev>"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new("quitter", "debug")
obj.lastFocused = {}

--- Quitter.quitAppsAfter
--- Variable
--- Table of applications to quit when unused.
obj.quitAppsAfter = {}

--- Quitter:start()
--- Method
--- Start Quitter
---
--- Parameters:
---  * None
function obj:start()
  self:reset()

  -- Reset if we're waking from sleep
  self.watcher = hs.caffeinate.watcher.new(function(event)
    if event ~= hs.caffeinate.watcher.systemDidWake then return end
    self:reset()
  end)

  -- Set last focused time for relevant apps
  self.windowFilter = hs.window.filter.new(false)
  for app, _ in pairs(self.quitAppsAfter) do
    self.windowFilter:allowApp(app)
  end
  self.windowFilter:subscribe(hs.window.filter.windowUnfocused, function(window, appName)
    local name = window:application():name()
    self.lastFocused[name] = os.time()
  end)

  self.timer = hs.timer.doEvery(60, function()
    self:reap()
  end):start()

  return self
end

--- Quitter:stop()
--- Method
--- Stop Quitter
---
--- Parameters:
---  * None
function obj:stop()
  self.watcher:stop()
  self.windowFilter:unsubscribe(hs.window.filter.windowFocused)
  self.timer:stop()
end

function obj:reset()
  hs.fnutils.ieach(hs.application.runningApplications(), function(app)
    local name = app:name()

    local duration = self.quitAppsAfter[name]
    if duration == nil then return false end

    self.lastFocused[name] = os.time()
  end)
end

function obj:shouldQuit(app)
  if app == nil then return false end

  -- Don't quit the currently focused app
  if app:isFrontmost() then return false end

  local duration = self.quitAppsAfter[app:name()]
  if duration == nil then return false end

  local lastFocused = self.lastFocused[app:name()]
  if lastFocused == nil then return false end

  self.logger.d("app: " .. app:name() .. " last focused at " .. lastFocused)

  return (os.time() - lastFocused) > duration
end

function obj:reap()
  self.logger.d("reaping")

  local frontmostApp = hs.application.frontmostApplication()
  for appName, _ in pairs(self.quitAppsAfter) do
    local app = hs.application.get(appName)

    if self:shouldQuit(app) then
      hs.notify.new({
        title = "Hammerspoon",
        informativeText = "Quitting " .. app:name(),
        withdrawAfter = 2,
      }):send()
      app:kill()
      self.lastFocused[app:name()] = nil
    end
  end
end

return obj
