#!/usr/bin/env ruby

require "json"
require "shellwords"
require_relative "threading"

# cache the read repos from Github
CACHE_FILE = ".yast_repos_cache.json"
# 2 weeks
CACHE_TIMEOUT = 60*60*24*14

def read_yast_cache
  if File.exist?(CACHE_FILE) && File.stat(CACHE_FILE).mtime + CACHE_TIMEOUT > Time.now
    return JSON.parse(File.read CACHE_FILE)
  end

  repos = JSON.parse(`curl -s 'https://api.github.com/orgs/yast/repos?page=1&per_page=100'`).map{|r| r["name"]}
  repos += JSON.parse(`curl -s 'https://api.github.com/orgs/yast/repos?page=2&per_page=100'`).map{|r| r["name"]}

  repos.sort!

  File.write(CACHE_FILE, JSON.generate(repos))

  repos
end

def run_in(dir, cmd)
  attempt = 1

  loop do
    `(cd #{Shellwords.escape(dir)} && #{cmd})`

    break if $?.success?

    if attempt > 5
      $stderr.puts "Command #{cmd.inspect} still fails, giving up"
      exit(1)
    end

    attempt += 1
    $stderr.puts "Error: #{$?.exitstatus}, retrying in 10 seconds..."
    sleep(10)
  end
end


repos = read_yast_cache
puts "Found #{repos.size} Yast repositories"

IGNORE = [
  "skelcd-control-SLES-for-VMware",
  "rubygem-scc_api",
  "yast-backup",
  "yast-bluetooth",
  "yast-boot-server",
  "yast-cd-creator",
  "yast-certify",
  "yast-cim",
  "yast-databackup",
  "yast-dbus-client",
  "yast-debugger",
  "yast-dialup",
  "yast-dirinstall",
  "yast-fax-server",
  "yast-fingerprint-reader",
  "yast-heartbeat",
  "yast-hpc",
  "yast-ipsec",
  "yast-irda",
  "yast-liby2util",
  "yast-meta",
  "yast-mouse",
  "yast-mysql-server",
  "yast-ntsutils",
  "yast-oem-installation",
  "yast-online-update-test",
  "yast-openschool",
  "yast-openteam",
  "yast-openwsman-yast",
  "yast-packagemanager",
  "yast-packagemanager-test",
  "yast-phone-services",
  "yast-power-management",
  "yast-profile-manager",
  "yast-repair",
  "yast-restore",
  "yast-squidguard",
  "yast-sshd",
  "yast-sudo",
  "yast-support",
  "yast-system-profile",
  "yast-system-update",
  "yast-ui-qt-tests",
  "yast-uml",
  "yast-you-server",
  "yast-yxmlconv",
  "yast-y2pmsh",
  "yast-y2r-tools",
]

repos = repos - IGNORE
puts "Ignoring #{IGNORE.size} obsoleted repositories, using #{repos.size} repositories"

repos.sort!

Threading.in_parallel(repos) do |repo|
  dir = repo.sub(/^yast-/, "")

  if File.exist?(dir)
    puts "Updating #{dir}..."

    run_in(dir, "git reset --hard")
    run_in(dir, "git checkout -q master")
    run_in(dir, "git fetch --prune")
    run_in(dir, "git pull --rebase")
  else
    puts "Cloning #{dir}..."
    run_in(Dir.pwd, "git clone git@github.com:yast/#{repo}.git #{dir}")
  end

  # add your code here to run it in each git repo:
  # run_in(dir, "cmd")
end

