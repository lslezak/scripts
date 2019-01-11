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
organization = "yast"

# uncomment for debugging, enable the gem also in Gemfile
# require "byebug"
# byebug

# read GitHub repos
client = Octokit::Client.new(access_token: ENV["GH_TOKEN"])
client.auto_paginate = true

print "Reading #{organization} GitHub repositories..."
git_repos = client.list_repositories(organization)
puts " done, #{git_repos.size} repositories found"

obsolete_hooks = []
failed_repos = []

git_repos.each do |repo|
  print "Loading #{repo.full_name} hooks... "

  begin
    hooks = client.hooks(repo.full_name)
  rescue
    puts "FAILED!"
    failed_repos << repo.full_name
    next
  end

  puts

  hooks.each do |h|
    next if h.name == "web" # || h.name == "email"

    obsolete_hooks << "#{repo.full_name} - #{h.name}"
  end
end

print "\nFound #{obsolete_hooks.size} obsolete services:\n\n"
puts obsolete_hooks.sort

if !failed_repos.empty?
  puts "\n#{failed_repos.size} repositories failed (missing permission?):"
  puts failed_repos.join(", ")
  exit 1
end
