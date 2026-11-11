Usage Statistics of OpenMS and SeqAn
====================================

This repo contains scripts, data and other files that create the usage statistics dashboards of OpenMS and SeqAn.
A dashboard is a single HTML report that combines:

* calls to the version check server: calls and users per month, top applications, operating systems, world map
* downloads from GitHub releases, conda and PyPI
* GitHub issues and pull requests
* Google Scholar citations

A cron job which triggers the analysis of log files is set up on [Jenkins](https://abibuilder.cs.uni-tuebingen.de/jenkins/job/usage_statistics/job/usageStatistics/).

:exclamation:**Important**:exclamation:: The top level `seqan_versions.txt` and `openms_versions.txt` must not be moved to a different location because it is needed to ensure a correct server response to a user call. The Tübingen REST server pulls both file once per night, so if a version changes, they can be directly updated in this repository.

Creating a dashboard
--------------------

1. Get the dependencies:
   They are available as a Docker image, see [docker/README.md](docker/README.md).
   ```console
   $ docker pull ghcr.io/seqan/usage-plots:latest
   ```
   Without Docker, you need `gawk`, `perl`, `pandoc`, the Python packages from `scripts/config/requirements.txt` and the R packages from `scripts/config/r-requirements.txt`.

2. Get log files:
   The original server calls are stored in Tübingen.
   Ask someone in Tübingen to send you a zipped file or get access to the server yourself.
   Concatenate the logs into one file.
   Its name has to start with `seqan-` or `openms-`, which selects the project.
   To try things out, use the randomized log in [example/](example/).

3. Set a GitHub token:
   Without it, GitHub statistics are not collected, see [scripts/README.md](scripts/README.md#github-token).
   ```console
   $ export GITHUB_PAT="github_pat_[...]"
   ```

4. Run `scripts/run.sh`:
   It calls the individual steps sequentially and creates all output in the current working directory.
   ```console
   $ mkdir -p local/report && cd local/report # `local` is ignored by git
   $ ../../scripts/run.sh ../../example/seqan-example.log
   ```
   `output_seqan/index.html` opens the dashboard, `output_seqan/report_<date>.html`.

[example/output_seqan/](example/output_seqan/) contains the result of these commands.

To change which GitHub repositories and conda/PyPI packages are counted as libraries or apps, edit `scripts/config/config.py`.
[scripts/README.md](scripts/README.md) describes the configuration, the individual steps and the output.

Repository layout
-----------------

| Path                                        | Content                                                                 |
|---------------------------------------------|-------------------------------------------------------------------------|
| `scripts/`                                  | Scripts that create the dashboard, see [README](scripts/README.md)      |
| `docker/`                                   | Docker image with all dependencies, see [README](docker/README.md)      |
| `example/`                                  | Randomized example log and its dashboard, see [README](example/README.md) |
| `database/`                                 | IP geolocation database, obtained from https://lite.ip2location.com     |
| `tooltags/`                                 | Tags for the tools of each project                                      |
| `seqan_versions.txt`, `openms_versions.txt` | Current versions, pulled by the REST server (do not move)               |
