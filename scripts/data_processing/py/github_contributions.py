#!/usr/bin/env python3

from datetime import datetime, timezone
import pandas as pd
from typing import List, Dict

from gql import gql, Client

from scripts.data_processing.py.github_shared import (
    get_org_repos,
    START_DATE,
    get_gql_client,
    ALL_MONTHS,
    BERLIN_TZ
)

def get_placeholder_data(no_auth: bool) -> pd.DataFrame:
    monthly_stats = []
    for month in ALL_MONTHS:
        month_data = {
            'Month': str(month),
            'Issues_Opened': -1 if no_auth else 0,
            'Issues_Closed': -1 if no_auth else 0,
            'PRs_Opened': -1 if no_auth else 0,
            'PRs_Closed': -1 if no_auth else 0
        }
        monthly_stats.append(month_data)
    return pd.DataFrame(monthly_stats)

def fetch_all_issues(client: Client, owner: str, repo: str, since_date: datetime, verbose: bool = False) -> List[Dict]:
    """Fetch all issues and PRs for a repository using GraphQL."""
    if verbose:
        print(f"  Fetching items since {since_date.isoformat()}")

    since_iso = since_date.astimezone(timezone.utc).isoformat()
    all_items = []

    # Query for issues
    issues_query = gql("""
        query($owner: String!, $repo: String!, $since: DateTime!, $cursor: String) {
            repository(owner: $owner, name: $repo) {
                issues(first: 100, after: $cursor, filterBy: {since: $since}) {
                    pageInfo {
                        hasNextPage
                        endCursor
                    }
                    nodes {
                        createdAt
                        closedAt
                        state
                    }
                }
            }
        }
    """)

    # Query for pull requests
    prs_query = gql("""
        query($owner: String!, $repo: String!, $cursor: String) {
            repository(owner: $owner, name: $repo) {
                pullRequests(first: 100, after: $cursor, orderBy: {field: CREATED_AT, direction: DESC}) {
                    pageInfo {
                        hasNextPage
                        endCursor
                    }
                    nodes {
                        createdAt
                        closedAt
                        state
                    }
                }
            }
        }
    """)

    # Fetch issues
    issues_cursor = None
    issues_has_more = True

    while issues_has_more:
        variables = {
            "owner": owner,
            "repo": repo,
            "since": since_iso,
            "cursor": issues_cursor
        }
        result = client.execute(issues_query, variable_values=variables)

        for issue in result['repository']['issues']['nodes']:
            created_at = datetime.fromisoformat(issue['createdAt'])
            closed_at = datetime.fromisoformat(issue['closedAt']) if issue['closedAt'] else None

            created_in_range = created_at >= since_date
            closed_in_range = closed_at is not None and closed_at >= since_date

            if created_in_range or closed_in_range:
                all_items.append({
                    'created_at': created_at.astimezone(BERLIN_TZ),
                    'closed_at': closed_at.astimezone(BERLIN_TZ) if closed_at else None,
                    'is_pr': False
                })

        page_info = result['repository']['issues']['pageInfo']
        issues_has_more = page_info['hasNextPage']
        issues_cursor = page_info['endCursor']

    # Fetch pull requests
    prs_cursor = None
    prs_has_more = True

    while prs_has_more:
        variables = {
            "owner": owner,
            "repo": repo,
            "cursor": prs_cursor
        }
        result = client.execute(prs_query, variable_values=variables)

        for pr in result['repository']['pullRequests']['nodes']:
            created_at = datetime.fromisoformat(pr['createdAt'])
            closed_at = datetime.fromisoformat(pr['closedAt']) if pr['closedAt'] else None

            # Check if in timeframe
            created_in_range = created_at >= since_date
            closed_in_range = closed_at is not None and closed_at >= since_date

            if created_in_range or closed_in_range:
                all_items.append({
                    'created_at': created_at.astimezone(BERLIN_TZ),
                    'closed_at': closed_at.astimezone(BERLIN_TZ) if closed_at else None,
                    'is_pr': True
                })
            elif created_at < since_date:
                # Since PRs are ordered by creation date descending, stop when we reach old PRs
                prs_has_more = False
                break

        if prs_has_more:
            page_info = result['repository']['pullRequests']['pageInfo']
            prs_has_more = page_info['hasNextPage']
            prs_cursor = page_info['endCursor']

    issues_count = sum(1 for item in all_items if not item['is_pr'])
    prs_count = sum(1 for item in all_items if item['is_pr'])
    if verbose:
        print(f"  Total items: {len(all_items)} ({issues_count} issues + {prs_count} PRs)")

    return all_items

def generate_monthly_stats(owner: str, since_date: datetime, verbose: bool = False) -> pd.DataFrame:
    """Generate monthly statistics for issues and PRs."""
    client = get_gql_client()

    # No authentication (token)
    if not client:
        return get_placeholder_data(True)

    # Get all repositories
    repos = get_org_repos(client, owner, verbose=verbose)

    all_items = []

    # Fetch data for each repository
    for repo in repos:
        if verbose:
            print(f"Fetching issues and pull requests for {owner}/{repo}...")
        repo_items = fetch_all_issues(client, owner, repo, since_date, verbose=verbose)
        if verbose:
            print(f"Fetched {len(repo_items)} items")
        all_items.extend(repo_items)

    if verbose:
        print(f"Fetched {len(all_items)} items total across all repositories")

    # Convert to DataFrame
    df = pd.DataFrame(all_items)

    if df.empty:
        return get_placeholder_data(False)

    # Add month columns
    df['created_month'] = pd.to_datetime(df['created_at']).dt.tz_localize(None).dt.to_period('M')
    df['closed_month'] = pd.to_datetime(df['closed_at']).dt.tz_localize(None).dt.to_period('M')

    # Calculate statistics for each month
    monthly_stats = []
    for month in ALL_MONTHS:
        month_data = {
            'Month': str(month),
            'Issues_Opened': len(df[(df['created_month'] == month) & (~df['is_pr'])]),
            'Issues_Closed': len(df[(df['closed_month'] == month) & (~df['is_pr'])]),
            'PRs_Opened': len(df[(df['created_month'] == month) & (df['is_pr'])]),
            'PRs_Closed': len(df[(df['closed_month'] == month) & (df['is_pr'])])
        }
        monthly_stats.append(month_data)

    return pd.DataFrame(monthly_stats)

def fetch_github_contributions(owner: str, output_path: str, verbose: bool = False) -> None:
    """Fetch GitHub contributions and save to a TSV file."""
    data = generate_monthly_stats(owner, since_date=START_DATE, verbose=verbose)
    data.to_csv(output_path, sep='\t', index=False)
