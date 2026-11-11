#!/usr/bin/env bash

set -euo pipefail

# Get the full path to this bash script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." &> /dev/null && pwd)"

usage() {
    echo "Usage: $(basename "$0") [--local] [--force] <concatenated_log_file>" >&2
    echo "Example: $(basename "$0") seqan-combined.log" >&2
    echo "" >&2
    echo "  --local  Also create <Project>_<date>.zip of the output directory in the output directory" >&2
    echo "           and link it in the report. Without it, the report links the archive of Jenkins." >&2
    echo "  --force  Fetch the statistics even if they were already fetched today." >&2
}

# Parse options
LOCAL=false
FORCE=false
while [[ $# -gt 0 && "$1" == --* ]]; do
    case "$1" in
        --local)
            LOCAL=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

if [[ "${LOCAL}" == true ]] && ! command -v zip &> /dev/null; then
    echo "Error: --local requires zip" >&2
    exit 1
fi

LOG_FILE="$(readlink -m "$1")"

# Validate log file exists
if [[ ! -f "${LOG_FILE}" ]]; then
    echo "Error: Log file not found: ${LOG_FILE}" >&2
    exit 1
fi

# Extract project name from log file
PROJECT="$(basename "${LOG_FILE}" | cut -f 1 -d '-')"
INTERMEDIATE_OUTPUT_DIR="${PWD}/intermediate_output_${PROJECT}"
OUTPUT_DIR="${PWD}/output_${PROJECT}"

# Determine tooltag file based on project
if [[ "${PROJECT,,}" == "seqan" ]]; then
    PROJECT_NAME="SeqAn"
    TOOLTAG_FILE="${REPO_DIR}/tooltags/seqan_tooltags.tsv"
elif [[ "${PROJECT,,}" == "openms" ]]; then
    PROJECT_NAME="OpenMS"
    TOOLTAG_FILE="${REPO_DIR}/tooltags/openms_tooltags.tsv"
else
    echo "Error: Could not determine project from log file name: ${LOG_FILE}" >&2
    echo "Expected filename to start with 'seqan-' or 'openms-'" >&2
    exit 1
fi

# Validate tooltag file exists
if [[ ! -f "$TOOLTAG_FILE" ]]; then
    echo "Error: Tooltag file not found: $TOOLTAG_FILE" >&2
    exit 1
fi

echo "============================================================================="
echo "                                 START"
echo "============================================================================="
echo ""
echo "Project: ${PROJECT}"
echo "Log file: ${LOG_FILE}"
echo "Intermediate output: ${INTERMEDIATE_OUTPUT_DIR}"
echo "Final output: ${OUTPUT_DIR}"
echo "Tooltag file: ${TOOLTAG_FILE}"
echo "Local: ${LOCAL}"
echo "Force: ${FORCE}"
echo ""

# Process log file
echo "--- Processing log file..."
"${SCRIPT_DIR}/log_processing/process_log_file.sh" "${LOG_FILE}"

# Validate intermediate output exists
if [[ ! -f "${INTERMEDIATE_OUTPUT_DIR}/all.log" ]] || [[ ! -f "${INTERMEDIATE_OUTPUT_DIR}/geolocations.csv" ]]; then
    echo "Error: Log processing did not produce expected output files" >&2
    exit 1
fi

# Gather statistics
echo ""
echo "--- Gathering statistics..."

mkdir -p "${OUTPUT_DIR}"
TIMESTAMP=$(date +"%F")

# Statistics that were already fetched today are reused, unless --force is given
if [[ "${FORCE}" == true || ! -f "${OUTPUT_DIR}/monthly_conda_downloads_${TIMESTAMP}.tsv" ]]; then
    echo "  Conda..."
    "${SCRIPT_DIR}/data_processing/conda_stats.py" --project "${PROJECT}" --output "${OUTPUT_DIR}"
else
    echo "Skipping gathering conda stats."
fi

if [[ "${FORCE}" == true || ! -f "${OUTPUT_DIR}/monthly_github_contributions_${TIMESTAMP}.tsv" || ! -f "${OUTPUT_DIR}/monthly_github_downloads_${TIMESTAMP}.tsv" ]]; then
    echo "  GitHub..."
    "${SCRIPT_DIR}/data_processing/github_stats.py" --project "${PROJECT}" --output "${OUTPUT_DIR}"
else
    echo "Skipping gathering GitHub stats."
fi

if [[ "${FORCE}" == true || ! -f "${OUTPUT_DIR}/monthly_pypi_downloads_${TIMESTAMP}.tsv" ]]; then
    echo "  PyPI..."
    "${SCRIPT_DIR}/data_processing/pypi_stats.py" --project "${PROJECT}" --output "${OUTPUT_DIR}"
else
    echo "Skipping gathering PyPI stats."
fi

# Generate report
echo ""
echo "--- Creating report..."
# With --local, the report links the zip that is created below
ZIP_FILE=""
if [[ "${LOCAL}" == true ]]; then
    ZIP_FILE="${PROJECT_NAME}_${TIMESTAMP}.zip"
fi
"${SCRIPT_DIR}/create_report.R" \
    "${INTERMEDIATE_OUTPUT_DIR}/all.log" \
    "${INTERMEDIATE_OUTPUT_DIR}/geolocations.csv" \
    "${SCRIPT_DIR}/reporting/report.Rmd" \
    "${OUTPUT_DIR}" \
    "${TOOLTAG_FILE}" \
    ${ZIP_FILE:+"${ZIP_FILE}"}

if [[ -f "${OUTPUT_DIR}/report.html" && ! -f "${OUTPUT_DIR}/index.html" ]]; then
    ln -s "${OUTPUT_DIR}/report.html" "${OUTPUT_DIR}/index.html"
fi

# The zip contains the output directory, without zips of earlier runs.
# It is created outside of the output directory, so that it cannot contain itself.
if [[ "${LOCAL}" == true ]]; then
    echo ""
    echo "--- Creating ${OUTPUT_DIR}/${ZIP_FILE}..."
    ZIP_TMP_DIR="$(mktemp -d)"
    (cd "$(dirname "${OUTPUT_DIR}")" && \
        zip -r -q "${ZIP_TMP_DIR}/${ZIP_FILE}" "$(basename "${OUTPUT_DIR}")" -x "$(basename "${OUTPUT_DIR}")/*.zip")
    mv -f "${ZIP_TMP_DIR}/${ZIP_FILE}" "${OUTPUT_DIR}/${ZIP_FILE}"
    rmdir "${ZIP_TMP_DIR}"
fi

echo ""
echo "============================================================================="
echo "Report generation complete!"
echo "Output directory: ${OUTPUT_DIR}"
echo "============================================================================="
