Scripts
=======

`run.sh` is the general entry point to create a dashboard.
It takes one concatenated log file and calls the individual steps sequentially:

1. `log_processing/process_log_file.sh` turns the log into a table and looks up the geolocations.
2. `data_processing/conda_stats.py`, `github_stats.py` and `pypi_stats.py` fetch the download and contribution statistics.
3. `create_report.R` creates all plots and tables and renders `reporting/report.Rmd`.

```console
$ /path/to/scripts/run.sh seqan-combined.log
```

The name of the log file has to start with `seqan-` or `openms-` (lower case), which selects the project.

Output
------

All output is created in the current working directory:

| Path                                     | Content                                                        |
|------------------------------------------|----------------------------------------------------------------|
| `intermediate_output_<project>/`         | `all.log`, `ips.txt` and `geolocations.csv` from step 1        |
| `output_<project>/report.html`           | The dashboard                                                  |
| `output_<project>/monthly_*_<date>.tsv`  | Statistics fetched in step 2                                   |
| `output_<project>/*_<date>.{pdf,png,tsv}` | Plots and tables of the report                                |
| `output_<project>/*_<year>_<date>.{pdf,png,tsv}` | Plots and tables of one year                                  |
| `output_<project>/*_per_year_<date>.tsv` | Values per year of the plots over time                        |

`<date>` is the current date for the fetched statistics, the citations and the download and contribution tables,
and the last day of the log for all plots and tables of the log.

Keep the files in `output_<project>/` together: `report.html` embeds the plots, but its download buttons link to the individual files.
Viewing the report requires an internet connection for the table library and the map tiles.

The worldmap, the top 10 applications, the distribution of countries and cities, and the daily and weekly usage have a tab
for all data of the log and a tab for each year from 2023 (`FIRST_YEAR` in `config/config.R`) to the current year.
The tab of a year shows the report for a log that contains only the calls of this year; years without calls have no tab.
The plots over time (general usage, new unique users, unique users, total calls) show all data and have a `TSV per year`
with the same rows as the download tables (see below). Its values are the sums of the rows of the plot's TSV, so an IP address
counts in the sum of the monthly unique users once for each month in which it has a call.
The monthly plots include the last month of the log, even if the log ends before the end of the month.
The report describes how each number is computed.

Step 2 skips a source if the file with the current date is already in `output_<project>/`.
Running `run.sh` again on the same day therefore does not fetch the statistics again.

Configuration
-------------

| File                                | Content                                                                 |
|-------------------------------------|-------------------------------------------------------------------------|
| `config/config.py`                  | GitHub repositories and conda/PyPI packages of each project             |
| `config/package_data.yaml`          | Catalog for the conda statistics                                        |
| `config/requirements.txt`           | Python dependencies                                                     |
| `config/r-requirements.txt`         | R dependencies                                                          |
| `../tooltags/<project>_tooltags.tsv` | Tag of each tool, used by the "General Usage" plot                     |

`config/config.py` defines for each project:

* `library_repos`: GitHub repositories that count as library. All other repositories of the GitHub organization count as app.
* `conda_packages_map`, `pypi_packages_map`: Packages that count as library or app. Packages that are not listed are not counted.

Tools without an entry in the tool tags are tagged `extern`.

Data sources
------------

| Source                  | Fetched by                 | Access                                                                       |
|-------------------------|----------------------------|------------------------------------------------------------------------------|
| Conda downloads         | `conda_stats.py`           | Public `anaconda-package-data` S3 bucket, cached in `${TMPDIR:-/tmp}/s3fs_cache` |
| PyPI downloads          | `pypi_stats.py`            | Public ClickHouse demo server                                                |
| GitHub downloads        | `github_stats.py`          | GraphQL API, requires a token                                                |
| GitHub issues and PRs   | `github_stats.py`          | GraphQL API, requires a token                                                |
| Citations               | `plotting/citations.R`     | Google Scholar                                                               |
| Geolocations            | `log_processing/get_ip_addresses.py` | Local database `../database/IP2LOCATION-LITE-DB5.BIN`              |

The fetched statistics cover the years from 2023 (`FIRST_YEAR` in `config/config.R` and `data_processing/py/github_shared.py`) to the current year.
The download and contribution tables show each full year from 2023 on, the fourth quarter of the previous year to the third quarter of the current year, and the current year.
GitHub only reports a total per release, so a release's downloads are distributed evenly over the time until the next release of the same repository (or up to the fetch date for the latest release).

GitHub token
------------

The GitHub statistics require a personal access token in the environment:

```console
$ export GITHUB_PAT="github_pat_[...]"
```

Without the token, GitHub statistics are not collected, because the rate limit for unauthenticated queries would be hit.
`github_stats.py` then writes placeholder files with a value of `-1` for each month, so that the report can still be created.
These placeholders show up in the report as negative numbers: each GitHub column shows `-12` for each period, and `Total_Downloads` is reduced by 12.

The placeholder files count as existing statistics for the current date.
To collect GitHub statistics after a run without a token, delete `output_<project>/monthly_github_*` first.

Log processing
--------------

The input is an access log in combined log format.
Only the IP address, the date and the request are evaluated:

```text
<ip> - - [<date>:<time> <offset>] "GET /check/<who>_<os>_<cpu>_<app>_<version> HTTP/1.1" ...
```

For example, `/check/SeqAn3_Linux_64_needle_1.0.3` has `SeqAn3` as `who`, `Linux` as `os`, `64` as `cpu`, `needle` as `app` and `1.0.3` as `version`.

`process_log_file.sh` writes these columns to `all.log`: `calls`, `date`, `ip`, `app`, `version`, `cpu`, `os`, `who` and `clustered`.

* Lines containing a term from `EXCLUDED_TERMS` (e.g., `test_version_check`) and lines that do not match this format (e.g., without an `x.y.z` version) are dropped.
* Identical rows are merged: an app counts once per day for each combination of IP address, version, CPU mode, OS and `who`.
* `clustered` is set if the previous row has the same date, app, version and the same first two octets of the IP address.
  The rows are sorted as bytes (`LC_ALL=C`), so the result does not depend on the locale.
  `data_processing/load.R` removes these rows from the statistics and reports them as cluster calls in the top 10 plots.
  The cluster users of an app are the IP addresses whose calls of the app are all cluster calls.
* OS names are normalized; `unknown` counts as `Linux`.

Directory layout
----------------

| Path               | Content                                                                         |
|--------------------|---------------------------------------------------------------------------------|
| `config/`          | Configuration, see above                                                        |
| `log_processing/`  | Step 1                                                                          |
| `data_processing/` | Step 2 (`*_stats.py` with helpers in `py/`) and R code to load the data for step 3 |
| `plotting/`        | R code for the plots                                                            |
| `reporting/`       | R Markdown source of the report and its assets                                  |
