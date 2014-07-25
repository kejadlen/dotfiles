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
  Dir["#{mountpoint}/ssh keys/*"].each do |file|
    cp file, File.basename(file)
    puts `chmod go-r #{File.basename(file)}`
    puts `ssh-add -K #{File.basename(file)}`
  end
end
