require "digest/sha1"
require "open-uri"

require "nokogiri"
require "roda"

module Rzz

  class App < Roda
    plugin :caching

    route do |r|
      r.get do
        r.is "test-gym" do
          url = "https://elemental.medium.com/feed"
          xml = URI.open(url).read
          r.etag Digest::SHA1.hexdigest(xml)

          doc = Nokogiri::XML(xml)

          self_url = "#{r.base_url}#{r.path}" # Should this be configured via the environment?
          doc.at_xpath("/rss/channel/link/text()").content = self_url
          doc.at_xpath("/rss/channel/atom:link[@href='#{url}']")["href"] = self_url

          doc.at_xpath("/rss/channel/atom:link[@rel='hub']").remove

          doc
            .xpath("/rss/channel/item")
            .select {|item| item.xpath("./category[text()='test-gym']").empty? }
            .each(&:remove)

          doc
            .xpath("/rss/channel/item")
            .each do |item|
              link = item.at_xpath("./link/text()").content
              item.at_xpath("./description/text()").content = URI.open(link).read
            end

          response.headers["Content-Type"] = "text/xml"
          doc.to_xml
        end
      end
    end
  end

end

if __FILE__ == $0
  url = "https://elemental.medium.com/feed"
  xml = URI.open(url).read
  doc = Nokogiri::XML(xml)

  require "pry"
  binding.pry
end
