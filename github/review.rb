#!/usr/bin/env ruby

# install missing gems
if !File.exist?(".vendor")
  puts "Installing the needed Rubygems to .vendor/bundle ..."
  system "bundle install --path .vendor/bundle"
end

require "rubygems"
require "bundler/setup"

require "octokit"

# Generate at https://github.com/settings/tokens
client = Octokit::Client.new(access_token: ENV["GH_TOKEN"])
client.auto_paginate = true

# Obtained from schubi
pulls = [
  "yast/yast-packager/pull/380",
  "yast/yast-add-on/pull/65",
  "yast/yast-installation/pull/749",
  "yast/yast-bootloader/pull/539",
  "yast/yast-configuration-management/pull/15",
  "yast/yast-rdp/pull/14",
  "yast/yast-pam/pull/10",
  "yast/yast-perl-bindings/pull/20",
  "yast/yast-pkg-bindings/pull/108",
  "yast/yast-snapper/pull/61",
  "yast/yast-dns-server/pull/77",
  "yast/yast-iplb/pull/14",
  "yast/yast-s390/pull/60",
  "yast/yast-support/pull/31",
  "yast/yast-devtools/pull/133",
  "yast/yast-services-manager/pull/180",
  "yast/yast-testsuite/pull/21",
  "yast/yast-iscsi-client/pull/72",
  "yast/yast-tftp-server/pull/23",
  "yast/yast-registration/pull/404",
  "yast/yast-multipath/pull/25",
  "yast/yast-online-update-configuration/pull/16",
  "yast/yast-ldap/pull/31",
  "yast/yast-kdump/pull/100",
  "yast/yast-iscsi-lio-server/pull/82",
  "yast/yast-pos-installation/pull/7",
  "yast/yast-auth-server/pull/46",
  "yast/yast-squid/pull/21",
  "yast/yast-proxy/pull/21",
  "yast/yast-hardware-detection/pull/18",
  "yast/yast-auth-client/pull/66",
  "yast/yast-cluster/pull/42",
  "yast/yast-nfs-client/pull/73",
  "yast/yast-theme/pull/99",
  "yast/yast-scanner/pull/19",
  "yast/yast-nfs-server/pull/28",
  "yast/yast-dhcp-server/pull/39",
  "yast/yast-sudo/pull/7",
  "yast/yast-http-server/pull/35",
  "yast/yast-python-bindings/pull/17",
  "yast/yast-security/pull/46",
  "yast/yast-metapackage-handler/pull/13",
  "yast/yast-installation-control/pull/70",
  "yast/yast-slp/pull/25",
  "yast/yast-samba-client/pull/65",
  "yast/yast-drbd/pull/19",
  "yast/yast-ycp-ui-bindings/pull/37",
  "yast/yast-update/pull/113",
  "yast/yast-rear/pull/13",
  "yast/yast-autoinstallation/pull/466",
  "yast/yast-ftp-server/pull/52",
  "yast/yast-isns/pull/20",
  "yast/yast-xml/pull/11",
  "yast/yast-schema/pull/39",
  "yast/yast-core/pull/138",
  "yast/yast-geo-cluster/pull/21",
  "yast/yast-online-update/pull/24",
  "yast/yast-slp-server/pull/27",
  "yast/yast-samba-server/pull/63",
  "yast/yast-mail/pull/38",
  "yast/yast-apparmor/pull/30",
  "yast/yast-caasp/pull/31"
]

pulls.each do |p|
  repo, pr = p.split("/pull/")

  options = { event: "APPROVE", body: "LGTM" }
  puts "Approving #{repo} ##{pr}"
  client.create_pull_request_review(repo, pr, options)

  puts "Merging #{repo} ##{pr}"
  client.merge_pull_request(repo, pr)

  puts "Deleting master-license branch in #{repo}"
  client.delete_branch(repo, "master-license")
end
