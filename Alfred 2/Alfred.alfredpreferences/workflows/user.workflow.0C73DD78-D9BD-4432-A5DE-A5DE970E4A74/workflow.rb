require "delegate"

$LOAD_PATH.unshift(File.expand_path("../vendor/bundle", __FILE__))
require "bundler/setup"

require "alphred"
require "faker"

module Workflow
  class Faker
    FAKER_KLASSES = ::Faker.constants
                           .reject {|c| c == :Config }
                           .map {|c| ::Faker.const_get(c) }
                           .select {|c| Class === c}

    attr_reader *%i[klass method]

    def initialize(klass, method="")
      @klass, @method = klass, method
    end

    def items
      items = Alphred::Items.new
      self.matching_klasses.each do |klass|
        self.matching_methods(klass).each do |method|
          result = method.call rescue next # Ignore missing translations

          klass_short = klass.to_s.split("::").last.downcase
          query = [klass_short, method.name].join(" ")
          autocomplete = klass_short

          items << Item.new(query, result, autocomplete)
        end
      end

      items
    end

    def matching_klasses
      FAKER_KLASSES.select {|c| c.to_s.downcase.include?(self.klass.downcase) }
    end

    def matching_methods(klass)
      klass.singleton_methods(false)
        .map {|m| klass.method(m) }
        .select do |method|
          method.to_s.downcase.include?(self.method.downcase) && [-1, 0].include?(method.arity)
        end
    end
  end

  class Item < Alphred::Item
    def initialize(query, result, autocomplete)
      super(uid: query, arg: result, autocomplete: autocomplete,
            title: query, subtitle: result, icon: "icon.png")
    end
  end
end

if __FILE__ == $0
  query = ARGV.shift
  workflow = Workflow::Faker.new(*query.split(" "))
  puts workflow.items.to_xml
end
