require 'rbconfig'
# ruby 1.8.7 doesn't define RUBY_ENGINE
ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
ruby_version = RbConfig::CONFIG["ruby_version"]
path = File.expand_path('..', __FILE__)
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/builder-3.2.2/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/alphred-1.1.1/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/multipart-post-2.0.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/faraday-0.9.2/lib"
