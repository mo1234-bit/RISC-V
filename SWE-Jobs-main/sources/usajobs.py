"""USAJobs — US government job board API (free, needs API key + email)."""

import os
import logging
from models import Job
from sources.http_utils import get_json

log = logging.getLogger(__name__)

URL = "https://data.usajobs.gov/api/search"

SEARCHES = [
    {"Keyword": "software developer", "LocationName": "", "RemoteIndicator": "True", "ResultsPerPage": 20},
    {"Keyword": "software engineer", "LocationName": "", "RemoteIndicator": "True", "ResultsPerPage": 20},
]


def fetch_usajobs() -> list[Job]:
    """Fetch remote IT jobs from USAJobs."""
    api_key = os.getenv("USAJOBS_API_KEY", "")
    api_email = os.getenv("USAJOBS_EMAIL", "")

    if not api_key or not api_email:
        log.warning("USAJobs: USAJOBS_API_KEY or USAJOBS_EMAIL not set — skipping.")
        return []

    headers = {
        "Host": "data.usajobs.gov",
        "User-Agent": api_email,
        "Authorization-Key": api_key,
    }

    jobs = []
    for params in SEARCHES:
        data = get_json(URL, params=params, headers=headers)
        if not data:
            continue

        results = (data.get("SearchResult", {})
                      .get("SearchResultItems", []))

        for wrapper in results:
            item = wrapper.get("MatchedObjectDescriptor", {})
            pos = item.get("PositionLocation", [{}])
            location = pos[0].get("LocationName", "USA") if pos else "USA"

            salary = ""
            remun = item.get("PositionRemuneration", [{}])
            if remun:
                mn = remun[0].get("MinimumRange", "")
                mx = remun[0].get("MaximumRange", "")
                if mn and mx:
                    salary = f"${float(mn):,.0f}–${float(mx):,.0f}"

            schedule = item.get("PositionSchedule", [{}])
            job_type = schedule[0].get("Name", "") if schedule else ""

            url = item.get("PositionURI", "")
            apply_url = item.get("ApplyURI", [""])[0] if item.get("ApplyURI") else url

            jobs.append(Job(
                title=item.get("PositionTitle", ""),
                company=item.get("OrganizationName", "US Government"),
                location=location,
                url=apply_url or url,
                source="usajobs",
                salary=salary,
                job_type=job_type,
                tags=[],
                is_remote=True,
            ))
    log.info(f"USAJobs: fetched {len(jobs)} jobs.")
    return jobs
