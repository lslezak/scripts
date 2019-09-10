# yupdate

**Problem**: you are developing a change for the installer and need to test it frequently.
The change is spread across multiple repositories.

**Old Solution**:
1. For all repos, run `rake osc:build`
2. Collect the resulting RPMs
3. Run a server, eg. with `ruby -run -e httpd -- -p 8888 .`
4. Type a loooong boot line to pass them all as DUD=http...rpm

**New Solution**

1. Run `./yupdate --dwim` (?)

```
Usage: yupdate [options]
    -c, --create-overlays            Create the default YaST overlays
    -g, --ghrepo GITHUB_REPO         GitHub repository name
    -b, --branch BRANCH_OR_TAG       Use the specified branch or tag (default: master)
    -d, --diff                       Display diff of the modified files
        --overlay DIR                Create overlayfs mount for the specified directory
    -l, --list-overlays              List overlay mounts
    -f, --list-files                 List overlay files
    -o, --other-servers URL          List other running remote servers
    -r, --reset                      Remove all overlays, reset the system to the original state
    -s, --sync URL                   Sync from server
    -u, --self-update                Selfupdate from GitHub
    -v, --verbose                    Verbose output
        --version                    Print the script version
```
