require "json"

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

namespace :dotslash do
  # The tag recorded in an existing bin/<name>, or nil when it has yet to be
  # generated.
  def dotslash_tag(file)
    return nil unless File.exist?(file)

    providers = JSON.parse(File.read(file).sub(/\A#!.*\n/, ""))
      .dig("platforms", "macos-aarch64", "providers") || []
    provider = providers.find { |p| p["type"] == "github-release" }
    provider && provider["tag"]
  rescue JSON::ParserError
    nil
  end

  # The block receives the tag and returns a hash of DotSlash platform to
  # asset name. A `path` proc receives each asset name.
  def update_dotslash_release(name:, repo:, path: name, tag: nil, &assets)
    unless tag
      tag = JSON.parse(`gh release view --repo #{repo} --json tagName`)["tagName"]
    end

    platforms = assets.call(tag).transform_values do |asset_name|
      url = "https://github.com/#{repo}/releases/download/#{tag}/#{asset_name}"
      output = `dotslash -- create-url-entry #{url}`
      raise "create-url-entry failed for #{url}" unless $?.success?

      entry = JSON.parse(output)

      platform = {
        size: entry["size"],
        hash: "blake3",
        digest: entry["digest"],
        path: path.respond_to?(:call) ? path.call(asset_name) : path,
        providers: [
          { url: url },
          { type: "github-release", repo: "https://github.com/#{repo}", tag: tag, name: asset_name },
        ],
      }
      platform[:format] = entry["format"] if entry["format"] && !entry["format"].start_with?("TODO")
      platform
    end

    dotslash = { name: name, platforms: platforms }

    file = "bin/#{name}"
    previous_tag = dotslash_tag(file)
    contents = "#!/usr/bin/env dotslash\n\n#{JSON.pretty_generate(dotslash)}\n"
    unchanged = File.exist?(file) && File.read(file) == contents
    File.write(file, contents) unless unchanged

    puts(if previous_tag.nil?
           "#{name}: added #{tag}"
         elsif unchanged
           "#{name}: up to date (#{tag})"
         elsif previous_tag == tag
           "#{name}: regenerated (#{tag})"
         else
           "#{name}: #{previous_tag} → #{tag}"
         end)
  end

  desc "Update jq"
  task(:jq) do
    update_dotslash_release(name: "jq", repo: "jqlang/jq") do
      {
        "macos-aarch64" => "jq-macos-arm64",
        "linux-aarch64" => "jq-linux-arm64",
        "linux-x86_64" => "jq-linux-amd64",
      }
    end
  end

  desc "Update jj"
  task(:jj) do
    update_dotslash_release(name: "jj", repo: "jj-vcs/jj") do |tag|
      {
        "macos-aarch64" => "jj-#{tag}-aarch64-apple-darwin.tar.gz",
        "linux-aarch64" => "jj-#{tag}-aarch64-unknown-linux-musl.tar.gz",
        "linux-x86_64" => "jj-#{tag}-x86_64-unknown-linux-musl.tar.gz",
      }
    end
  end

  desc "Update just"
  task(:just) do
    update_dotslash_release(name: "just", repo: "casey/just") do |tag|
      {
        "macos-aarch64" => "just-#{tag}-aarch64-apple-darwin.tar.gz",
        "linux-aarch64" => "just-#{tag}-aarch64-unknown-linux-musl.tar.gz",
        "linux-x86_64" => "just-#{tag}-x86_64-unknown-linux-musl.tar.gz",
      }
    end
  end

  desc "Update fzf"
  task(:fzf) do
    update_dotslash_release(name: "fzf", repo: "junegunn/fzf") do |tag|
      version = tag.delete_prefix("v")
      {
        "macos-aarch64" => "fzf-#{version}-darwin_arm64.tar.gz",
        "linux-aarch64" => "fzf-#{version}-linux_arm64.tar.gz",
        "linux-x86_64" => "fzf-#{version}-linux_amd64.tar.gz",
      }
    end
  end

  desc "Update zizmor"
  task(:zizmor) do
    update_dotslash_release(name: "zizmor", repo: "zizmorcore/zizmor") do
      {
        "macos-aarch64" => "zizmor-aarch64-apple-darwin.tar.gz",
        "linux-aarch64" => "zizmor-aarch64-unknown-linux-gnu.tar.gz",
        "linux-x86_64" => "zizmor-x86_64-unknown-linux-gnu.tar.gz",
      }
    end
  end

  desc "Update sops"
  task(:sops) do
    update_dotslash_release(name: "sops", repo: "getsops/sops") do |tag|
      {
        "macos-aarch64" => "sops-#{tag}.darwin.arm64",
        "linux-aarch64" => "sops-#{tag}.linux.arm64",
        "linux-x86_64" => "sops-#{tag}.linux.amd64",
      }
    end
  end

  age_assets = lambda do |tag|
    {
      "macos-aarch64" => "age-#{tag}-darwin-arm64.tar.gz",
      "linux-aarch64" => "age-#{tag}-linux-arm64.tar.gz",
      "linux-x86_64" => "age-#{tag}-linux-amd64.tar.gz",
    }
  end

  desc "Update age"
  task(:age) do
    update_dotslash_release(name: "age", repo: "FiloSottile/age", path: "age/age", &age_assets)
  end

  desc "Update age-keygen"
  task("age-keygen") do
    update_dotslash_release(name: "age-keygen", repo: "FiloSottile/age", path: "age/age-keygen", &age_assets)
  end

  desc "Update tree-sitter"
  task(:tree_sitter) do
    update_dotslash_release(name: "tree-sitter", repo: "tree-sitter/tree-sitter") do
      {
        "macos-aarch64" => "tree-sitter-macos-arm64.gz",
        "linux-aarch64" => "tree-sitter-linux-arm64.gz",
        "linux-x86_64" => "tree-sitter-linux-x64.gz",
      }
    end
  end

  desc "Update ramekin"
  task(:ramekin) do
    update_dotslash_release(name: "ramekin", repo: "kejadlen/ramekin") do
      { "macos-aarch64" => "ramekin-aarch64-apple-darwin.tar.gz" }
    end
  end

  desc "Update cq"
  task(:cq) do
    update_dotslash_release(name: "cq", repo: "technicalpickles/cq", path: ->(asset) { "#{asset.delete_suffix(".tar.gz")}/cq" }) do |tag|
      version = tag.delete_prefix("v")
      {
        "macos-aarch64" => "cq-#{version}-aarch64-apple-darwin.tar.gz",
        "linux-aarch64" => "cq-#{version}-aarch64-unknown-linux-gnu.tar.gz",
        "linux-x86_64" => "cq-#{version}-x86_64-unknown-linux-gnu.tar.gz",
      }
    end
  end

  desc "Update ranger"
  task(:ranger) do
    update_dotslash_release(name: "ranger", repo: "kejadlen/ranger") do
      {
        "macos-aarch64" => "ranger-aarch64-apple-darwin.tar.gz",
        "linux-aarch64" => "ranger-aarch64-unknown-linux-gnu.tar.gz",
      }
    end
  end

  desc "Update frork"
  task(:frork) do
    update_dotslash_release(name: "frork", repo: "kejadlen/frork") do
      {
        "macos-aarch64" => "frork-aarch64-apple-darwin.tar.gz",
        "linux-aarch64" => "frork-aarch64-unknown-linux-gnu.tar.gz",
        "linux-x86_64" => "frork-x86_64-unknown-linux-gnu.tar.gz",
      }
    end
  end

  desc "Update all dotslash files"
  task all: %i[
    age
    age-keygen
    cq
    fzf
    frork
    jj
    jq
    just
    ramekin
    ranger
    sops
    tree_sitter
    zizmor
  ]
end

desc "Upgrade neovim"
task :upgrade_neovim do
  # fetch.prunetags fetches tags despite brew's --no-tags, so the moving
  # nightly/stable tags would otherwise be rejected as clobbers.
  %w[tree-sitter neovim].each do |formula|
    chdir File.expand_path("~/Library/Caches/Homebrew/#{formula}--git") do
      sh "git tag --delete nightly stable" do
        # no-op so that `sh` doesn't throw an
        # exception if a tag doesn't exist
      end
    end
  end
  sh "brew upgrade tree-sitter --fetch-HEAD"
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
