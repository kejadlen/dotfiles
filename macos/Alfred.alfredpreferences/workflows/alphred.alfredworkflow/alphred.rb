$LOAD_PATH.unshift(File.expand_path('../vendor/bundle', __FILE__))
require 'bundler/setup'

require 'alphred'

if __FILE__ == $0
  query = ARGV.shift

  Alphred::Error.try do
    raise 'OMG' if query == 'error'

    items = Alphred::Items[
      Alphred::Item.new(
        title: 'ohai',
        subtitle: $LOAD_PATH.inspect,
      ),
    ]
    puts items.to_json
  end
end
