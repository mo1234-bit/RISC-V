"""
Deduplication: tracks seen job IDs to avoid re-sending.
Uses seen_jobs.json stored on a git branch.
"""

import json
import os
import logging
from models import Job
from config import SEEN_JOBS_FILE

log = logging.getLogger(__name__)


def load_seen_ids(path: str = SEEN_JOBS_FILE) -> set:
    """Load previously seen job IDs from JSON file."""
    if not os.path.exists(path):
        log.info("No seen_jobs file found — starting fresh.")
        return set()
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        ids = set(data) if isinstance(data, list) else set()
        log.info(f"Loaded {len(ids)} seen job IDs.")
        return ids
    except (json.JSONDecodeError, IOError) as e:
        log.warning(f"Error reading seen_jobs: {e} — starting fresh.")
        return set()


def save_seen_ids(seen: set, path: str = SEEN_JOBS_FILE) -> None:
    """Save seen job IDs to JSON file."""
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(sorted(seen), f, ensure_ascii=False)
        log.info(f"Saved {len(seen)} seen job IDs.")
    except IOError as e:
        log.error(f"Error saving seen_jobs: {e}")


def deduplicate(jobs: list[Job], seen: set) -> list[Job]:
    """
    Return only jobs whose unique_id is NOT in seen.
    Also deduplicates within the batch itself.
    """
    new_jobs = []
    batch_ids = set()

    for job in jobs:
        uid = job.unique_id
        if uid in seen:
            continue
        if uid in batch_ids:
            continue
        batch_ids.add(uid)
        new_jobs.append(job)

    log.info(f"Dedup: {len(jobs)} total → {len(new_jobs)} new jobs.")
    return new_jobs


def mark_as_seen(jobs: list[Job], seen: set) -> set:
    """Add job IDs to the seen set. Returns updated set."""
    for job in jobs:
        seen.add(job.unique_id)
    return seen
