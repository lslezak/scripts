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
