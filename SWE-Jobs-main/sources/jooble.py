"""Jooble — global job search API (POST-based, free key)."""

import logging
from models import Job
from sources.http_utils import post_json
from config import JOOBLE_API_KEY

log = logging.getLogger(__name__)

BASE = "https://jooble.org/api"

SEARCHES = [
    {"keywords": "software engineer", "location": "remote"},
    {"keywords": "backend developer", "location": "remote"},
    {"keywords": "flutter developer", "location": "remote"},
    {"keywords": "mobile app developer", "location": "remote"},
    {"keywords": "data scientist", "location": "remote"},
    {"keywords": "machine learning engineer", "location": "remote"},
    {"keywords": "software engineer", "location": "Egypt"},
    {"keywords": "software developer", "location": "Cairo, Egypt"},
    {"keywords": "flutter developer", "location": "Egypt"},
    {"keywords": "software engineer", "location": "Saudi Arabia"},
    {"keywords": "software developer", "location": "Riyadh, Saudi Arabia"},
    {"keywords": "flutter developer", "location": "Saudi Arabia"},
]


def fetch_jooble() -> list[Job]:
    """Fetch jobs from Jooble across multiple searches."""
    if not JOOBLE_API_KEY:
        log.warning("Jooble: API key not set — skipping.")
        return []

    url = f"{BASE}/{JOOBLE_API_KEY}"
    jobs = []

    for search in SEARCHES:
        payload = {
            "keywords": search["keywords"],
            "location": search["location"],
            "page": 1,
        }
        data = post_json(url, payload=payload)
        if not data or "jobs" not in data:
            continue

        for item in data["jobs"]:
            location = item.get("location", "")
            is_remote = "remote" in location.lower() or "remote" in search["location"].lower()

            # Clean snippet HTML
            snippet = item.get("snippet", "")
            salary = item.get("salary", "")

            jobs.append(Job(
                title=item.get("title", ""),
                company=item.get("company", ""),
                location=location or search["location"],
                url=item.get("link", ""),
                source="jooble",
                salary=salary,
                job_type=item.get("type", ""),
                tags=[],
                is_remote=is_remote,
            ))
    log.info(f"Jooble: fetched {len(jobs)} jobs.")
    return jobs
