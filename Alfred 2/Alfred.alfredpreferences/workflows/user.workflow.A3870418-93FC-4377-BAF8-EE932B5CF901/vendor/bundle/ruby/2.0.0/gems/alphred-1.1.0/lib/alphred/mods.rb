require "builder"

module Alphred
  class Mods
    MODS = %i[ shift fn ctrl alt cmd ]

    attr_accessor *MODS

    def initialize(**kwargs)
      MODS.each do |mod|
        self.instance_variable_set("@#{mod}", kwargs[mod]) if kwargs.has_key?(mod)
      end
    end

    def to_xml(xml)
      MODS.each do |mod|
        value = self.send(mod)
        xml.subtitle value, mod: mod unless value.nil?
      end
    end
  end
end
