#!/usr/bin/env ruby

# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>

require "json"

switch_audio_source = "/opt/homebrew/bin/SwitchAudioSource"

unless ARGV.empty?
  type, id = ARGV
  `#{switch_audio_source} -t #{type} -i #{id}`
end

audio_sources = `#{switch_audio_source} -a -f json`
  .lines(chomp: true)
  .map {|x| JSON.parse(x) }
  .group_by {|x| x.fetch("type") }

input = JSON.parse(`#{switch_audio_source} -c -f json -t input`)
output = JSON.parse(`#{switch_audio_source} -c -f json -t output`)

puts ":waveform: | symbolize=true"
puts "---"

audio_sources.each do |type,sources|
  sources.each do |source|
    name = source.fetch("name")
    id = source.fetch("id")

    sf_type = case type
              when "input" then ":mic.fill:"
              when "output" then ":speaker.wave.2.fill:"
              else fail "Unexpected type: #{type}"
              end

    params = {
      symbolize: true,
      checked: [input, output].include?(source),
      bash: __FILE__,
      terminal: false,
      param0: type,
      param1: id,
    }

    puts "#{sf_type} #{name} | #{params.map {|k,v| "#{k}=#{v}"}.join(" ")}"
  end
end
