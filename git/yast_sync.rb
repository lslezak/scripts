#!/usr/bin/env ruby

require "json"
require "shellwords"

# which branch to check out
# TODO: add branch fallbacks, e.g. if Code-11-SP4 does not exist try Code-11-SP3
TARGET_BRANCH = "master"

# retry counts after failure
MAX_ATTEMPS = 5
RETRY_TIMEOUT = 10

# Helper class for paralellizing the work
class Threading
  # number of threads to use
  @@threads_count = nil

  class << self

    # Run a task in parallel for processing list of items.
    #
    # The passed block is used for processing each list item.
    #
    # The number of created threads for processing is autodetected
    # (equals to the number of CPUs in system) or can be set explicitly
    # by setting Threading.threads_count value.
    #
    # Example:
    #   Threading.in_parallel [ 1, 3, 4, 5] do | arg |
    #     sleep arg
    #     puts "Slept #{arg} seconds"
    #   end
    #
    def in_parallel args
      tasks = split_array args, threads_count

      # the currently running threads
      running_threads = []

      tasks.each do |task|
        running_threads << Thread.new(task) do |task_args|
          task_args.each { |a| yield a }
        end
      end

      # wait for all threads to finish
      running_threads.each { |t| t.join }
    end

    def threads_count= num
      @@threads_count = num
    end

    def threads_count
      @@threads_count ||= cpu_count
    end

    private

    # autodetect the number of CPUs in the system
    def cpu_count
      File.read("/proc/cpuinfo").split("\n").count { |s| s.start_with?("processor\t:") }
    end

    # split an array to (possibly) equal parts
    def split_array(arr, parts)
      ret = [];
      arr.each_slice((arr.size / parts.to_f).ceil) { |part| ret << part } unless arr.empty?
      ret
    end
  end
end

def read_yast_repos
  JSON.parse(`curl --netrc -s 'https://api.github.com/orgs/yast/repos?page=1&per_page=100'`).map{|r| r["name"]}.concat(
    JSON.parse(`curl --netrc -s 'https://api.github.com/orgs/yast/repos?page=2&per_page=100'`).map{|r| r["name"]}
  )
end

def run_in(dir, cmd)
  attempt = 1

  loop do
    `(cd #{Shellwords.escape(dir)} && #{cmd})`

    break if $?.success?

    if attempt > MAX_ATTEMPS
      $stderr.puts "Command #{cmd.inspect} still fails, giving up"
      exit(1)
    end

    attempt += 1
    $stderr.puts "Error: #{$?.exitstatus}, retrying in #{RETRY_TIMEOUT} seconds..."
    sleep(RETRY_TIMEOUT)
  end
end

repos = read_yast_repos
puts "Found #{repos.size} YaST repositories"

IGNORED_REPOS = [
  "skelcd-control-SLES-for-VMware",
  "rubygem-scc_api",
  "yast-autofs",
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
  "yast-iscsi-server",
  "yast-kerberos-client",
  "yast-kerberos-server",
  "yast-liby2util",
  "yast-live-installer",
  "yast-ldap-client",
  "yast-ldap-server",
  "yast-lxc",
  "yast-meta",
  "yast-mouse",
  "yast-mail-server",
  "yast-mysql-server",
  "yast-ntsutils",
  "yast-oem-installation",
  "yast-online-update-test",
  "yast-openschool",
  "yast-openteam",
  "yast-openvas-security-scanner",
  "yast-openwsman-yast",
  "yast-packagemanager",
  "yast-packagemanager-test",
  "yast-phone-services",
  "yast-power-management",
  "yast-profile-manager",
  "yast-repair",
  "yast-restore",
  "yast-runlevel",
  "yast-squidguard",
  "yast-sshd",
  "yast-sudo",
  "yast-support",
  "yast-system-profile",
  "yast-system-update",
  "yast-slepos-image-builder",
  "yast-slepos-system-manager",
  "yast-slide-show",
  "yast-tv",
  "yast-ui-qt-tests",
  "yast-update-alternatives",
  "yast-uml",
  "yast-wagon",
  "yast-you-server",
  "yast-yxmlconv",
  "yast-y2pmsh",
  "yast-y2r-tools",
  "ycp-killer",
  "y2r",
]

repos = repos - IGNORED_REPOS
puts "Ignoring #{IGNORED_REPOS.size} obsoleted repositories, using #{repos.size} repositories"

repos.sort!

# the maximum number of parallel threads can be limited via ENV
max_threads = ENV["THREADS_MAX"].to_i
Threading.threads_count = max_threads if max_threads > 0
puts "Using #{Threading.threads_count} parallel threads..."

Threading.in_parallel(repos) do |repo|
  # remove the "yast-" prefix, make searching in the directory easier
  dir = repo.sub(/^yast-/, "")

  # clone or update the existing checkout
  if File.exist?(dir)
    puts "Updating #{dir}..."

    # make sure any unsubmitted work is not lost by accident, stash the changes
    run_in(dir, "git stash save")

    run_in(dir, "git reset --hard")
    run_in(dir, "git checkout -q #{TARGET_BRANCH}")
    # clenup - remove the branches which were deleted on the server
    run_in(dir, "git fetch --prune")
    run_in(dir, "git pull --rebase")
    # do extra git cleanup - might save a lot of space, on the other hand it might
    # definitely delete some "lost" work, use with caution!
    # run_in(dir, "git gc")
  else
    puts "Cloning #{dir}..."
    run_in(Dir.pwd, "git clone -b #{TARGET_BRANCH} git@github.com:yast/#{repo}.git #{dir}")
  end

  # add your code here to run it in each git repo:
  # run_in(dir, "cmd")
end

obsolete = Dir["*"] & IGNORED_REPOS.map{|r| r.sub(/^yast-/, "")}
if !obsolete.empty?
  puts "Found obsolete directories: #{obsolete}"
end
