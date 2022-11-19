#!/usr/bin/env ruby

# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

require "json"

muted = `osascript -e "input volume of (get volume settings)"`.to_i.zero?

unless ARGV.empty?
  vol = ARGV.shift
  `osascript -e "set volume input volume #{vol}"`
  name = File.basename(__FILE__).split(?.)[0..-3].join(?.)
  `open swiftbar://refreshplugin?name=#{name}`
end

icon = [:mic, muted ? :slash : nil, :fill].compact.join(?.)
params = {
  symbolize: true,
  bash: __FILE__,
  param0: muted ? 75 : 0,
  terminal: false,
}
puts ":#{icon}: | #{params.map {|k,v| "#{k}=#{v}"}.join(" ")}"
