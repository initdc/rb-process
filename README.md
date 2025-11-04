# Rb::Process

Add the missing methods to the Ruby Process, you can use it with method chaining

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add rb-process

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install rb-process

## Usage

```ruby
require "rb/process"

Process.run("bash", "r+") { |pipe| pipe.puts "uname" }
# => "Linux\n"

Process.output("ls spec").each_line(chomp: true).to_a
# => ["rb", "spec_helper.rb"]

Process.code("uname -s")
# => 0
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/initdc/rb-process.
