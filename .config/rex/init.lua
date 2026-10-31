-- The server's cwd isn't the config dir, but Rex puts that dir first on
-- package.path.
local dir = package.path:match("^([^;]*/)%?%.lua")

-- Rex runs Lua 5.1, but fennel.lua is version-agnostic, so borrow the rock
-- frork installs for Hammerspoon.
package.path = os.getenv("HOME") .. "/.luarocks/share/lua/5.4/?.lua;" .. package.path
local fennel = require("fennel")
fennel.path = dir .. "?.fnl;" .. dir .. "?/init.fnl;" .. fennel.path
-- Keep Fennel line numbers so Rex's errors point at the right line.
table.insert(package.loaders, fennel.makeSearcher({ correlate = true }))

require("config")
