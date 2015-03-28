# code [![[version]](https://badge.fury.io/rb/code.svg)](http://badge.fury.io/rb/code)

Shows a method's code with syntax highlighting. Tries to find the Ruby definition of method first, then falls back to the C version (if the `core_docs` gem is available).

## Setup

```
gem install code core_docs
```


## Usage

```ruby
# in /home/jan/.rvm/rubies/ruby-2.2.1/lib/ruby/site_ruby/2.2.0/rubygems/core_ext/kernel_require.rb:38
##
# When RubyGems is required, Kernel#require is replaced with our own which
# is capable of loading gems on demand.
#
# When you call <tt>require 'x'</tt>, this is what happens:
# * If the file can be loaded from the existing Ruby loadpath, it
#   is.
# * Otherwise, installed gems are searched for a file that matches.
#   If it's found in gem 'y', that gem is activated (added to the
#   loadpath).
#
# The normal <tt>require</tt> functionality of returning false if
# that file has already been loaded is preserved.
def require path
  RUBYGEMS_ACTIVATION_MONITOR.enter

  path = path.to_path if path.respond_to? :to_path

  spec = Gem.find_unresolved_default_spec(path)
  if spec
    Gem.remove_unresolved_default_spec(spec)
    gem(spec.name)
  end

  # If there are no unresolved deps, then we can use just try
  # normal require handle loading a gem from the rescue below.

  if Gem::Specification.unresolved_deps.empty? then
    RUBYGEMS_ACTIVATION_MONITOR.exit
    return gem_original_require(path)
  end

  # If +path+ is for a gem that has already been loaded, don't
  # bother trying to find it in an unresolved gem, just go straight
  # to normal require.
  #--
  # TODO request access to the C implementation of this to speed up RubyGems

  spec = Gem::Specification.stubs.find { |s|
    s.activated? and s.contains_requirable_file? path
  }

  begin
    RUBYGEMS_ACTIVATION_MONITOR.exit
    return gem_original_require(spec.to_fullpath(path) || path)
  end if spec

  # Attempt to find +path+ in any unresolved gems...

  found_specs = Gem::Specification.find_in_unresolved path

  # If there are no directly unresolved gems, then try and find +path+
  # in any gems that are available via the currently unresolved gems.
  # For example, given:
  #
  #   a => b => c => d
  #
  # If a and b are currently active with c being unresolved and d.rb is
  # requested, then find_in_unresolved_tree will find d.rb in d because
  # it's a dependency of c.
  #
  if found_specs.empty? then
    found_specs = Gem::Specification.find_in_unresolved_tree path

    found_specs.each do |found_spec|
      found_spec.activate
    end

  # We found +path+ directly in an unresolved gem. Now we figure out, of
  # the possible found specs, which one we should activate.
  else

    # Check that all the found specs are just different
    # versions of the same gem
    names = found_specs.map(&:name).uniq

    if names.size > 1 then
      RUBYGEMS_ACTIVATION_MONITOR.exit
      raise Gem::LoadError, "#{path} found in multiple gems: #{names.join ', '}"
    end

    # Ok, now find a gem that has no conflicts, starting
    # at the highest version.
    valid = found_specs.select { |s| s.conflicts.empty? }.last

    unless valid then
      le = Gem::LoadError.new "unable to find a version of '#{names.first}' to activate"
      le.name = names.first
      RUBYGEMS_ACTIVATION_MONITOR.exit
      raise le
    end

    valid.activate
  end

  RUBYGEMS_ACTIVATION_MONITOR.exit
  return gem_original_require(path)
rescue LoadError => load_error
  RUBYGEMS_ACTIVATION_MONITOR.enter

  if load_error.message.start_with?("Could not find") or
      (load_error.message.end_with?(path) and Gem.try_activate(path)) then
    RUBYGEMS_ACTIVATION_MONITOR.exit
    return gem_original_require(path)
  else
    RUBYGEMS_ACTIVATION_MONITOR.exit
  end

  raise load_error
end
```

```c
>> Code.for File, :open #=> nil
// in io.c:6219
// call-seq:
//    IO.open(fd, mode="r" [, opt])                -> io
//    IO.open(fd, mode="r" [, opt]) { |io| block } -> obj
// 
// With no associated block, <code>IO.open</code> is a synonym for IO.new.  If
// the optional code block is given, it will be passed +io+ as an argument,
// and the IO object will automatically be closed when the block terminates.
// In this instance, IO.open returns the value of the block.
// 
// See IO.new for a description of the +fd+, +mode+ and +opt+ parameters.
static VALUE
rb_io_s_open(int argc, VALUE *argv, VALUE klass)
{
    VALUE io = rb_class_new_instance(argc, argv, klass);

    if (rb_block_given_p()) {
	return rb_ensure(rb_yield, io, io_close, io);
    }

    return io;
}

```

## Goal

Be as powerful as pry's source browsing: https://github.com/pry/pry/wiki/Source-browsing


## MIT License

Copyright (C) 2015 Jan Lelis <http://janlelis.com>. Released under the MIT license.
