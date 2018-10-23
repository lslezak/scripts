#!/usr/bin/env ruby

# This script saves configs for YaST jobs at Jenkins.
#
# Pass the Jenkins credentials via "JENKINS_USER" and "JENKINS_PASSWORD"
# environment variables.

# install missing gems
if !File.exist?("./vendor")
  puts "Installing needed Rubygems to ./vendor/bundle ..."
  `bundle install --path vendor/bundle`
end

require "rubygems"
require "bundler/setup"

require "jenkins_api_client"

JENKINS_URL = "https://ci.opensuse.org".freeze

puts "Reading YaST Jenkins jobs at #{JENKINS_URL}..."
jenkins = JenkinsApi::Client.new(server_url: JENKINS_URL,
  username: ENV["JENKINS_USER"], password: ENV["JENKINS_PASSWORD"])

jenkins_jobs = jenkins.job.list_all.select { |j| j.match(/^yast|^libyui/) }
puts "Found #{jenkins_jobs.size} Jenkins jobs"

jenkins_jobs.each do |job|
  cfg = jenkins.get_config("/job/#{job}")
  File.write("#{job}.xml", cfg)
  puts "Saved config to #{job}.xml"
end
