#!/usr/bin/env python3

import sys
import argparse
from pathlib import Path
from datetime import datetime
from typing import List
import pandas as pd
import intake

# Add project root to Python path
project_root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(project_root))

from scripts.config.config import PACKAGE_INFO
from scripts.data_processing.py.github_shared import BERLIN_TZ, ALL_MONTHS

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

def fetch_conda_downloads(package_names: List[str], verbose: bool = False) -> pd.DataFrame:
    """Fetch Conda download statistics for a list of packages.

    Args:
        package_names: List of Conda package names to fetch
        verbose: Enable verbose output

    Returns:
        DataFrame with columns: Month, Downloads (aggregated across all packages)
    """
    if not package_names:
        if verbose:
            print("No packages to fetch, returning placeholder data")
        return get_placeholder_data()

    if verbose:
        print(f"Fetching Conda downloads for {len(package_names)} packages...")

    # Open the catalog
    catalog_path = project_root / "scripts" / "config" / "package_data.yaml"
    cat = intake.open_catalog(str(catalog_path))

    # Get current year and previous year
    current_year = datetime.now(tz=BERLIN_TZ).year
    previous_year = current_year - 1

    # Fetch data for both years
    dfs = []
    for year in [previous_year, current_year]:
        if verbose:
            print(f"Fetching data for year {year}...")

        # Load the data for this year
        df = cat.anaconda_package_data_by_year_month_res(year=year).to_dask()

        # Filter for the packages we want
        df = df[df['pkg_name'].isin(package_names)]

        # Group by month and sum the counts
        df = df.groupby('time')['counts'].sum().reset_index()

        # Compute the result (convert from Dask to pandas)
        df = df.compute()

        dfs.append(df)

    # Combine both years
    df = pd.concat(dfs, ignore_index=True)

    if verbose:
        print(f"Fetched {len(df)} rows from catalog")

    # Rename columns for consistency
    df = df.rename(columns={'time': 'Month', 'counts': 'Downloads'})

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
    """Main entry point for Conda statistics collection."""
    parser = argparse.ArgumentParser(
        description="Fetch Conda download statistics for a project."
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
    output_file = args.output / f"monthly_conda_downloads_{timestamp}.tsv"

    if args.verbose:
        print(f"Project: {args.project}")
        print(f"Output directory: {args.output}")
        print(f"Timestamp: {timestamp}\n")

    # Check if project has Conda packages configured
    if "conda_packages_map" not in PACKAGE_INFO[args.project]:
        if args.verbose:
            print(f"Warning: No Conda packages configured for {args.project}")
        data = get_placeholder_data()
        data['Type'] = 'Unknown'
    else:
        conda_config = PACKAGE_INFO[args.project]["conda_packages_map"]

        # Fetch application downloads
        app_packages = conda_config.get("apps", [])
        if app_packages:
            if args.verbose:
                print(f"Fetching {len(app_packages)} application packages...")
            app_data = fetch_conda_downloads(app_packages, verbose=args.verbose)
            app_data['Type'] = 'Application'
        else:
            app_data = get_placeholder_data()
            app_data['Type'] = 'Application'

        # Fetch library downloads
        lib_packages = conda_config.get("libraries", [])
        if lib_packages:
            if args.verbose:
                print(f"Fetching {len(lib_packages)} library packages...")
            lib_data = fetch_conda_downloads(lib_packages, verbose=args.verbose)
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

if __name__ == "__main__":
    main()
