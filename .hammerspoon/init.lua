local lVer = _VERSION:match("Lua (.+)$")
-- local luarocks = hs.execute("which luarocks"):gsub("\n", "")
local luarocks = "/usr/local/bin/luarocks"
if #luarocks > 0 then
  package.path = package.path .. ";" .. hs.execute(
    luarocks .. " --lua-version " .. lVer .. " path --lr-path"
  ):gsub("\n", "")
  package.cpath = package.cpath .. ";" .. hs.execute(
    luarocks .. " --lua-version " .. lVer .. " path --lr-cpath"
  ):gsub("\n", "")
end

fennel = require "fennel"
table.insert(package.loaders or package.searchers, fennel.searcher)

fennel.dofile("init.fnl", { allowedGlobals = false })

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
