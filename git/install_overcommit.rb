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

def install_overcommit(dir)
  # skip if overcommit is already present
  overcommit_file = File.join(dir, OVERCOMMIT_CFG)
  return if File.exist?(overcommit_file)

  rubocop_enabled = File.exist?(File.join(dir, ".rubocop.yml"))
  test_command = if File.exist?(File.join(dir, "Makefile.cvs"))
    ["make", "check"]
  else
    ["rake", "test:unit"]
  end

  config = <<EOS
# Use this file to configure the Overcommit hooks you wish to use. This will
# extend the default configuration defined in:
# https://github.com/brigade/overcommit/blob/master/config/default.yml
#
# At the topmost level of this YAML file is a key representing type of hook
# being run (e.g. pre-commit, commit-msg, etc.). Within each type you can
# customize each hook, such as whether to only run it on certain files (via
# `include`), whether to only display output if it fails (via `quiet`), etc.
#
# For a complete list of hooks, see:
# https://github.com/brigade/overcommit/tree/master/lib/overcommit/hook
#
# For a complete list of options that you can use to customize hooks, see:
# https://github.com/brigade/overcommit#configuration

CommitMsg:
  SpellCheck:
    enabled: true
    # force using the English dictionary
    env:
      LC_ALL: en_US.UTF-8

PreCommit:
  # do not commit directly to these branches, use Pull Requests!
  ForbiddenBranches:
    enabled: true
    branch_patterns:
      - master
      - openSUSE-*
      - SLE-10-*
      - Code-11*
      - SLE-12-*

  RuboCop:
    enabled: #{rubocop_enabled}
    # treat all warnings as failures
    on_warn: fail

PrePush:
  RSpec:
    enabled: true
    command: #{test_command.inspect}
    # don't fail because of translations
    env:
      LC_ALL: en_US.UTF-8
EOS

  # write the config file
  File.write(overcommit_file, config)

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

Find.find(start) do |path|
  # a Git repository?
  next unless File.directory?(File.join(path, ".git"))

  install_overcommit(path)

  # stop searching in this directory
  Find.prune
end
