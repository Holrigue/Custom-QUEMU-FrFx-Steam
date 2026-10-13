# Preinstallation: release status

A neutral Linux image could technically ship with Firefox and a prepared Steam launcher. v0.1.0 provides a **preparation kit**, not such an image. No personal disk is exported: even after accounts are deleted, data can remain in its blocks.

The available path installs Linux, then runs `linux/prepare-persistent.sh`. Apps and dependencies are downloaded by APT; Steam downloads its client at first launch. Apps then persist. Internet is required.

A future image would have to be built fresh, with no Steam/Firefox account, with the Linux account created by the recipient, machine-id handling, a package inventory, checksums, and tests. Check the redistribution terms of every component before publishing.

Mozilla allows some unmodified redistribution under conditions: https://www.mozilla.org/en-US/foundation/trademarks/distribution-policy/ . A Steam download alone is not a general redistribution grant; the launcher and the client are distinct: https://repo.steampowered.com/steam/ . This release downloads from the providers and does not re-host their binaries.

GitHub Releases requires files under 2 GiB each: https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases . A VM would need split archives and a verified rebuild; do not add the large disks to Git.
