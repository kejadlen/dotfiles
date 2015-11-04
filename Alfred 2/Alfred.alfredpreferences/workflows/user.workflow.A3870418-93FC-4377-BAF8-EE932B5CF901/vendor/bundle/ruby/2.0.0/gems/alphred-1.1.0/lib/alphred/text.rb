require "builder"

module Alphred
  class Text
    attr_accessor *%i[ copy largetype ]

    def initialize(copy: nil, largetype: nil)
      @copy = copy
      @largetype = largetype
    end

    def to_xml(xml)
      xml.text copy, type: :copy unless self.copy.nil?
      xml.text largetype, type: :largetype unless self.largetype.nil?
    end
  end
end
