#!/usr/bin/env ruby

# This script restores a job config at Jenkins.
#
# Usage: jenkins_restore.rb <job_name> <config.xml>
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

jenkins = JenkinsApi::Client.new(server_url: JENKINS_URL,
  username: ENV["JENKINS_USER"], password: ENV["JENKINS_PASSWORD"])

job = ARGV[0]
file = ARGV[1]

if job.nil? || job.empty?
  $stderr.puts "Missing job name"
  $stderr.puts "Usage: jenkins_restore.rb <job_name> <config.xml>"
  exit 1
end

if file.nil? || file.empty?
  $stderr.puts "Missing config file name"
  $stderr.puts "Usage: jenkins_restore.rb <job_name> <config.xml>"
  exit 1
end

xml = File.read(file)

puts "Submitting #{job} job config from #{file}..."
jenkins.post_config("/job/#{job}/config.xml", xml)
puts "Done."
