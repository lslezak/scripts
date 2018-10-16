#!/usr/bin/env ruby

# This script creates Jenkins hooks for YaST repositories at GitHub
# and reconfigures the Jenkins jobs to use hooks instead of polling.
#
# For creating the hook you need a GitHub token with appropriate permissions.
# Pass the token via "GH_TOKEN" environment variable.
# Pass the Jenkins credentials via "JENKINS_USER" and "JENKINS_PASSWORD"
# environment variables.

# install missing gems
if !File.exist?("./vendor")
  puts "Installing needed Rubygems to ./vendor/bundle ..."
  `bundle install --path vendor/bundle`
end

require "rubygems"
require "bundler/setup"

require "octokit"
require "jenkins_api_client"
require "rexml/document"

JENKINS_URL = "https://ci.opensuse.org".freeze

# read YaST Jenkins jobs
puts "Reading YaST Jenkins jobs at #{JENKINS_URL}..."
jenkins = JenkinsApi::Client.new(server_url: JENKINS_URL,
  username: ENV["JENKINS_USER"], password: ENV["JENKINS_PASSWORD"])

jenkins_jobs = jenkins.job.list("^yast.*")
puts "Found #{jenkins_jobs.size} Jenkins jobs"

# read YaST GitHub repos with progress
github = Octokit::Client.new(access_token: ENV["GH_TOKEN"])

# We need to load the YaST repos in a loop, by default GitHub returns
# only the first 30 items (with per_page option it can be raised up to 100).
print "Reading YaST repositories at GitHub"
$stdout.flush
page = 1
git_repos = []
begin
  print "."
  $stdout.flush
  repos = github.repos("yast", page: page)
  git_repos.concat(repos)
  page += 1
end until repos.empty?

puts "\nFound #{git_repos.size} Git repositories"

repo_names = git_repos.map { |git_repo| git_repo["name"] }
repos_with_job = repo_names.select { |repo| jenkins_jobs.include?("#{repo}-master") }

puts "Found #{repos_with_job.size} repos with a Jenkins job"

# check webhooks for each repo
created = []
repos_with_job.each do |repo|
  full_repo_name = "yast/#{repo}"
  hooks = github.hooks(full_repo_name).map { |h| h["name"] }

  next unless !hooks.include?("jenkins")
  puts "Creating Jenkins hook for repository: #{repo}"
  github.create_hook(full_repo_name, "jenkins", jenkins_hook_url: "https://ci.opensuse.org/github-webhook/")
  created << repo
end
puts "Created #{created.size} hooks in repositories: #{created.join(", ")}"

# update job configs to use webhooks instead of polling
repos_with_job.each do |repo|
  job = "#{repo}-master"
  cfg = jenkins.get_config("/job/#{job}")
  xml = REXML::Document.new(cfg)

  updated = false
  # remove the polling config if present
  if xml.elements["/project/triggers/hudson.triggers.SCMTrigger"]
    xml.elements.delete("/project/triggers/hudson.triggers.SCMTrigger")
    updated = true
  end

  # add GitHub push config if missing
  if !xml.elements["/project/triggers/com.cloudbees.jenkins.GitHubPushTrigger"]
    xml.elements["/project/triggers"].add_element("com.cloudbees.jenkins.GitHubPushTrigger")
       .add_element("spec")
    updated = true
  end

  if updated
    jenkins.post_config("/job/#{repo}-master/config.xml", xml.to_s)
    puts "Jenkins #{job} job configuration updated"
  end
end
