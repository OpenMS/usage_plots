Example
=======

A small example of the input and output of [`scripts/run.sh`](../scripts/README.md).

| Path                | Content                                                  |
|---------------------|----------------------------------------------------------|
| `seqan-example.log` | 10,000 lines of the SeqAn version check log              |
| `output_seqan/`     | Output for this log, `output_seqan/report.html` is the dashboard |

To view the dashboard, check out the repository and open `output_seqan/report.html` in a browser.

The log is randomized
---------------------

The log is based on real data, but its IP addresses and timestamps were replaced by random values.
Locations, dates and trends in the report therefore do **not** reflect real usage:

* Each IP address was replaced by a random, public address.
* Each day was replaced by a random day of the same time span, and each call got a random time of day.
* The timestamps embedded in the `test_version_check` requests match the new time of their line.

Calls from the same day are still on the same day, and addresses from the same `/16` network are still in the same `/16` network.
This keeps the merging of calls and the detection of clusters meaningful, see [Log processing](../scripts/README.md#log-processing).

The remainder of each line is unchanged, and the applications and versions in the report come from real calls.

The conda, PyPI, GitHub and Google Scholar statistics in the report do not depend on the log.
They are real values from the date in the file names.

Recreating the output
---------------------

From the root of the repository:

```console
$ mkdir -p local/report && cd local/report
$ ../../scripts/run.sh ../../example/seqan-example.log
```

Creating the output in `example/` itself would add files for the current date next to the existing ones.
