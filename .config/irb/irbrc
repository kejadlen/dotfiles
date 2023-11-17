require 'pp'

if defined?(Reline::Face) # https://github.com/ruby/irb/issues/328
  # Tweak IRB's default colors
  Reline::Face.config(:completion_dialog) do |conf|
    conf.define :default, foreground: :black, background: :cyan
    conf.define :enhanced, foreground: :black, background: :magenta
    conf.define :scrollbar, foreground: :white, background: :blue
  end
end

def pbcopy(str=nil)
  str = yield if block_given?
  IO.popen(%w[pbcopy], 'w') {|io| io.write str }
end

# IRB.conf[:AUTO_INDENT] = true
# IRB.conf[:EVAL_HISTORY] = 1000
# IRB.conf[:SAVE_HISTORY] = 1000
# IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb_history"

# shut irb up
# IRB.conf[:PROMPT][ IRB.conf[:PROMPT_MODE] ][:RETURN] = ''

# require 'wirble'
# def pc(*ary)
#   ary.each do |obj|
#     puts Wirble::Colorize.colorize(obj.inspect)
#   end
# end

# def history
#   Readline::HISTORY.to_a
# end

irbrc_local = File.expand_path('../.irbrc.local', __FILE__)
require irbrc_local if File.exist?(irbrc_local)
