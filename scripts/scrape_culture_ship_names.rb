require "open-uri"
require "rexml/document"

html = open('https://en.wikipedia.org/wiki/List_of_spacecraft_in_the_Culture_series').read
doc = REXML::Document.new(html)
tds = doc.elements.to_a('//table[tr/th/text()="Name"]/tr//td[3]')
names = tds.map {|td| REXML::XPath.match(td, './/text()')[0] }

puts names
