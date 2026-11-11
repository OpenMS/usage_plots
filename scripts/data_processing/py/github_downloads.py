#!/usr/bin/env python3

from gql import gql, Client
from datetime import datetime, timedelta, timezone
import pandas as pd
from typing import List
import re

from scripts.data_processing.py.github_shared import get_gql_client, get_org_repos, ALL_MONTHS, BERLIN_TZ, CURRENT_DATE
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
                    'repo': repo,
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

    # GitHub only reports the total downloads of a release. They are spread evenly over the days (Europe/Berlin)
    # from the release to the day before the next release of the same repository. The latest release of a repository
    # is spread up to and including the day on which the statistics are fetched, so no downloads are attributed to
    # future months.
    releases_by_repo = {}
    for release in stable_releases:
        release_day = datetime.fromisoformat(release['published_at']).astimezone(BERLIN_TZ).date()
        releases_by_repo.setdefault(release['repo'], []).append((release_day, release['download_count']))

    periods = []  # (first day, last day, downloads)
    for releases in releases_by_repo.values():
        releases.sort()
        last_days = [day - timedelta(days=1) for day, _ in releases[1:]] + [CURRENT_DATE.date()]
        for (first_day, downloads), last_day in zip(releases, last_days):
            # A release that is followed by another release on the same day gets this day
            periods.append((first_day, max(first_day, last_day), downloads))

    # Calculate proportional downloads for each month
    monthly_downloads = []
    for month in ALL_MONTHS:
        month_first_day = month.start_time.date()
        month_last_day = month.end_time.date()

        total = 0
        for first_day, last_day, release_downloads in periods:
            overlap_days = (min(last_day, month_last_day) - max(first_day, month_first_day)).days + 1
            if overlap_days > 0:
                total += release_downloads * overlap_days / ((last_day - first_day).days + 1)

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
