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
# or see https://github.com/octokit/octokit.rb#authentication
client = Octokit::Client.new(access_token: ENV["GH_TOKEN"])
client.auto_paginate = true

ARGV.each do |p|
  p.match(/^https:\/\/github.com\/(\S+)\/pull\/(\d+)/)
  next unless Regexp.last_match

  repo = Regexp.last_match[1]
  pr = Regexp.last_match[2]

  pull = client.pull_request(repo, pr)

  puts
  puts "-" * 60
  puts "Pull request #{p}:"
  puts "Title: #{pull[:title]}"
  puts "-" * 60

  # display the diff
  system("curl -L #{pull[:diff_url]}")
  puts "-" * 60

  # display the status (Travis)
  status_url = pull[:statuses_url]
  status_url.match("https://api.github.com/repos/.*/statuses/(.*)")
  sha = Regexp.last_match[1]

  if sha
    status = client.status(repo, sha)
    puts "\nStatus: #{status[:state]}\n\n"
    puts "-" * 60
  end

  print "\nApprove it? [Y/n] "
  next unless ["Y", "y", ""].include?($stdin.gets.strip)

  options = { event: "APPROVE", body: "LGTM" }
  puts "Approving #{repo} ##{pr}..."
  client.create_pull_request_review(repo, pr, options)

  # if you do not want to merge or delete the source branch just comment the lines below

  puts "Merging #{repo} ##{pr}..."
  client.merge_pull_request(repo, pr)

  pull = client.pull_request(repo, pr)
  branch = pull[:head][:ref]

  puts "Deleting #{branch} branch in #{repo}..."
  client.delete_branch(repo, branch)
end
