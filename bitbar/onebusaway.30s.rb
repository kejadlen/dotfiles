#!/usr/bin/env ruby

require 'open-uri'
require 'rexml/document'

COLOR_MAP = {
  arrivalStatusOnTime: :green,
  arrivalStatusNoInfo: :black,
  arrivalStatusEarly: :red,
  arrivalStatusDelayed: :blue,
  arrivalStatusDepartedOnTime: :green,
  arrivalStatusDepartedNoInfo: :black,
  arrivalStatusDepartedEarly: :red,
  arrivalStatusDepartedDelayed: :blue,
  arrivalStatusCancelled: :red,
}

html = open('http://pugetsound.onebusaway.org/where/standard/stop.action?id=1_7360').read
doc = REXML::Document.new(html)
status = doc.elements['//td[contains(@class, "arrivalsStatusEntry")]']

minutes = status.elements['//span'].text
color = COLOR_MAP[status.attributes['class'].split(/\s+/).last.to_sym]
times = doc.elements.to_a('//div[@class="arrivalsTimePanel"]')

puts "#{minutes} | color=#{color}"
puts '---'
times.each do |time|
  puts "#{time[0].text}#{time[1]}#{time[2].text}"
end
