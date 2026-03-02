from typing import Dict, List

# `library_repos` is a list of github.com repository names that should be counted to library statistics.
#   All other github.com repositories are considered apps.
# `conda_packages_map` contains lists for both libraries and apps.
PACKAGE_INFO: Dict[str, Dict[str, List[str] | Dict[str, List[str]]]] = {
    "SeqAn": {
        "library_repos": ["seqan", "seqan3", "sharg-parser", "hibf"],
        "conda_packages_map": {
            "libraries": ["bioconductor-rseqan", "seqan-library", "seqan", "seqan3", "sharg"],
            "apps": [
                "anise_basil", "bioconductor-qckitfastq", "dnp-binstrings", "dnp-corrprofile",
                "dnp-diprofile", "dream-stellar", "fastremap-bio", "flexbar", "ganon", "genmap",
                "gustaf", "hilive2", "hmntrimmer", "imseq", "lambda", "mason", "micro-razers",
                "needle", "raptor", "razers3", "reads2graph", "sak", "sctools", "seqan_tcoffee",
                "slimm", "softsv", "stellar", "yara"
            ]
        },
        "pypi_packages_map": {
            "libraries": [],
            "apps" : []
        }
    },
    "OpenMS": {
        "library_repos": ["openms", "contrib", "contrib-sources", "pyopenms_viz", "pyopenms-docs", "openms-docs"],
        "conda_packages_map": {
            "libraries": ["pyopenms", "libopenms"],
            "apps": [
                "diapysef", "easypqp", "iptkl", "massdash", "ms2rescore", "openms", "pmultiqc",
                "pypgatk", "pyprophet", "quantms-rescoring", "quantms-utils"
            ]
        },
        "pypi_packages_map": {
            "libraries": ["pyopenms"],
            "apps" : []
        }
    }
}
