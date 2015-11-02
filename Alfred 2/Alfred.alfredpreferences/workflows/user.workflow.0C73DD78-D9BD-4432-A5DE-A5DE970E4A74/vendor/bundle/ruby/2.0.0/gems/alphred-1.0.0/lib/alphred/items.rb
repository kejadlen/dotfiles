require "builder"

module Alphred
  class Items < DelegateClass(Array)
    attr_reader :items

    def initialize(*items)
      @items = items
      super(@items)
    end

    def to_xml
      xml = Builder::XmlMarkup.new(indent: 2)
      xml.instruct! :xml
      xml.items do
        self.items.each do |item|
          item.to_xml(xml)
        end
      end
    end
  end
end
