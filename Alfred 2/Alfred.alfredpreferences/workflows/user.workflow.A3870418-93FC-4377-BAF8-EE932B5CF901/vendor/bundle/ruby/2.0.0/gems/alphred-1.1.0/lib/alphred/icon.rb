require "builder"

module Alphred
  class Icon
    VALID_TYPES = %i[ fileicon filetype ]

    attr_accessor *%i[ value type ]

    def initialize(**kwargs)
      raise ArgumentError.new("missing keyword: value") unless kwargs.has_key?(:value)

      @value = kwargs[:value]
      self.type = kwargs[:type] if kwargs.has_key?(:type)
    end

    def type=(type)
      raise ArgumentError.new("`type` must be one of #{VALID_TYPES}") unless type.nil? || VALID_TYPES.include?(type)

      @type = type
    end

    def to_xml(xml=nil)
      xml ||= Builder::XmlMarkup.new(indent: 2)
      attrs = {}
      attrs[:type] = self.type unless self.type.nil?
      xml.icon self.value, attrs
    end
  end
end

module Kernel
  def Icon(value)
    case value
    when Alphred::Icon then value
    when String        then Alphred::Icon.new(value: value)
    when Hash          then Alphred::Icon.new(**value)
    end
  end
end
