module SM
  module Items
    def self.register(keyword, url)
      registry << Item.new(keyword, url)
    end

    def self.registry
      @registry ||= []
    end

    def self.to_xml(keyword, query=nil)
      <<-XML
<?xml version="1.0"?>
<items>
  #{registry.select {|item| keyword.nil? || item.keyword.start_with?(keyword) }.map {|item| item.to_xml(query) }.join}
</items>
      XML
    end
  end

  class Item
    attr_reader :keyword, :url

    def initialize(keyword, url)
      @keyword = keyword.to_s
      @url = url
    end

    def to_xml(query=nil)
      <<-XML
<item uid="#{keyword}" arg="#{url % query}" valid="YES" autocomplete="#{keyword}">
  <title>#{keyword}</title>
  <subtitle>#{url % query}</subtitle>
</item>
      XML
    end
  end
end

include SM

Items.register(:account, 'https://app.simplymeasured.com/admin/account/%s')
Items.register(:airbrake, 'https://simplymeasured.airbrake.io/')
Items.register(:go, 'http://go.intsm.net/%s')
Items.register(:historic, 'https://app.simplymeasured.com/admin/historic/%s')
Items.register(:historics, 'https://app.simplymeasured.com/admin/historics')
Items.register(:jira, 'https://simplymeasured.jira.com/secure/QuickSearch.jspa?searchString=%s')
Items.register(:stream, 'https://app.simplymeasured.com/capture/streams/%s')

keyword,*query = (ARGV.shift || '').split(/\s+/)
query = query.join

puts Items.to_xml(keyword, query)
