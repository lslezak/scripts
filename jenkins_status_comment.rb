#! /usr/bin/env ruby
#
# This script parses the "rake osc:sr" output and creates a SR link comment
# at the respective GitHub repository
#
# Usage: Export the GitHub token in the GH_TOKEN environment variable, then run
#   ./travis-status-update <command>
#
# example:
#   ./travis-status-update rake osc:sr

require "net/http"
require "uri"
require "json"
require "tempfile"
require "shellwords"

# get the  GitHub repository name in the current directory
# @return [String,nil] repository or nil if not found
def git_repo
  url = `git config --get remote.origin.url`
  # e.g. git@github.com:yast/yast-yast2.git
  # or https://github.com/yast/yast-yast2.git
  if url.match(/git@github.com:(.*)\.git/)
    return Regexp.last_match[1]
  else
    url.match(/https:\/\/github.com\/(.*)\.git/)[1]
  end
end

# get the git commit hash for the repository in the current directory
# @return [String,nil] hash or nil if not found
def git_commit
  `git rev-parse HEAD`.chomp
end

def closed_pulls
  # see https://developer.github.com/v3/pulls/
  query  = {
    "state" => "closed",
    "sort" => "updated",
    "direction" => "desc"
  }

  http_get("https://api.github.com/repos/#{git_repo}/pulls", query)
end

# Get the pull request for the current Git checkout
# @return [Hash] Parsed GitHub response
#
def git_pr
  # simple case - merged with "Merge" button at GitHub with the default message
  # containing the pull request number
  git_log = `git log -n 1 --oneline`
  if git_log.match(/Merge pull request #(\d+) from/)
    return "number" => Regexp.last_match[1]
  end

  # otherwise we need to find the latest commit in the merged
  # pull requests

  # get the closed pull requests
  response = closed_pulls
  return nil unless response.is_a?(Net::HTTPSuccess)

  pulls = JSON.parse(response.body)
  commit = git_commit

  # check if the latest commit SHA matches any "merge_commit_sha" in the pulls
  pulls.find do |pull|
    pull["merge_commit_sha"] == commit
  end
end

# parse the rake osc:sr output and find the URL of the created repository
# and the context (OBS/IBS)
# @return [Hash<Symbol, String>] SR data
def osc_info(log)
  if log =~ /^osc -A '([^']*)'/
    if Regexp.last_match[1] == "https://api.suse.de/"
      return { bs: "IBS"}
    else
      return { bs: "OBS"}
    end
  end

  if log =~ /^created request id ([0-9]+)/
    return { sr:   Regexp.last_match[1] }
  end
end

# post the status at GitHub, runs HTTP POST
# @param url [String] GitHub status URL
# @param data [Hash] HTTP data (sent as JSON)
# @return [Net::HTTPResponse] HTTP response
def http_request(url, type, data, query)
  uri = URI.parse(url)
  uri.query = URI.encode_www_form(query) unless query.nil?
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true if uri.scheme == "https"

  request = type.new(uri.request_uri, http_headers)
  request.body = data.to_json unless data.nil?

  print "Sending #{type} request to #{url}..."
  # Send the request
  res = https.request(request)
  if res.is_a?(Net::HTTPSuccess)
    puts " OK"
  else
    puts " Failed: #{res.code}: #{res.body}"
  end

  res
end

# post the status at GitHub, runs HTTP POST
# @param url [String] GitHub status URL
# @param headers [Hash] HTTP headers
# @param data [Hash] HTTP data (sent as JSON)
# @return [Net::HTTPResponse] HTTP response
def http_post(url, headers, data)
  http_request(url, Net::HTTP::Post, data, nil)
end

# post the status at GitHub, runs HTTP POST
# @param url [String] the target URL
# @param data [Hash] the HTTP data, sent as JSON
# @return [Net::HTTPResponse] HTTP response
def http_get(url, query = nil)
  http_request(url, Net::HTTP::Get, nil, query)
end

def build_comment(status, log)
  message = if status.success?
    ":heavy_check_mark: [Jenkins job ##{ENV["BUILD_DISPLAY_NAME"]}]" \
    "(#{ENV["BUILD_URL"]}) successfully finished"
  else
    ":x: [Jenkins job ##{ENV["BUILD_DISPLAY_NAME"]}](#{ENV["BUILD_URL"]}) failed"
  end

  info = {}

  # read by lines, the log might be HUGE...
  f = File.new(log)
  f.each do |line|
    line_info = osc_info(line)
    info.merge!(line_info) if line_info
  end
  f.close

  return message if info.empty?

  host = (info[:bs] == "IBS") ? "build.suse.de" : "build.opensuse.org"
  url = "https://#{host}/request/show/#{info[:sr]}"

  message << "\n:heavy_check_mark: Created #{info[:bs]} submit " \
      "[request ##{info[:sr]}](#{url})"
end

def http_headers(content_type = "text/json")
  headers = {
    "Content-Type"  => content_type
  }
  headers["Authorization"] = "token #{ENV["GH_TOKEN"]}" if ENV["GH_TOKEN"]
  headers
end

##############################################################################

require 'optparse'

dry_run = false

OptionParser.new do |opts|
  opts.on("-d", "--dry-run", "Dry run (do not send the comment)") do
    dry_run = true
  end
end.parse!

if ARGV.empty?
  puts "Missing command parameter!"
  exit 1
end

status = nil
message = nil
Tempfile.open("jenkinslog") do |f|
  command = ARGV.map{|c| Shellwords.escape(c)}.join(" ") + " | tee #{f.path}"
  cmd = ["bash",  "-o",  "pipefail", "-c", command ]
  system(*cmd)
  status = $?
  puts "Result: PID #{status.pid} exited with value #{status.exitstatus}"
  message = build_comment(status, f.path)
end

puts "Scanning for a pull request..."
pr = git_pr

if pr
  puts "Found pull request ##{pr["number"]}"
else
  puts "Pull request not found"
  exit status.exitstatus
end

url = "https://api.github.com/repos/#{git_repo}/issues/#{pr["number"]}/comments"

puts "Adding comment \"#{message}\""
puts "to pull request https://github.com/#{git_repo}/pull/#{pr["number"]}"

if dry_run
  puts "Dry-run active stopping here."
  exit status.exitstatus
end

res = http_post(url, http_headers, "body" => message)
if res.is_a?(Net::HTTPSuccess)
  puts " Success"
else
  puts " Error #{res.code}: #{res.body}"
end

exit status.exitstatus
