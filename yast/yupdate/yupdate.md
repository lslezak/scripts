# The yupdate Script

This is a documentation for the `yupdate` helper script,
which is included in the YaST installer in SLE15-SP2/openSUSE
Leap 15.2, openSUSE Tumbleweed 2019xxxx or newer distributions.

## The Introduction

**Problem**: you are developing a change for the installer and need to test it
frequently.  For extra fun, the change is spread across multiple repositories.

The YaST installation system is quite different to an
usual Linux installed system. The root filesystem
is stored in RAM disk and most files are read-only.
That makes it quite difficult to modify the YaST installer
if you need to debug a problem or test a fix.

There are some possibilities for updating the YaST installer
(see [Alternative](#Alternative))
but they are usually not trivial and need special preparations.
For this reason we created a special `yupdate` script which makes
the process easier.

## Installation

yupdate should run in the inst-sys. Since SLE15-SP2/openSUSE
Leap 15.2, openSUSE Tumbleweed 2019xxxx, it ~~is~~ will be preinstalled.

For older releases, run:

```
inst-sys# wget https://raw.githubusercontent.com/lslezak/scripts/yupdate_refactoring/yast/yupdate/yupdate
FIXME: rename to master before merging                           ^ ~~~~~~~~~~~~~~~~~
inst-sys# chmod +x ./yupdate
```

## Basic Use Cases

This script is intended to help in the following scenarios.

### Make inst-sys Writable

To make a directory in the inst-sys writable run command

`yupdate overlay create <dir>` this will create a writable overlay
above the specified directory. If you do not specify any directory
it will create writable overlays for the default YaST directories.

Then you can easily edit the files using the included `vim` editor
or by other tools like `sed`.

### Patch YaST from GitHub Sources

### Patch YaST from Locally Modified Sources

### Patch YaST from a Generic Tarball Archive


## Other Commands


## Alternative

1. For all repos, run `rake osc:build`
2. Collect the resulting RPMs
3. Run a server, eg. with `ruby -run -e httpd -- -p 8888 .`
4. Type a loooong boot line to pass them all as DUD=http...rpm
