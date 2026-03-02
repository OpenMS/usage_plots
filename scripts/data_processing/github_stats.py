#!/usr/bin/env python3

import sys
import argparse
from pathlib import Path
from datetime import datetime

# Add project root to Python path
project_root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(project_root))

from scripts.data_processing.py.github_downloads import fetch_github_downloads
from scripts.data_processing.py.github_contributions import fetch_github_contributions
from scripts.data_processing.py.github_shared import BERLIN_TZ

# Valid project names with canonical spelling
VALID_PROJECTS = {
    "seqan": "SeqAn",
    "openms": "OpenMS"
}

def normalize_project(project: str) -> str:
    """Normalize project name to canonical spelling."""
    project_lower = project.lower()
    if project_lower not in VALID_PROJECTS:
        raise argparse.ArgumentTypeError(
            f"Invalid project '{project}'. Must be one of: {', '.join(VALID_PROJECTS.values())}"
        )
    return VALID_PROJECTS[project_lower]

def main():
    """Main entry point for GitHub statistics collection."""
    parser = argparse.ArgumentParser(
        description="Fetch GitHub statistics (contributions and downloads) for a project."
    )
    parser.add_argument(
        "--project",
        type=normalize_project,
        required=True,
        metavar="PROJECT",
        help=f"Project name (one of: {', '.join(VALID_PROJECTS.values())})"
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        metavar="DIR",
        help="Output directory for generated files"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output"
    )

    args = parser.parse_args()

    # Create output directory if it doesn't exist
    args.output.mkdir(parents=True, exist_ok=True)

    # Generate timestamp in Berlin timezone
    timestamp = datetime.now(tz=BERLIN_TZ).strftime("%Y-%m-%d")

    # Create output file paths with timestamp
    contributions_file = args.output / f"monthly_github_contributions_{timestamp}.tsv"
    downloads_file = args.output / f"monthly_github_downloads_{timestamp}.tsv"

    if args.verbose:
        print(f"Project: {args.project}")
        print(f"Output directory: {args.output}")
        print(f"Timestamp: {timestamp}\n")

    if args.verbose:
        print("Fetching GitHub contributions...")
    fetch_github_contributions(args.project, str(contributions_file), verbose=args.verbose)
    if args.verbose:
        print(f"Saved to: {contributions_file}\n")

    if args.verbose:
        print("Fetching GitHub downloads...")
    fetch_github_downloads(args.project, str(downloads_file), verbose=args.verbose)
    if args.verbose:
        print(f"Saved to: {downloads_file}\n")

    if args.verbose:
        print("Done!")

if __name__ == "__main__":
    main()
