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
require "rainbow"

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
  p.match(/^https:\/\/github.com\/(\S+)\/pull\/(\d+)/)
  next unless Regexp.last_match

  repo = Regexp.last_match[1]
  pr = Regexp.last_match[2]

  pull = client.pull_request(repo, pr)

  puts
  puts "-" * 60
  puts "Pull request #{Rainbow(p).cyan}"
  puts "Title: #{pull[:title]}"

  if pull[:merged]
    puts Rainbow("Already merged").bright.yellow
    next
  end

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
    color = status[:state] == "success" ? :green : :red
    puts "\nOverall Status: " + Rainbow("#{status[:state]}\n\n").color(color)

    if status[:state] == "failure"
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

  # if you do not want to merge or delete the source branch just comment the lines below

  puts "Merging #{repo} ##{pr}..."
  client.merge_pull_request(repo, pr)

  pull = client.pull_request(repo, pr)
  branch = pull[:head][:ref]

  puts "Deleting #{branch} branch in #{repo}..."
  client.delete_branch(repo, branch)
end
