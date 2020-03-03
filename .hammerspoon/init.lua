fennel = require("fennel")
table.insert(package.loaders or package.searchers, fennel.searcher)

fennel.dofile("init.fnl", { allowedGlobals = false })

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
-- spoon.Quitter:start()

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

hs.notify.new({
  title = "Hammerspoon",
  informativeText = "Config loaded",
  withdrawAfter = 2,
}):send()
