#!/usr/bin/env python3

from gql import gql, Client
from datetime import datetime, timedelta, timezone
from dateutil.relativedelta import relativedelta
import pandas as pd
from typing import List
import re

from scripts.data_processing.py.github_shared import get_gql_client, get_org_repos, ALL_MONTHS, BERLIN_TZ
from scripts.config.config import PACKAGE_INFO

def get_placeholder_data(no_auth: bool) -> pd.DataFrame:
    monthly_stats = []
    for month in ALL_MONTHS:
        month_data = {
            'Month': str(month),
            'Downloads': -1 if no_auth else 0
        }
        monthly_stats.append(month_data)
    return pd.DataFrame(monthly_stats)

def get_github_downloads(client: Client, owner: str, repos: List[str], verbose: bool = False) -> pd.DataFrame:
    """Get GitHub release downloads for a list of repos with monthly breakdown using GraphQL."""
    # No authentication (token)
    if not client:
        return pd.DataFrame(get_placeholder_data(True))

    query = gql("""
        query($owner: String!, $repo: String!, $cursor: String) {
            repository(owner: $owner, name: $repo) {
                releases(first: 100, after: $cursor, orderBy: {field: CREATED_AT, direction: DESC}) {
                    pageInfo {
                        hasNextPage
                        endCursor
                    }
                    nodes {
                        tagName
                        publishedAt
                        releaseAssets(first: 100) {
                            nodes {
                                name
                                downloadCount
                            }
                        }
                    }
                }
            }
        }
    """)

    all_releases = []

    # Fetch releases for each repository
    for repo in repos:
        if verbose:
            print(f"Fetching releases for {owner}/{repo}...")

        cursor = None
        has_more = True

        while has_more:
            variables = {
                "owner": owner,
                "repo": repo,
                "cursor": cursor
            }
            result = client.execute(query, variable_values=variables)

            for release in result['repository']['releases']['nodes']:
                # Calculate total downloads excluding .sha256 files
                total_count = sum(
                    asset['downloadCount']
                    for asset in release['releaseAssets']['nodes']
                    if not asset['name'].endswith('.sha256')
                )

                all_releases.append({
                    'tag_name': release['tagName'],
                    'published_at': release['publishedAt'],
                    'download_count': total_count
                })

            page_info = result['repository']['releases']['pageInfo']
            has_more = page_info['hasNextPage']
            cursor = page_info['endCursor']

    if verbose:
        print(f"Fetched {len(all_releases)} total releases")

    # Filter out release candidates
    stable_releases = [r for r in all_releases if not re.search(r'rc\.?[0-9]+$', r['tag_name'])]
    if verbose:
        print(f"Filtered to {len(stable_releases)} stable releases")

    if not stable_releases:
        return pd.DataFrame(get_placeholder_data(False))

    # Process releases
    release_data = []
    for release in stable_releases:
        published_at = datetime.fromisoformat(release['published_at'])

        release_data.append({
            'release_date': published_at,
            'downloads': release['download_count']
        })

    # Convert to DataFrame and sort
    df = pd.DataFrame(release_data)
    df = df.sort_values('release_date').reset_index(drop=True)

    # Calculate proportional downloads for each month
    monthly_downloads = []
    for month in ALL_MONTHS:
        month_start = month.to_timestamp().tz_localize(tz=BERLIN_TZ)
        month_end = (month + 1).to_timestamp().tz_localize(tz=BERLIN_TZ) - timedelta(days=1)

        total = 0
        for i, row in df.iterrows():
            release_date = row['release_date']
            release_downloads = row['downloads']

            # Get next release date or 1 year later
            if i < len(df) - 1:
                next_release_date = df.iloc[i + 1]['release_date']
            else:
                next_release_date = release_date + relativedelta(years=1)

            # Calculate overlap
            overlap_start = max(release_date, month_start)
            overlap_end = min(next_release_date - timedelta(days=1), month_end)

            if overlap_start <= overlap_end:
                release_period_days = (next_release_date - release_date).days
                overlap_days = (overlap_end - overlap_start).days + 1

                if release_period_days > 0:
                    proportion = overlap_days / release_period_days
                    total += release_downloads * proportion

        monthly_downloads.append({
            'Month': str(month),
            'Downloads': round(total)
        })

    return pd.DataFrame(monthly_downloads)

def fetch_github_downloads(owner: str, output_path: str, verbose: bool = False) -> None:
    """Fetch GitHub downloads and save to a TSV file."""
    client = get_gql_client()
    all_repos = get_org_repos(client, owner, verbose=verbose)
    library_repos = PACKAGE_INFO[owner]["library_repos"]
    app_repos = list(set(all_repos) - set(library_repos))

    app_data = get_github_downloads(client, owner, app_repos, verbose=verbose)
    app_data['Type'] = 'Application'
    lib_data = get_github_downloads(client, owner, library_repos, verbose=verbose)
    lib_data['Type'] = 'Library'

    data = pd.concat([app_data, lib_data], ignore_index=True)
    data.to_csv(output_path, sep='\t', index=False)
