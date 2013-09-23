#!/usr/bin/env ruby

result = `curl -s 'https://api.github.com/orgs/yast/repos?page=1&per_page=100' | grep "\\"name\\":" | sed -e "s/^.*name\\": \\"\\(.*\\)\\",.*$/\\1/"`
result << `curl -s 'https://api.github.com/orgs/yast/repos?page=2&per_page=100' | grep "\\"name\\":" | sed -e "s/^.*name\\": \\"\\(.*\\)\\",.*$/\\1/"`
repos = result.split "\n"

puts "Found #{repos.size} Yast repositories"

IGNORE = [ "yast-bluetooth", "yast-boot-server", "yast-cd-creator",
"yast-certify", "yast-cim", "yast-databackup", "yast-dbus-client",
"yast-debugger", "yast-dirinstall", "yast-fax-server",
"yast-fingerprint-reader", "yast-mouse", "yast-ntsutils",
"yast-oem-installation", "yast-online-update-test", "yast-openschool",
"yast-openteam", "yast-openwsman-yast", "yast-packagemanager",
"yast-packagemanager-test", "yast-phone-services", "yast-power-management",
"yast-profile-manager", "yast-registration", "yast-repair", "yast-squidguard",
"yast-sudo", "yast-support", "yast-system-profile", "yast-system-update",
"yast-uml", "yast-y2pmsh", "yast-you-server", "yast-yxmlconv", "yast-meta" ]

puts "Skipping #{IGNORE.size} obsoleted repositories"

repos = repos - IGNORE

repos.each do |repo|
  dir = repo.gsub(/^yast-/, "")

  if File.exist? dir
    puts "Updating #{repo}..."

    Dir.chdir dir do
      `git checkout -q master`
      `git pull --rebase`
    end
  else
    puts "Cloning #{repo}..."
    `git clone git@github.com:yast/#{repo}.git #{dir}`
  end

  puts
end


