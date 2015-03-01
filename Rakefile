# rsync -avz --exclude 'Newest Additions' --exclude '*.DS_Store' . ~/Dropbox/wallpapers/dlanham\ wallpapers

namespace :clean do
  task :ds_store do
    sh 'find ~/Dropbox -name .DS_Store -print0 | xargs -0 rm'
  end

  task all: %i[ ds_store ]
end
