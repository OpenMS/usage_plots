#!/usr/bin/env python3

import os
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
from typing import List, Optional, Final
import pandas as pd

from gql import gql, Client
from gql.transport.requests import RequestsHTTPTransport

def get_org_repos(client: Client, owner: str, verbose: bool = False) -> List[str]:
    """Fetch all repositories for an organization using GraphQL."""
    query = gql("""
        query($owner: String!, $cursor: String) {
            organization(login: $owner) {
                repositories(first: 100, after: $cursor) {
                    pageInfo {
                        hasNextPage
                        endCursor
                    }
                    nodes {
                        name
                    }
                }
            }
        }
    """)

    repo_names = []
    cursor = None
    has_more = True

    while has_more:
        variables = {
            "owner": owner,
            "cursor": cursor
        }
        result = client.execute(query, variable_values=variables)

        for repo in result['organization']['repositories']['nodes']:
            repo_names.append(repo['name'])

        page_info = result['organization']['repositories']['pageInfo']
        has_more = page_info['hasNextPage']
        cursor = page_info['endCursor']

    if verbose:
        print(f"Found {len(repo_names)} repositories for {owner}")
    return repo_names

def get_gql_client() -> Optional[Client]:
    """Get GraphQL client if token is available."""
    github_token = os.getenv("GITHUB_PAT", "")
    if not github_token:
        return None

    transport = RequestsHTTPTransport(
        url='https://api.github.com/graphql',
        headers={'Authorization': f'bearer {github_token}'},
        use_json=True,
    )
    return Client(transport=transport, fetch_schema_from_transport=False)

BERLIN_TZ = ZoneInfo("Europe/Berlin")
CURRENT_DATE = datetime.now(tz=BERLIN_TZ)
CURRENT_YEAR = CURRENT_DATE.year
PREVIOUS_YEAR = CURRENT_YEAR - 1
START_DATE = datetime(year=PREVIOUS_YEAR, month=1, day=1, tzinfo=BERLIN_TZ)
END_DATE = datetime(year=CURRENT_YEAR, month=12, day=31, tzinfo=BERLIN_TZ)
ALL_MONTHS = pd.period_range(start=START_DATE, end=END_DATE, freq='M')
