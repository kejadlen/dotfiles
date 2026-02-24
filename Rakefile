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
    sh "git submodule sync"
    sh "git submodule foreach git pull"
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

desc "Update dotslash files from their GitHub releases"
task :update_dotslash do
  sh "gh release download --repo kejadlen/pinch --pattern pinch --output bin/pinch --clobber"

  require "json"
  require "open3"

  # Update jq dotslash file with latest release
  release_json, = Open3.capture2("gh", "release", "view", "--repo", "jqlang/jq", "--json", "tagName,assets")
  release = JSON.parse(release_json)
  tag = release["tagName"]
  asset = release["assets"].find { |a| a["name"] == "jq-macos-arm64" }

  url = "https://github.com/jqlang/jq/releases/download/#{tag}/jq-macos-arm64"
  digest, = Open3.capture2("dotslash", "--", "create-url-entry", url)
  entry = JSON.parse(digest)

  dotslash = {
    name: "jq",
    platforms: {
      "macos-aarch64" => {
        size: entry["size"],
        hash: "blake3",
        digest: entry["digest"],
        path: "jq",
        providers: [
          { url: url },
          { type: "github-release", repo: "https://github.com/jqlang/jq", tag: tag, name: "jq-macos-arm64" },
        ],
      },
    },
  }

  File.write("bin/jq", "#!/usr/bin/env dotslash\n\n#{JSON.pretty_generate(dotslash)}\n")
end

desc "Upgrade neovim"
task :upgrade_neovim do
  chdir File.expand_path("~/Library/Caches/Homebrew/neovim--git") do
    sh "git tag --delete nightly stable" do
      # no-op so that `sh` doesn't throw an
      # exception if a tag doesn't exist
    end
  end
  sh "brew upgrade neovim --fetch-HEAD"
end

namespace :pave do
  PATHS = %w[
    Downloads/
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
