local mash = {"cmd", "alt", "ctrl"}
local smash = {"cmd", "alt", "ctrl", "shift"}

-- Window management

function chunkc (args)
  hs.task.new("/usr/local/bin/chunkc", nil, args)
    :start()
end

hs.hotkey.bind(mash, "left", function()
  chunkc({"tiling::window", "--warp", "west"})
end)
hs.hotkey.bind(mash, "right", function()
  chunkc({"tiling::window", "--warp", "east"})
end)
hs.hotkey.bind(mash, "up", function()
  chunkc({"tiling::window", "--warp", "north"})
end)
hs.hotkey.bind(mash, "down", function()
  chunkc({"tiling::window", "--warp", "south"})
end)
hs.hotkey.bind(mash, "z", function()
  chunkc({"tiling::window", "--toggle", "fullscreen"})
end)

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

hs.alert.show("Config loaded")
