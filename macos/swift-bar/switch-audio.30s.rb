#!/usr/bin/env ruby

# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>

require "json"

SWITCH_AUDIO_SOURCE = "/opt/homebrew/bin/SwitchAudioSource"
SOURCES = {
  headset: { icon: "headphones", input: "Antlion USB Microphone", output: "CalDigit Thunderbolt 3 Audio" },
  laptop: { icon: "play.laptopcomputer", input: "MacBook Pro Microphone", output: "MacBook Pro Speakers" },
}

unless ARGV.empty?
  audio_sources = `#{SWITCH_AUDIO_SOURCE} -a -f json`
    .lines(chomp: true)
    .map {|x| JSON.parse(x) }

  SOURCES.fetch(ARGV.shift.to_sym).each do |type, name|
    src = audio_sources.find {|src| src.values_at("type", "name") == [type.to_s, name] }
    id = src.fetch("id")
    `#{SWITCH_AUDIO_SOURCE} -t #{type} -i #{id}`
  end
end

input = JSON.parse(`#{SWITCH_AUDIO_SOURCE} -c -f json -t input`)
output = JSON.parse(`#{SWITCH_AUDIO_SOURCE} -c -f json -t output`)
active_source = SOURCES.find {|_,src|
  src.values_at(:input, :output) == [input, output].map {|src| src.fetch("name") }
}

icon = active_source ? active_source.fetch(1).fetch(:icon) : "questionmark.bubble"
puts ":waveform:: :#{icon}: | symbolize=true"
puts "---"

SOURCES.each do |name, sources|
  params = {
    symbolize: true,
    checked: name == active_source.fetch(0),
    bash: __FILE__,
    terminal: false,
    param0: name,
  }

  icon = sources.fetch(:icon)
  puts ":#{icon}: | #{params.map {|k,v| "#{k}=#{v}"}.join(" ")}"
end
