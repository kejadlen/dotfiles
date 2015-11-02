require "rake"

namespace :alphred do
  desc "Prepare a release, named after the directory"
  task :release, [:version] => [:tag, :package]

  desc "Tag the current commit in git with VERSION"
  task :tag, [:version] do |t, args|
    version = args[:version]

    git_status = `git status --porcelain`
    fail <<-FAIL unless git_status.empty?
Can't tag #{version}: dirty working directory.
    FAIL

    sh "git tag #{version}"
  end

  desc "Create an alfredworkflow package with vendored dependencies"
  task :package do
    restore_bundler_config do
      cmd = "bundle install --standalone --path vendor/bundle --without development test"
      sh "chruby-exec 2.0.0 -- #{cmd}"
    end
    sh "zip -r #{application_dir.pathmap("%n.alfredworkflow")} *"
    rm_rf "vendor"
  end

  def application_dir
    Rake.application.original_dir
  end

  def restore_bundler_config
    path = File.join(application_dir, ".bundle", "config")
    config = File.read(path)
    yield
  ensure
    File.write(path, config, mode: ?w)
  end
end
