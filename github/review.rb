#!/usr/bin/env ruby

# Usage:
# $PROGRAM_NAME [--merge] [--delete] <PR_URL> <PR_URL> ...
#   --merge     - merge the approved pull requests
#   --delete    - remove the source branch after merging,
#                 (skipped when the PR is opened from a fork)
#
# This script displays the details about the specified pull requests
# (the title, diff, Travis status).
# If everything is fine it can approve the pull request and
# optionally merges it and remov the source branch.

require "shellwords"

# install missing gems
vendor_dir = File.join(__dir__, ".vendor")
bundle_dir = File.join(vendor_dir, "bundle")

ENV["BUNDLE_GEMFILE"] = File.join(__dir__, "Gemfile")

if !File.exist?(vendor_dir)
  puts "Installing the needed Rubygems to #{bundle_dir} ..."
  system "bundle install --path #{bundle_dir.shellescape}"
end

require "rubygems"
require "bundler/setup"

require "octokit"
require "rainbow"
require "optparse"

merge_pr = false
delete_branch = false

OptionParser.new do |parser|
  parser.banner = "Usage: #{$PROGRAM_NAME} [options] PR_URL1 PR_URL2 ..."

  parser.on("-m", "--merge", "Merge the approved pull requests") do |m|
    merge_pr = m
  end

  parser.on("-d", "--delete", "Delete the source branch after merging (forks are skipped)") do |d|
    delete_branch = d
  end
end.parse!

# use ~/.netrc ?
netrc = File.join(Dir.home, ".netrc")
client_options = if ENV["GH_TOKEN"]
  # Generate at https://github.com/settings/tokens
  { access_token: ENV["GH_TOKEN"] }
elsif File.exist?(netrc) && File.read(netrc).match(/^machine api.github.com/)
  # see https://github.com/octokit/octokit.rb#authentication
  { netrc: true }
else
  raise "Github authentication not set"
end

client = Octokit::Client.new(client_options)
client.auto_paginate = true

ARGV.each do |p|
  p =~ /^https:\/\/github.com\/(\S+)\/pull\/(\d+)/
  if !Regexp.last_match
    puts "Skipping #{p.inspect}, does not look like a GitHub pull request URL"
    next
  end

  repo = Regexp.last_match[1]
  pr = Regexp.last_match[2]

  pull = client.pull_request(repo, pr)

  puts
  puts "-" * 60
  puts "Pull request #{Rainbow(p).cyan}"
  puts "Title: #{pull[:title]}"
  puts "-" * 60

  # display the diff
  system("curl -L #{pull[:diff_url]}")
  puts "-" * 60

  if pull[:merged]
    puts Rainbow("Already merged").bright.yellow
    next
  end

  # display the status (Travis)
  status_url = pull[:statuses_url]
  status_url =~ "https://api.github.com/repos/.*/statuses/(.*)"
  sha = Regexp.last_match[1]

  if sha
    status = client.status(repo, sha)
    color = status[:state] == "success" ? :green : :red
    puts "\nOverall Status: " + Rainbow("#{status[:state]}\n\n").color(color)

    if status[:state] != "success"
      status[:statuses].each do |st|
        color = st[:state] == "success" ? :green : :red
        puts Rainbow("    #{st[:state]}: #{st[:description]}").color(color)
      end
    end

    puts "-" * 60
  end

  print "\nApprove it? [Y/n] "
  next unless ["Y", "y", ""].include?($stdin.gets.strip)

  options = { event: "APPROVE", body: "LGTM" }
  puts "Approving #{repo} ##{pr}..."
  client.create_pull_request_review(repo, pr, options)

  next unless merge_pr

  puts "Merging #{repo} ##{pr}..."
  client.merge_pull_request(repo, pr)

  next unless delete_branch

  # we cannot delete the source branch from a fork (different owner)
  next if pull[:head][:repo][:fork]

  branch = pull[:head][:ref]
  puts "Deleting #{branch} branch in #{repo}..."
  client.delete_branch(repo, branch)
end
