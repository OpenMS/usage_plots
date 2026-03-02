#!/usr/bin/env python3

import sys
import argparse
from pathlib import Path
from datetime import datetime
from typing import List
import pandas as pd

# Add project root to Python path
project_root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(project_root))

from clickhouse_connect import get_client
from clickhouse_connect.driver.client import Client

from scripts.config.config import PACKAGE_INFO
from scripts.data_processing.py.github_shared import BERLIN_TZ, ALL_MONTHS

PYPI_DOWNLOADS_QUERY = """
SELECT
    month,
    SUM(count) as total_downloads
FROM pypi.pypi_downloads_per_month
WHERE project IN {package_names:Array(String)}
GROUP BY month
ORDER BY month
"""

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

def create_client() -> Client:
    """Create ClickHouse client connection."""
    return get_client(
        host='sql-clickhouse.clickhouse.com',
        user='demo',
        password='',
        port=443
    )

def get_placeholder_data() -> pd.DataFrame:
    """Return placeholder data when no packages are configured."""
    monthly_stats = []
    for month in ALL_MONTHS:
        month_data = {
            'Month': str(month),
            'Downloads': 0
        }
        monthly_stats.append(month_data)
    return pd.DataFrame(monthly_stats)

def fetch_pypi_downloads(package_names: List[str], verbose: bool = False) -> pd.DataFrame:
    """Fetch PyPI download statistics for a list of packages.

    Args:
        package_names: List of PyPI package names to fetch
        verbose: Enable verbose output

    Returns:
        DataFrame with columns: Month, Downloads (aggregated across all packages)
    """
    if not package_names:
        if verbose:
            print("No packages to fetch, returning placeholder data")
        return get_placeholder_data()

    if verbose:
        print(f"Fetching PyPI downloads for {len(package_names)} packages...")

    with create_client() as client:
        result = client.query(
            query=PYPI_DOWNLOADS_QUERY,
            parameters={'package_names': package_names}
        )

        # Convert to DataFrame
        df = pd.DataFrame(
            result.result_rows,
            columns=['Month', 'Downloads']
        )

        if verbose:
            print(f"Fetched {len(df)} rows from database")

        # Convert Month from "2024-04-01" to "2024-04" format
        df['Month'] = pd.to_datetime(df['Month']).dt.to_period('M').astype(str)

        # Create a complete DataFrame with all months from ALL_MONTHS
        all_months_df = pd.DataFrame({
            'Month': [str(month) for month in ALL_MONTHS]
        })

        # Merge with fetched data, filling missing months with 0
        df = all_months_df.merge(df, on='Month', how='left')
        df['Downloads'] = df['Downloads'].fillna(0).astype(int)

        if verbose:
            print(f"Filled to {len(df)} rows with complete month range")

        return df

def main():
    """Main entry point for PyPI statistics collection."""
    parser = argparse.ArgumentParser(
        description="Fetch PyPI download statistics for a project."
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

    # Create output file path with timestamp
    output_file = args.output / f"monthly_pypi_downloads_{timestamp}.tsv"

    if args.verbose:
        print(f"Project: {args.project}")
        print(f"Output directory: {args.output}")
        print(f"Timestamp: {timestamp}\n")

    # Check if project has PyPI packages configured
    if "pypi_packages_map" not in PACKAGE_INFO[args.project]:
        if args.verbose:
            print(f"Warning: No PyPI packages configured for {args.project}")
        data = get_placeholder_data()
        data['Type'] = 'Unknown'
    else:
        pypi_config = PACKAGE_INFO[args.project]["pypi_packages_map"]

        # Fetch application downloads
        app_packages = pypi_config.get("apps", [])
        if app_packages:
            if args.verbose:
                print(f"Fetching {len(app_packages)} application packages...")
            app_data = fetch_pypi_downloads(app_packages, verbose=args.verbose)
            app_data['Type'] = 'Application'
        else:
            app_data = get_placeholder_data()
            app_data['Type'] = 'Application'

        # Fetch library downloads
        lib_packages = pypi_config.get("libraries", [])
        if lib_packages:
            if args.verbose:
                print(f"Fetching {len(lib_packages)} library packages...")
            lib_data = fetch_pypi_downloads(lib_packages, verbose=args.verbose)
            lib_data['Type'] = 'Library'
        else:
            lib_data = get_placeholder_data()
            lib_data['Type'] = 'Library'

        # Combine data
        data = pd.concat([app_data, lib_data], ignore_index=True)

    # Save to file
    data.to_csv(output_file, sep='\t', index=False)

    if args.verbose:
        print(f"Saved to: {output_file}\n")
        print("Done!")

if __name__ == '__main__':
    main()
