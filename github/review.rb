#!/usr/bin/env ruby

# Usage:
# $PROGRAM_NAME <PR_URL> <PR_URL> ...
#
# This script approves a PR, merges it and removes the source branch

# install missing gems
if !File.exist?(".vendor")
  puts "Installing the needed Rubygems to .vendor/bundle ..."
  system "bundle install --path .vendor/bundle"
end

require "rubygems"
require "bundler/setup"

require "octokit"

# Generate at https://github.com/settings/tokens
client = Octokit::Client.new(access_token: ENV["GH_TOKEN"])
client.auto_paginate = true

ARGV.each do |p|
  p.match(/^https:\/\/github.com\/(yast\/\S+)\/pull\/(\d+)/)
  next unless Regexp.last_match

  repo = Regexp.last_match[1]
  pr = Regexp.last_match[2]

  options = { event: "APPROVE", body: "LGTM" }
  puts "Approving #{repo} ##{pr}"
  client.create_pull_request_review(repo, pr, options)

  puts "Merging #{repo} ##{pr}"
  client.merge_pull_request(repo, pr)

  pull = client.pull_request(repo, pr)
  branch = pull[:head][:ref]

  puts "Deleting #{branch} branch in #{repo}"
  client.delete_branch(repo, branch)
end
