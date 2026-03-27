"""Adzuna — job aggregator API (free tier, needs app_id + app_key)."""

import logging
from models import Job
from sources.http_utils import get_json
from config import ADZUNA_APP_ID, ADZUNA_APP_KEY

log = logging.getLogger(__name__)

BASE = "https://api.adzuna.com/v1/api/jobs"

# Search in multiple countries for remote + local jobs
SEARCHES = [
    {"country": "gb", "what": "software developer", "where": "", "extra": {}},
    {"country": "us", "what": "software engineer remote", "where": "", "extra": {}},
    {"country": "de", "what": "software developer remote", "where": "", "extra": {}},
]


def fetch_adzuna() -> list[Job]:
    """Fetch jobs from Adzuna across multiple countries."""
    if not ADZUNA_APP_ID or not ADZUNA_APP_KEY:
        log.warning("Adzuna: credentials not set — skipping.")
        return []

    jobs = []
    for search in SEARCHES:
        country = search["country"]
        url = f"{BASE}/{country}/search/1"
        params = {
            "app_id": ADZUNA_APP_ID,
            "app_key": ADZUNA_APP_KEY,
            "what": search["what"],
            "results_per_page": 20,
            "content-type": "application/json",
            "sort_by": "date",
        }
        if search["where"]:
            params["where"] = search["where"]

        data = get_json(url, params=params)
        if not data or "results" not in data:
            continue

        for item in data["results"]:
            location_parts = []
            loc = item.get("location", {})
            if loc.get("display_name"):
                location_parts.append(loc["display_name"])
            location = ", ".join(location_parts) or country.upper()

            salary = ""
            if item.get("salary_min") and item.get("salary_max"):
                salary = f"£{item['salary_min']:,.0f}–£{item['salary_max']:,.0f}"

            jobs.append(Job(
                title=item.get("title", ""),
                company=item.get("company", {}).get("display_name", ""),
                location=location,
                url=item.get("redirect_url", ""),
                source="adzuna",
                salary=salary,
                job_type=item.get("contract_time", ""),
                tags=[item.get("category", {}).get("label", "")],
                is_remote="remote" in item.get("title", "").lower() or
                          "remote" in item.get("description", "").lower()[:200],
            ))
    log.info(f"Adzuna: fetched {len(jobs)} jobs.")
    return jobs
