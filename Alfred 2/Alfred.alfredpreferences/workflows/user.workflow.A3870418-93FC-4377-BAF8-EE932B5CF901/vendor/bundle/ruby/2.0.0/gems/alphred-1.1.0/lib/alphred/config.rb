require "json"

module Alphred
  class Config
    PATH = File.join(ENV["alfred_workflow_data"], 'config.json')

    def self.load(**defaults)
      config = self.new(**defaults)
      config.load!
      config
    end

    attr_reader :data

    def initialize(**defaults)
      @data = Hash[defaults.map {|k,v| [k.to_s, v.to_s] }]
    end

    def load!
      self.data.merge!(JSON.load(File.open(PATH)))
    end

    def update!(json)
      data = self.data.merge(JSON.load(json))
      File.write(PATH, JSON.dump(data), mode: ?w)
    end

    def [](key)
      self.data[key.to_s]
    end

    def filter_xml(filter=nil)
      filter ||= ""

      items = self.data.map do |key, value|
        title = if filter.empty?
                  "Unset #{key}"
                else
                  "Set #{key} to #{filter}"
                end
        Item.new(
          uid: key,
          arg: JSON.dump(key => filter),
          title: title,
          subtitle: self[key]
        )
      end

      Items.new(*items).to_xml
    end
  end
end
