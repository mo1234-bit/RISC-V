"""Himalayas — free remote jobs API (no key required)."""

import logging
from models import Job
from sources.http_utils import get_json

log = logging.getLogger(__name__)

BASE = "https://himalayas.app/jobs/api/search"
QUERIES = [
    "software engineer", "backend developer", "frontend developer",
    "devops", "QA engineer", "full stack developer",
    "flutter developer", "mobile developer", "react native",
    "data scientist", "machine learning", "blockchain developer",
]


def fetch_himalayas() -> list[Job]:
    """Fetch jobs from Himalayas across multiple queries."""
    jobs = []
    for q in QUERIES:
        data = get_json(BASE, params={"query": q, "limit": 20})
        if not data or "jobs" not in data:
            continue
        for item in data["jobs"]:
            location = item.get("location", "")
            remote = item.get("timezoneRestriction") is not None or "remote" in location.lower()
            jobs.append(Job(
                title=item.get("title", ""),
                company=item.get("companyName", ""),
                location=location or "Remote",
                url=item.get("applicationLink") or f"https://himalayas.app/jobs/{item.get('slug', '')}",
                source="himalayas",
                salary=_format_salary(item),
                job_type=item.get("employmentType", ""),
                tags=item.get("categories", []) or [],
                is_remote=remote,
            ))
    log.info(f"Himalayas: fetched {len(jobs)} jobs.")
    return jobs


def _format_salary(item: dict) -> str:
    mn = item.get("salaryCurrencyMin")
    mx = item.get("salaryCurrencyMax")
    cur = item.get("salaryCurrency", "USD")
    if mn and mx:
        return f"{cur} {mn:,}–{mx:,}"
    return ""
