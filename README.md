# Base Runtime Tools

Various helper scripts and hacks the Base Runtime team uses.
The contents of this repository are meant to be deployed in
the `build` user's home directory.

Some brief info on the currect directory structure:

* `compose/`
    * contains a compose-like repo, with only the right builds
      in it; includes the `modules` thingie
    * suitable for sharing publicly
    * created by `compose.pl`
    * mostly obsoleted by the staging composes

* `logs/`
    * contains logs for component build failures for each
      local module build

* `mbs/`
    * the local MBS root, with configuration and possibly custom
      patches applied to make it work

* `misc/`
    * various helper scripts go here
    * `savelogs.sh` saves the gives module component build failure
      logs to `logs/`
    * `newimage.pl` creates, tests and optionally pushes a new
      docker base image to Docker Hub; it also sends a notification
      e-mail

* `mock/`
    * source for the `/var/lib/mock` bind mount
    * this is for convenience; our `/home` is much larger and we
      don't have to move data between filesystems all the time

* `modules/`
    * local module checkouts, not necessarily up-to-date
    * should be updated before running a compose

* `repos/`
    * local repos created from koji tags
    * `f26-modularity` → `module-bootstrap-master-1` lives here
    * also useful for creating composes
    * `syncrepos.sh` downloads the given koji tag and creates
      a repo with the RPMs in it; x86_64 only

* `results/`
    * MBS build results go here

* `rpmbuild/`
    * rpmbuild stuff goes here; used by MBS

* `tests/`
    * our tests repos go here

* `compose.pl`
    * finds RPMs in passed directories and creases a compose-like
      structure using the modulemd file found in `modules/base-runtime`

* `mbs.sh`
    * creates or connects to a tmux session with the MBS running

* `status.pl`
    * a helper script for checking module build status
