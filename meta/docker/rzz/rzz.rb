require "digest/sha1"
require "open-uri"

require "nokogiri"
require "roda"

module Rzz

  class App < Roda
    plugin :caching
    plugin :json

    route do |r|
      r.get do
        r.is "test-gym" do
          url = "https://elemental.medium.com/test-gym/home"
          html = URI.open(url).read

          doc = Nokogiri::HTML(html)
          items = doc.xpath("//a[@data-post-id]").map {|a|
            attrs = a.attributes
            id = attrs.fetch("data-post-id").value
            title = a.xpath("./h3").text
            content = a.xpath("./div").text
            href = URI(attrs.fetch("href"))
            url = "#{href.scheme}://#{href.host}#{href.path}"
            { id: id, title: title, content_text: content, url: url }
          }

          {
            version: "https://jsonfeed.org/version/1",
            title: "Test Gym",
            home_page_url: url,
            feed_url: "#{r.base_url}#{r.path}",
            items: items,
          }
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
