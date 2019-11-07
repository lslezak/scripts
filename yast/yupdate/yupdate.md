# The yupdate Script

This is a documentation for the `yupdate` helper script,
which is included in the YaST installer in SLE15-SP2/openSUSE
Leap 15.2, openSUSE Tumbleweed 2019xxxx or newer distributions.

## The Introduction

The YaST installation system is quite different to an
usual Linux installed system. The root filesystem
is stored in RAM disk and most files are read-only.
That makes it quite difficult to modify the YaST installer
if you need to debug a problem or test a fix.

There are some possibilities for updating the YaST installer
but they are usually not trivial and need special preparations.
For this reason we created a special `yupdate` script which makes
the process easier.


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


