# Alphred

Alphred is a library for making Alfred workflows in Ruby. It's designed
specifically for how I work, so assumes that you manage dependencies with
[Bundler][bundler] and Rubies with [chruby][chruby].

[bundler]: http://bundler.io/
[chruby]: https://github.com/postmodern/chruby

## Usage

The [example script filter][scriptfilter] would look like this using Alphred:

[scriptfilter]: https://www.alfredapp.com/help/workflows/inputs/script-filter/

``` ruby
items = Alphred::Items.new(
  Alphred::Item.new(uid: "desktop",
                    arg: "~/Desktop",
                    valid: true,
                    autocomplete: "Desktop",
                    type: :file,
                    title: "Desktop",
                    subtitle: "~/Desktop",
                    icon: { value: "~/Desktop", type: :fileicon }),
  Alphred::Item.new(uid: "flickr",
                    valid: false,
                    autocomplete: "flickr",
                    title: "Flickr",
                    icon: "flickr.png"),
  Alphred::Item.new(uid: "image",
                    autocomplete: "My holiday photo",
                    type: :file,
                    title: "My holiday photo",
                    subtitle: "~/Pictures/My holiday photo.jpg",
                    icon: { value: "public.jpeg", type: :filetype }),
  Alphred::Item.new(uid: "home",
                    arg: "~/",
                    valid: true,
                    autocomplete: "Home",
                    type: :file,
                    title: "Home Folder",
                    subtitle: "Home folder ~/",
                    icon: { value: "~/", type: :fileicon },
                    mods: { shift: "Subtext when shift is pressed",
                            fn: "Subtext when fn is pressed",
                            ctrl: "Subtext when ctrl is pressed",
                            alt: "Subtext when alt is pressed",
                            cmd: "Subtext when cmd is pressed" },
                    text: { copy: "Text when copying",
                            largetype: "Text for LargeType" }))
items.to_xml
```

This produces the following XML:

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<items>
  <item uid="desktop" arg="~/Desktop" autocomplete="Desktop" type="file" valid="yes">
    <title>Desktop</title>
    <subtitle>~/Desktop</subtitle>
    <icon type="fileicon">~/Desktop</icon>
  </item>
  <item uid="flickr" autocomplete="flickr" valid="no">
    <title>Flickr</title>
    <icon>flickr.png</icon>
  </item>
  <item uid="image" autocomplete="My holiday photo" type="file">
    <title>My holiday photo</title>
    <subtitle>~/Pictures/My holiday photo.jpg</subtitle>
    <icon type="filetype">public.jpeg</icon>
  </item>
  <item uid="home" arg="~/" autocomplete="Home" type="file" valid="yes">
    <title>Home Folder</title>
    <subtitle>Home folder ~/</subtitle>
    <icon type="fileicon">~/</icon>
    <subtitle mod="shift">Subtext when shift is pressed</subtitle>
    <subtitle mod="fn">Subtext when fn is pressed</subtitle>
    <subtitle mod="ctrl">Subtext when ctrl is pressed</subtitle>
    <subtitle mod="alt">Subtext when alt is pressed</subtitle>
    <subtitle mod="cmd">Subtext when cmd is pressed</subtitle>
    <text type="copy">Text when copying</text>
    <text type="largetype">Text for LargeType</text>
  </item>
</items>
```

### Workflow Configuration

`Alphred::Config` provides some helpers for managing configuration that should
persist when updating the workflow. This configuration is stored in an JSON
file in the workflow data directory.

``` ruby
# config.rb

module Workflow
  defaults = { foo: "bar" }
  Config = Alphred::Config.new(**defaults)
```

The corresponding Script Filter input and Run Action output then look like this:

``` shell
# script filter

ruby -r./config -e'puts Workflow::Config.filter_xml("{query}")'
```

``` shell
# run action

ruby -r./config -e'Forecast::Config.update!("{query}")'
```

### Releasing

Including `alphred/tasks` in your `Rakefile` will allow access to Alphred's
Rake tasks for releasing a workflow. `release` will tag the current commit with
the provided version and create a .alfredworkflow package with vendored gem
dependencies.

## TODO

- Add development mode for easier debugging. (Nicer errors, etc.)

## Development

After checking out the repo, run `bundle install` to install dependencies.
Then, run `rake test` to run the tests. You can also run `rake console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/kejadlen/alphred. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

