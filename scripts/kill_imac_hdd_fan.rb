#!/usr/bin/env ruby

fan_speed = (ARGV.shift || 1100).to_i

smc = '~/Applications/smcFanControl.app/Contents/Resources/smc'
fan_speed = (fan_speed << 2).to_s(16)
`#{smc} -k F1Mx -w #{fan_speed}`