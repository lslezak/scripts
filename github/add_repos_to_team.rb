#!/usr/bin/env ruby

# install missing gems
if !File.exist?(".vendor")
  puts "Installing the needed Rubygems to .vendor/bundle ..."
  system "bundle install --path .vendor/bundle"
end

require "rubygems"
require "bundler/setup"

require "octokit"

# a token with admin permissions is required
client = Octokit::Client.new(:access_token => '<your access token>')
client.auto_paginate = true

# the name of the organization
org_name = "<organization name>"
# the name of the team
team_name = "<team name>"

repos = client.list_repositories(org_name)

puts "Found repositories:"
puts repos.map(&:name).inspect

teams = client.organization_teams(org_name)
the_team = teams.find{|t| t.name == team_name}

repos.each do |r|
  puts "Adding repo #{r.name}..."
  client.add_team_repository(the_team.id, r.full_name, permission: 'pull')
end
