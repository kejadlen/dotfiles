-- Handle mismatch between homebrew's version of Lua and wezterm's version
local lVer = _VERSION:match("Lua (.+)$")
local luarocks = "/opt/homebrew/bin/luarocks"

function execute(prog)
  local fh = io.popen(prog)
  return fh:read("*a")
end

package.path = package.path .. ";" .. execute(
  luarocks .. " --lua-version " .. lVer .. " path --lr-path"
):gsub("\n", "")
package.cpath = package.cpath .. ";" .. execute(
  luarocks .. " --lua-version " .. lVer .. " path --lr-cpath"
):gsub("\n", "")

-- https://github.com/wez/wezterm/issues/5323
debug = {traceback = function() end}

fennel = require "fennel"
table.insert(package.loaders or package.searchers, fennel.searcher)

-- local wezterm = require "wezterm"
-- wezterm.log_error(package.path)

local home = os.getenv("HOME")
return fennel.dofile(home .. "/.config/wezterm/wezterm.fnl")
