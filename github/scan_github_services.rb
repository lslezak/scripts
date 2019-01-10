#!/usr/bin/env ruby

# This script scans for old GitHub services
#
# Pass the GitHub access token via "GH_TOKEN" environment variable.
# Generate at https://github.com/settings/tokens

# install missing gems
if !File.exist?("./vendor")
  puts "Installing needed Rubygems to ./vendor/bundle ..."
  system "bundle install --path vendor/bundle"
end

require "rubygems"
require "bundler/setup"
require "octokit"

# organization/user to scan
organization = "libyui"

# uncomment for debugging, enable the gem also in Gemfile
# require "byebug"
# byebug


# read GitHub repos
client = Octokit::Client.new(access_token: ENV["GH_TOKEN"])
client.auto_paginate = true

print "Reading GitHub repositories..."
git_repos = client.list_repositories(organization)
puts " done, #{git_repos.size} repositories found"


obsolete_hooks = []

git_repos.each do |repo|
  puts "Loading #{repo.full_name} hooks..."
  hooks = client.hooks(repo.full_name)

  hooks.each do |h|
    next if h.name == "web" # || h.name == "email"

    obsolete_hooks << "#{repo.full_name} - #{h.name}"
  end
end

print "\nFound #{obsolete_hooks.size} obsolete hooks:\n\n"

puts obsolete_hooks.sort
