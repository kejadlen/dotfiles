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
      Dir.chdir dir do
        sh 'rsync -avz --exclude "Newest Additions" --exclude "*.DS_Store" . ~/Dropbox/wallpapers/dlanham\ wallpapers'
      end
      rm_r dir
    end
  end

  desc 'Sync submodules'
  task :submodules do
    sh 'git submodule foreach git pull'
    Dir.chdir 'src/prezto' do
      sh 'git fetch upstream'
      sh 'git rebase upstream/master'
    end
  end
end
