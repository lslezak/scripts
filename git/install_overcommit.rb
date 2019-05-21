#!/usr/bin/env ruby
#
# This scripts automatically installs the overcommit Git hooks.
# It scans the subdirectories recursively for Git repositories.
#
# Usage:
#   ./install_overcommit.rb [path]
#
# If path is given it scans that directory, if not specified it scans
# the current directory.
#
# See https://github.com/brigade/overcommit for more details about
# the Overcommit tool.

# Overcommit configuration
OVERCOMMIT_CFG = ".overcommit.yml".freeze

def install_overcommit(dir, template)
  # skip if overcommit is already present
  overcommit_file = File.join(dir, OVERCOMMIT_CFG)
  return if File.exist?(overcommit_file)

  return unless File.exist?(File.join(dir, "Makefile.cvs")) || File.exist?(File.join(dir, "Rakefile"))

  rubocop_enabled = File.exist?(File.join(dir, ".rubocop.yml"))
  add_rubocop = !Dir["#{dir}/**/*.rb"].empty?

  test_command = if File.exist?(File.join(dir, "Makefile.cvs"))
    ["make", "check"]
  else
    ["rake", "test:unit"]
  end

  erb = ERB.new(template)
  # write the config file
  File.write(overcommit_file, erb.result(binding))

  # install the hooks
  Dir.chdir(dir) do
    system "overcommit --install"
    system "overcommit --sign"
  end

  puts
end

# traverse the directory using the Find module
# see http://ruby-doc.org/stdlib-2.1.3/libdoc/find/rdoc/Find.html
require "find"
start = ARGV[0] || "."

template = File.read(File.join(__dir__, "overcommit_template.yml.erb"))

Find.find(start) do |path|
  # a Git repository?
  next unless File.directory?(File.join(path, ".git"))

  install_overcommit(path, template)

  # stop searching in this directory
  Find.prune
end
