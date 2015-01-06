require 'fileutils'

include FileUtils

def with_mount(image)
  out = `hdiutil mount #{image}`
  mountpoint = out.split(/\s+/).last
  yield(mountpoint)
ensure
  puts `hdiutil unmount #{mountpoint}`
end

cd File.expand_path('~/.ssh')

with_mount "~/Dropbox/sekritz.sparseimage" do |mountpoint|
  from = Dir["#{mountpoint}/ssh keys/*"]
  to = from.map {|file| File.basename(file) }
  from.zip(to).each do |from, to|
    next if File.exist?(to)

    cp from, to
    puts `chmod go-r #{to}`
    puts `ssh-add -K #{to}`
  end
end
