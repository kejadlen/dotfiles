require 'irb/completion'
require 'irb/ext/save-history' unless RUBY_ENGINE == 'macruby'
require 'pp'

# tab completion
ARGV.concat %w[ --readline --prompt-mode simple ] unless RUBY_ENGINE == 'macruby'

IRB.conf[:AUTO_INDENT] = true
IRB.conf[:EVAL_HISTORY] = 1000
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb_history"

# shut irb up
# IRB.conf[:PROMPT][ IRB.conf[:PROMPT_MODE] ][:RETURN] = ''

# require 'wirble'
# def pc(*ary)
#   ary.each do |obj|
#     puts Wirble::Colorize.colorize(obj.inspect)
#   end
# end

def history
  Readline::HISTORY.to_a
end

irbrc_local = File.expand_path('../.irbrc.local', __FILE__)
require irbrc_local if File.exists?(irbrc_local)

begin
  # use Pry if it exists
  require 'pry'
  Pry.start || exit
rescue LoadError
end
