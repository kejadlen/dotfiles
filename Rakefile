# rsync -avz --exclude 'Newest Additions' --exclude '*.DS_Store' . ~/Dropbox/wallpapers/dlanham\ wallpapers

namespace :clean do
  desc 'Remove .DS_Store files from Dropbox'
  task :ds_store do
    sh 'find ~/Dropbox -name .DS_Store -print0 | xargs -0 rm -v'
  end

  task all: %i[ ds_store ]
end

namespace :sync do
  desc 'Sync David Lanham wallpapers (assumes the unzipped updates are in ~/Downloads)'
  task :dlanham do
    FileList[File.expand_path('~/Downloads/dlanham*')].each do |dir|
      Dir.chdir dir
      sh 'rsync -avz --exclude "Newest Additions" --exclude "*.DS_Store" . ~/Dropbox/wallpapers/dlanham\ wallpapers'
    end
  end
end
