#!/usr/bin/env bash

set -euo pipefail

# Get the full path to this bash script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Validate arguments
if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <concatenated_log_file>" >&2
    echo "Example: $(basename "$0") seqan-combined.log" >&2
    exit 1
fi

LOG_FILE="$1"

# Validate log file exists
if [[ ! -f "${LOG_FILE}" ]]; then
    echo "Error: Log file not found: ${LOG_FILE}" >&2
    exit 1
fi

# Extract project name from log file
PROJECT="$(basename "${LOG_FILE}" | cut -f 1 -d '-')"
INTERMEDIATE_OUTPUT_DIR="intermediate_output_${PROJECT}"
OUTPUT_DIR="output_${PROJECT}"

# Determine tooltag file based on project
if [[ "${PROJECT,,}" == "seqan" ]]; then
    TOOLTAG_FILE="${SCRIPT_DIR}/../tooltags/seqan_tooltags.tsv"
elif [[ "${PROJECT,,}" == "openms" ]]; then
    TOOLTAG_FILE="${SCRIPT_DIR}/../tooltags/openms_tooltags.tsv"
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

if [[ ! -f "${OUTPUT_DIR}/monthly_conda_downloads_${TIMESTAMP}.tsv" ]]; then
    echo "  Conda..."
    "${SCRIPT_DIR}/data_processing/conda_stats.py" --project "${PROJECT}" --output "${OUTPUT_DIR}"
else
    echo "Skipping gathering conda stats."
fi

if [[ ! -f "${OUTPUT_DIR}/monthly_github_contributions_${TIMESTAMP}.tsv" ]] || [[ ! -f "${OUTPUT_DIR}/monthly_github_downloads_${TIMESTAMP}.tsv" ]]; then
    echo "  GitHub..."
    "${SCRIPT_DIR}/data_processing/github_stats.py" --project "${PROJECT}" --output "${OUTPUT_DIR}"
else
    echo "Skipping gathering GitHub stats."
fi

if [[ ! -f "${OUTPUT_DIR}/monthly_pypi_downloads_${TIMESTAMP}.tsv" ]]; then
    echo "  PyPI..."
    "${SCRIPT_DIR}/data_processing/pypi_stats.py" --project "${PROJECT}" --output "${OUTPUT_DIR}"
else
    echo "Skipping gathering PyPI stats."
fi

# Generate report
echo ""
echo "--- Creating report..."
"${SCRIPT_DIR}/create_report.R" \
    "${INTERMEDIATE_OUTPUT_DIR}/all.log" \
    "${INTERMEDIATE_OUTPUT_DIR}/geolocations.csv" \
    "${SCRIPT_DIR}/reporting/report.Rmd" \
    "${OUTPUT_DIR}" \
    "${TOOLTAG_FILE}"

echo ""
echo "============================================================================="
echo "Report generation complete!"
echo "Output directory: ${OUTPUT_DIR}"
echo "============================================================================="
