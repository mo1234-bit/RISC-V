"""Remotive — remote jobs API (software-dev, qa, devops-sysadmin)."""

import logging
from models import Job
from sources.http_utils import get_json

log = logging.getLogger(__name__)

BASE = "https://remotive.com/api/remote-jobs"
CATEGORIES = ["software-dev", "qa", "devops-sysadmin"]


def fetch_remotive() -> list[Job]:
    """Fetch jobs from Remotive across multiple categories."""
    jobs = []
    for cat in CATEGORIES:
        data = get_json(BASE, params={"category": cat, "limit": 50})
        if not data or "jobs" not in data:
            log.warning(f"Remotive: no data for category={cat}")
            continue
        for item in data["jobs"]:
            jobs.append(Job(
                title=item.get("title", ""),
                company=item.get("company_name", ""),
                location=item.get("candidate_required_location", "Anywhere"),
                url=item.get("url", ""),
                source="remotive",
                salary=item.get("salary", ""),
                job_type=item.get("job_type", "").replace("_", " ").title(),
                tags=[item.get("category", "")],
                is_remote=True,
            ))
    log.info(f"Remotive: fetched {len(jobs)} jobs.")
    return jobs
