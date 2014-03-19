#! /usr/bin/ruby

# this scripts copies packages from YaST:Head to YaST:Head:installer
# to have kind of snapshot (to avoid too often rebuilds caused by
# automatic Jenkins submitions from Git

# list of packages to copy
# if a package is modified in 'next_opensuse' branch and submitted
# manually then remove it from the list so the changes are not lost!
PACKAGES = [ "autoyast2", "libstorage", "libyui", "libyui-bindings",
  "libyui-ncurses", "libyui-ncurses-pkg", "libyui-qt",
  "libyui-qt-pkg", "perl-Bootloader", "snapper", "yast2", "yast2-add-on",
  "yast2-bootloader", "yast2-branding-openSUSE", "yast2-core",
  "yast2-ca-management", "yast2-control-center", "yast2-control-center-gnome",
  "yast2-country", "yast2-dbus-server", "yast2-devtools",
  "yast2-dhcp-server", "yast2-dns-server",
  "yast2-fcoe-client", "yast2-firewall", "yast2-firstboot", "yast2-ftp-server",
  "yast2-hardware-detection", "yast2-http-server", "yast2-inetd",
  "yast2-instserver", "yast2-iscsi-client", "yast2-installation", "yast2-installation-control",
  "yast2-kdump", "yast2-kerberos-client", "yast2-kerberos-server", "yast2-ldap",
  "yast2-ldap-client", "yast2-ldap-server", "yast2-live-installer", "yast2-lxc",
  "yast2-mail", "yast2-metapackage-handler", "yast2-multipath", "yast2-network",
  "yast2-nfs-client", "yast2-nfs-server", "yast2-nis-client", "yast2-nis-server",
  "yast2-ntp-client", "yast2-online-update", "yast2-packager", "yast2-pam",
  "yast2-perl-bindings", "yast2-pkg-bindings", "yast2-printer",
  "yast2-product-creator", "yast2-proxy", "yast2-ruby-bindings",
  "yast2-samba-client", "yast2-samba-server", "yast2-scanner",
  "yast2-security", "yast2-services-manager", "yast2-schema", "yast2-slide-show",
  "yast2-slp", "yast2-slp-server", "yast2-snapper", "yast2-sound", "yast2-squid",
  "yast2-storage", "yast2-sysconfig", "yast2-testsuite", "yast2-tftp-server",
  "yast2-transfer", "yast2-tune", "yast2-update", "yast2-users", "yast2-vm", "yast2-xml",
  "yast2-x11", "yast2-ycp-ui-bindings", "rubygem-yast-rake", "rubygem-packaging_rake_tasks"
   ]

# OBS does not trigger rebuild if the package is not changed
# so we can blindly copy all packages without any check for changes
PACKAGES.each_with_index do |pkg, i|
  puts "[#{i+1}/#{PACKAGES.size} #{(i+1)*100/PACKAGES.size}%]  Copying package #{pkg} ..."
  `osc copypac YaST:Head #{pkg} YaST:Head:installer`
end

puts "Finished"

