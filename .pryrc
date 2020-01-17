Pry.config.editor = 'vim'

Pry.prompt = [
  proc { |target, _, _| "(#{Pry.view_clip(target)})> " },
  proc { |target, _, _| "(#{Pry.view_clip(target)})| " },
]

begin
  require 'pry-byebug'
  Pry.commands.alias_command 'c', 'continue'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'u', 'finish' # up
  Pry.commands.alias_command 'b', 'break'
rescue LoadError
end

def pbcopy(str=nil)
  str = yield if block_given?
  IO.popen(%w[pbcopy], 'w') {|io| io.write str }
end

def tic; @_tic = Time.now; end
def toc; Time.now - @_tic; end
def rot13(s=nil); s ||= `pbpaste`; s.tr("A-Za-z","N-ZA-Mn-za-m"); end

Pry::Commands.command /^$/, "repeat last command" do
  _pry_.input = StringIO.new(Pry.history.to_a.last)
end

pryrc_local = File.expand_path('../.pryrc.local', __FILE__)
load pryrc_local if File.exists?(pryrc_local)
