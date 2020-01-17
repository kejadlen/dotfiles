--- === Quitter ===
--
-- Quits configured apps if they have not been used since a specified amount of time.

local obj = {}
obj.__index = obj

-- Metadata

obj.name = "Quitter"
obj.version = "0.1"
obj.author = "Alpha Chen <alpha@kejadlen.dev>"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new("quitter", "debug")
obj.lastFocused = {}
obj.windowFocusedFn = function(window, appName)
  local bundleID = window:application():bundleID()
  if not obj.quitAppsAfter[bundleID] then return end
  obj.lastFocused[bundleID] = os.time()
end

--- Quitter.quitAppsAfter
--- Variable
--- Table of application bundle IDs to quit when unused. Use `mdls -name
--- --kMDItemCFBundleIdentifier -r /path/to/app` to find unknown bundle IDs.

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
  self.windowFilter = hs.window.filter.default:subscribe(hs.window.filter.windowFocused, self.windowFocusedFn)

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
  self.windowFilter:unsubscribe(hs.window.filter.windowFocused, self.windowFocusedFn)
  self.timer:stop()
end

function obj:reset()
  hs.fnutils.ieach(hs.application.runningApplications(), function(app)
    local bundleID = app:bundleID()

    local duration = self.quitAppsAfter[bundleID]
    if not duration then return false end

    self.lastFocused[bundleID] = os.time()
  end)
end

function obj:reap()
  self.logger.d("reaping")
  local appsToQuit = hs.fnutils.ifilter(hs.application.runningApplications(), function(app)
    -- Don't quit the currently focused app
    if app:isFrontmost() then return false end

    local duration = self.quitAppsAfter[app:bundleID()]
    if not duration then return false end

    local lastFocused = self.lastFocused[app:bundleID()]
    if not lastFocused then return false end

    self.logger.d("app: " .. app:name() .. " last focused at " .. lastFocused)

    return (os.time() - lastFocused) > duration
  end)

  for _,app in pairs(appsToQuit) do
    hs.notify.new({
      title = "Hammerspoon",
      informativeText = "Quitting " .. app:name(),
      withdrawAfter = 2,
    }):send()
    app:kill()
    self.lastFocused[app:bundleID()] = nil
  end
end

return obj
