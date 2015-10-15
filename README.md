# AmsVarFile

AmsVarFile generates DPM and DSM variable declaration files and provides for
adding and deleting variables programmatically.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ams_var_file'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ams_var_file

## Usage

First, require the gem:

```ruby
require "ams_var_file"
```

Note: AmsVarFile can output informative messages to `$stdout` and `$stderr`.
To have the messages output, set verbose to true (it's false by default).

```ruby
AmsVarFile::File.verbose = true
```

### Generate a Var File

To generate a `DPM` var file:

```ruby
AmsVarFile::File.generate("dpm", "path/to/dpms.gdl")
```

To generate a `DSM` var file:

```ruby
AmsVarFile::File.generate("dsm", "path/to/dsms.gdl")
```

AmsVarFile will throw an `IOError` exception if the file already exists.

The generated files will contain markers that allow AmsVarFile to understand
where to insert/delete variables. Removing or modifying these markers will
result in a `InvalidFileFormat` exception being thrown.

The markers are:

    // START DEFINITIONS

    // END DEFINITIONS

    // START INITS

    // END INITS

The naming convention of the files are `dpms.gdl` for DPMs
and `dsms.gdl` for DSMs.

### Adding Variable Declarations

Before adding a variable to a file, the file must exist. See the `generation`
details above for information on generating a file.

To add a `DPM` variable:

```ruby
# var_type can be one of:
#               boolean
#               date
#               datetime
#               money
#               numeric
#               numeric(#) where '#' indicates precision
#               percentage
#               text

var_type = "text"


# var_id is a valid GDL identifier (ie, no spaces or special chars)

var_id = "myDummyVar"


# var_alias is the variable's actual name in the AMS system. It *can*
# contain spaces and such.

var_alias = "My Dummy Var"


# file_path is any valid path to the `.gdl` file to add the variable to.

file_path = "path/to/dpms.gdl"


AmsVarFile::File.add_dpm_var(var_type, var_id, var_alias, file_path)
```

Adding a `DSM` variable is virtually the same, except a different method
is called:

```ruby
var_type  = "text"
var_id    = "myDummyDSMVar"
var_alias = "My Dummy DSM Var"
file_path = "path/to/dsms.gdl"


AmsVarFile::File.add_dsm_var(var_type, var_id, var_alias, file_path)
```

### Deleting Variable Declarations

Obviously, deleting a variable from a non-existing file won't work.

To delete a `DPM` variable:

```ruby
var_id = "myDummyVar"
file_path = "path/to/dpms.gdl"


AmsVarFile::File.del_dpm_var(var_id, file_path)
```

Ditto for a `DSM` variable:

```ruby
var_id = "myDummyDSMVar"
file_path = "path/to/dsms.gdl"


AmsVarFile::File.del_dsm_var(var_id, file_path)
```

AmsVarFile will handle the deletion of a non-existing variable gracefully:
it will not throw an exception. If `verbose` is `true`, you will
see a message (output on `$stderr`) indicating the variable wasn't found.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake rspec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jmcaffee/ams_var_file.

1. Fork it ( https://github.com/jmcaffee/ams_var_file/fork )
1. Clone it (`git clone git@github.com:[my-github-username]/ams_var_file.git`)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Create tests for your feature branch
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

See [LICENSE.txt](https://github.com/jmcaffee/ams_var_file/blob/master/LICENSE.txt) for
details.

