# Weekly tracking

The first GitHub scan ran successfully on 28 September 2026, with no version change. Automatic PR creation is currently disabled in the repository settings. The workflow can refresh its dedicated branch; if it cannot open the PR, it emits a warning. A PR can then be opened manually. No permission setting was widened at publication.

Every Monday at 10:23 UTC, or on demand, `upstream-versions.yml` reads stable Firefox, the Steam Linux client build, and the Debian Steam launcher version. HTTPS sources are recorded in `versions/upstream.json`.

On a change, the `automation/upstream-versions` branch and a pull request are updated. No auto-merge and no commit without a change. On conflicts: fail without a force push. Allow Actions to create PRs in the repository settings; no personal token required.

The scan does not rebuild a VM and installs nothing on a USB stick. It is neither a security audit nor a compatibility test. Steam updates itself; Firefox installed by the script updates through APT.

GitHub may delay runs or disable schedules of inactive public repositories after 60 days: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule .
