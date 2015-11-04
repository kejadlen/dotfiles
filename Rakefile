namespace :clean do
  desc "Remove .DS_Store files from Dropbox"
  task :ds_store do
    sh "find ~/Dropbox -name .DS_Store -print0 | xargs -0 rm -v"
  end

  task all: %i[ ds_store ]
end

namespace :sync do
  desc "Sync David Lanham wallpapers (assumes the unzipped updates are in ~/Downloads)"
  task :dlanham do
    rm_rf File.expand_path("~/Dropbox/wallpapers/dlanham wallpapers/Newest Additions")
    FileList[File.expand_path("~/Downloads/dlanham*")].each do |dir|
      Dir.chdir dir do
        sh 'rsync -avz --exclude "*.DS_Store" . ~/Dropbox/wallpapers/dlanham\ wallpapers'
      end
      rm_r dir
    end
  end

  desc "Sync submodules"
  task :submodules do
    sh "git submodule foreach git pull"
    Dir.chdir "src/prezto" do
      sh "git fetch upstream"
      sh "git rebase upstream/master"
      sh "git submodule update --init --recursive"
    end
  end

  desc "Sync crosswords from ~/Downloads"
  task :crosswords do
    # Dir[File.expand_path('~/Downloads/*.puz')].each do |puz|
    #   crossword = File.basename(puz, '.puz')
    #   dir = case crossword
    #         when /av\d{6}/
    #           'AV'
    #         when /\d{3}[a-zA-Z]+/
    #           'BEQ'
    #         when /mgwcc\d{3}/
    #           'MGWCC'
    #         when /[A-Z][a-z]{2}\d{4}/
    #           'NYT'
    #         else
    #           'etc'
    #         end
    #   dir = File.expand_path("~/Dropbox/Shared/Crosswords/#{dir}")
    #   FileUtils.mv puz, to, verbose: true
    # end
  end
end
