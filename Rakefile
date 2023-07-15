namespace :clean do
end

namespace :sync do
  desc "Sync David Lanham wallpapers (assumes the unzipped updates are in ~/Downloads)"
  task :dlanham do
    rm_rf File.expand_path("~/Dropbox/wallpapers/dlanham wallpapers/Newest Additions")
    FileList[File.expand_path("~/Downloads/dlanham*")].each do |dir|
      cmd = %w[ rsync -avz --exclude *.DS_Store . ]
      cmd << File.expand_path(dir.pathmap("~/Dropbox/wallpapers/%f"))
      Dir.chdir dir do
        sh *cmd
      end
      rm_r dir
    end
  end

  desc "Sync submodules"
  task :submodules do
    sh "git submodule update --init --recursive --remote"
  end

  desc "Sync puzzles from ~/Downloads"
  task :puzzles do
    Dir[File.expand_path("~/Downloads/*")].each do |file|
      dir = case file.pathmap("%f")
            when /^diagramless\d+.pdf$/i
              "diagramless"
            when /^201\dW(?:eek)?\d.*/
              "GM"
            end
      next if dir.nil?

      dir = File.expand_path(File.join("~/Dropbox/Shared/Puzzles", dir))
      mv file, dir
    end
  end

  desc "Sync a config"
  task :config, [:config, :to] do |t, args|
    config = File.expand_path(args[:config])
    to = args[:to] || config.sub(Dir.home, '\0/.dotfiles')

    mv config, to
    ln_s to, config
  end
end

namespace :pave do
  PATHS = %w[
    Downloads/
    Library/Preferences/com.YoruFukurouProject.YoruFukurou.plist
  ]

  desc "Backup files for paving"
  task :backup, [:to_dir] do |t, args|
    to_dir = args[:to_dir]

    PATHS.each do |path|
      from = File.expand_path("~/#{path}")
      to = File.expand_path("#{to_dir}/#{path}")

      mkdir_p to.pathmap("%d")
      sh *%W[ rsync --archive --delete --verbose #{from} #{to} ]
    end
  end

  desc "Restore files for paving"
  task :restore, [:from_dir] do |t, args|
    from_dir = args[:from_dir]

    PATHS.each do |path|
      from = File.expand_path("#{from_dir}/#{path}")
      to = File.expand_path("~/#{path}")

      mkdir_p to.pathmap("%d")
      sh *%W[ rsync --archive --delete --verbose #{from} #{to} ]
    end
  end
end

namespace :init do
  desc "Set up local neovim overrides"
  task "local-nvim", [:dir] do |t, args|
    dir = File.expand_path(args.fetch(:dir))

    File.write(File.join(dir, ".vimrc.local"), <<~VIMRC_LOCAL)
      lua << EOF
        package.path = "./.dev.local/?.fnl;" .. package.path
        require("vimrc")
      EOF
    VIMRC_LOCAL

    mkdir_p File.join(dir, ".dev.local")

    File.write(File.join(dir, ".dev.local", "vimrc.fnl"), <<~VIMRC_FNL)
      (local {: setup-lsp} (require :lsp))
      ;; (setup-lsp :ruby_ls)
    VIMRC_FNL
  end
end
