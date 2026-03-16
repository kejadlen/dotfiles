-- Hammerspoon embeds Lua 5.4 but brew's lua tracks the latest version.
-- Use luarocks to find packages installed for the right Lua version.
local lVer = _VERSION:match("Lua (.+)$")
local luarocks = "/opt/homebrew/bin/luarocks"
package.path = package.path .. ";" .. hs.execute(
  luarocks .. " --lua-version " .. lVer .. " path --lr-path"
):gsub("\n", "")
package.cpath = package.cpath .. ";" .. hs.execute(
  luarocks .. " --lua-version " .. lVer .. " path --lr-cpath"
):gsub("\n", "")

fennel = require "fennel"
table.insert(package.loaders or package.searchers, fennel.searcher)

fennel.dofile("init.fnl", { allowedGlobals = false })
