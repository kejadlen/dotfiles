require "builder"

require_relative "mods"
require_relative "text"

module Alphred
  class Item
    VALID_TYPES = %i[ default file file_skipcheck ]

    attr_accessor *%i[ uid arg valid autocomplete title subtitle mods icon text ]

    def initialize(**kwargs)
      raise ArgumentError.new("missing keyword: title") unless kwargs.has_key?(:title)

      @title = kwargs[:title]

      %i[ uid arg valid autocomplete subtitle ].each do |attr|
        self.instance_variable_set("@#{attr}", kwargs[attr]) if kwargs.has_key?(attr)
      end

      @icon = Icon(kwargs[:icon]) if kwargs.has_key?(:icon)
      @text = Text.new(kwargs[:text]) if kwargs.has_key?(:text)
      @mods = Mods.new(kwargs[:mods]) if kwargs.has_key?(:mods)

      self.type = kwargs[:type] if kwargs.has_key?(:type)
    end

    def type=(type)
      raise ArgumentError.new("`type` must be one of #{VALID_TYPES}") unless type.nil? || VALID_TYPES.include?(type)

      @type = type
    end

    def type
      @type && @type.to_s.gsub(?_, ?:)
    end

    def to_xml(xml=nil)
      xml ||= Builder::XmlMarkup.new(indent: 2)
      xml.item self.attrs do
        xml.title self.title
        xml.subtitle self.subtitle unless self.subtitle.nil?
        self.icon.to_xml(xml) unless self.icon.nil?
        self.mods.to_xml(xml) unless self.mods.nil?
        self.text.to_xml(xml) unless self.text.nil?
      end
    end

    def attrs
      attrs = {}
      %i[ uid arg autocomplete type ].each do |attr|
        value = self.send(attr)
        attrs[attr] = value unless value.nil?
      end
      attrs[:valid] = (self.valid) ? "yes" : "no" unless self.valid.nil?
      attrs
    end
  end
end
