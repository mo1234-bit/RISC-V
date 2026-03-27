"""
Job data model and filtering logic.
Handles keyword matching and geo-based filtering:
  - Egypt & Saudi Arabia: all jobs (onsite + remote)
  - Rest of world: remote only
"""

from dataclasses import dataclass, field
from typing import Optional
import config


def _flatten_tags(tags) -> str:
    """Safely flatten tags to a string, handling nested lists and non-string items."""
    if not tags:
        return ""
    flat = []
    for item in tags:
        if isinstance(item, list):
            flat.extend(str(i) for i in item)
        elif isinstance(item, dict):
            flat.append(str(item.get("name", item.get("label", ""))))
        else:
            flat.append(str(item))
    return " ".join(flat)


@dataclass
class Job:
    title: str
    company: str
    location: str
    url: str
    source: str
    salary: str = ""
    job_type: str = ""
    tags: list = field(default_factory=list)
    is_remote: bool = False
    original_source: str = ""  # for aggregators like JSearch

    @property
    def unique_id(self) -> str:
        """Generate a unique ID for dedup. Based on URL or title+company."""
        if self.url:
            # Normalize URL: strip tracking params
            clean = self.url.split("?utm")[0].split("&utm")[0]
            clean = clean.rstrip("/").lower()
            return clean
        return f"{self.title.lower().strip()}|{self.company.lower().strip()}"

    @property
    def display_source(self) -> str:
        """Get the display name for the source."""
        if self.original_source:
            return self.original_source
        return config.SOURCE_DISPLAY.get(self.source, self.source.title())

    @property
    def emoji(self) -> str:
        """Pick the best emoji based on title and location."""
        text = f"{self.title} {self.location} {_flatten_tags(self.tags)}".lower()
        for keyword, em in config.EMOJI_MAP.items():
            if keyword in text:
                return em
        return config.DEFAULT_EMOJI


def _text_matches_any(text: str, patterns) -> bool:
    """Check if lowered text contains any of the patterns."""
    text_lower = text.lower()
    return any(p.lower() in text_lower for p in patterns)


def _is_in_egypt(location: str) -> bool:
    """Check if location indicates Egypt."""
    loc = location.lower().strip()
    return any(p in loc for p in config.EGYPT_PATTERNS)


def _is_in_saudi(location: str) -> bool:
    """Check if location indicates Saudi Arabia."""
    loc = location.lower().strip()
    return any(p in loc for p in config.SAUDI_PATTERNS)


def _is_remote(job: Job) -> bool:
    """Check if job is remote based on multiple signals."""
    if job.is_remote:
        return True
    combined = f"{job.title} {job.location} {job.job_type} {_flatten_tags(job.tags)}".lower()
    return any(p in combined for p in config.REMOTE_PATTERNS)


def _is_in_allowed_country(location: str) -> bool:
    """Check if location is in Egypt or Saudi Arabia."""
    return _is_in_egypt(location) or _is_in_saudi(location)


def is_programming_job(job: Job) -> bool:
    """
    Check if job matches programming keywords.
    Must match at least one INCLUDE keyword and no EXCLUDE keywords.
    """
    searchable = f"{job.title} {_flatten_tags(job.tags)}".lower()

    # Must match at least one include keyword
    has_include = any(kw.lower() in searchable for kw in config.INCLUDE_KEYWORDS)
    if not has_include:
        return False

    # Must NOT match any exclude keyword
    has_exclude = any(kw.lower() in searchable for kw in config.EXCLUDE_KEYWORDS)
    if has_exclude:
        return False

    return True


def passes_geo_filter(job: Job) -> bool:
    """
    Geo-filtering logic:
    - Egypt/Saudi: pass all (onsite + remote)
    - Remote-only sources (Remotive, RemoteOK, WWR, Working Nomads): auto-pass
    - Others: must be remote OR in Egypt/Saudi
    """
    # Sources that are inherently remote-only
    remote_only_sources = {"remotive", "remoteok", "wwr", "workingnomads", "findwork", "reed"}

    # If source is remote-only, it passes geo filter
    if job.source in remote_only_sources:
        return True

    # If job is in Egypt or Saudi Arabia, pass regardless
    if _is_in_allowed_country(job.location):
        return True

    # If job is remote, pass regardless of location
    if _is_remote(job):
        return True

    # Onsite outside Egypt/Saudi → reject
    return False


def filter_jobs(jobs: list[Job]) -> list[Job]:
    """
    Apply all filters:
    1. Must be a programming job (keywords)
    2. Must pass geo filter
    Returns filtered list.
    """
    filtered = []
    for job in jobs:
        if not job.title or not job.url:
            continue
        if not is_programming_job(job):
            continue
        if not passes_geo_filter(job):
            continue
        filtered.append(job)
    return filtered
