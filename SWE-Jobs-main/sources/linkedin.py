"""
LinkedIn — Guest API (no login, no key required).
Parses HTML from public job search endpoint.
Searches for Egypt, Saudi Arabia, and remote jobs.
"""

import logging
import re
import time
from models import Job
from sources.http_utils import get_text

log = logging.getLogger(__name__)

SEARCH_URL = "https://www.linkedin.com/jobs-guest/jobs/api/seeMoreJobPostings/search"
DETAIL_URL = "https://www.linkedin.com/jobs-guest/jobs/api/jobPosting/{job_id}"

# f_TPR=r86400 = last 24 hours, f_WT=2 = remote
# Egypt onsite
SEARCHES = [
    {"keywords": "software engineer", "location": "Egypt", "f_TPR": "r86400"},
    {"keywords": "software developer", "location": "Egypt", "f_TPR": "r86400"},
    {"keywords": "backend developer", "location": "Egypt", "f_TPR": "r86400"},
    {"keywords": "flutter developer", "location": "Egypt", "f_TPR": "r86400"},
    {"keywords": "mobile developer", "location": "Egypt", "f_TPR": "r86400"},
    {"keywords": "data scientist", "location": "Egypt", "f_TPR": "r86400"},
    # Saudi Arabia onsite
    {"keywords": "software engineer", "location": "Saudi Arabia", "f_TPR": "r86400"},
    {"keywords": "software developer", "location": "Saudi Arabia", "f_TPR": "r86400"},
    {"keywords": "backend developer", "location": "Saudi Arabia", "f_TPR": "r86400"},
    {"keywords": "flutter developer", "location": "Saudi Arabia", "f_TPR": "r86400"},
    {"keywords": "mobile developer", "location": "Saudi Arabia", "f_TPR": "r86400"},
    # Remote worldwide
    {"keywords": "software engineer", "f_WT": "2", "f_TPR": "r86400"},
    {"keywords": "backend developer", "f_WT": "2", "f_TPR": "r86400"},
    {"keywords": "frontend developer", "f_WT": "2", "f_TPR": "r86400"},
    {"keywords": "devops engineer", "f_WT": "2", "f_TPR": "r86400"},
    {"keywords": "flutter developer", "f_WT": "2", "f_TPR": "r86400"},
    {"keywords": "mobile developer", "f_WT": "2", "f_TPR": "r86400"},
    {"keywords": "machine learning engineer", "f_WT": "2", "f_TPR": "r86400"},
    {"keywords": "data scientist", "f_WT": "2", "f_TPR": "r86400"},
    {"keywords": "QA engineer", "f_WT": "2", "f_TPR": "r86400"},
]

# Delay between requests to avoid rate limiting
REQUEST_DELAY = 4


def fetch_linkedin() -> list[Job]:
    """Fetch jobs from LinkedIn's public guest API."""
    jobs = []
    seen_urls = set()

    for params in SEARCHES:
        params["start"] = "0"
        html = get_text(SEARCH_URL, params=params, headers={
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 Chrome/125.0.0.0 Safari/537.36"
            ),
        })

        if not html:
            log.warning(f"LinkedIn: no response for {params.get('keywords')}")
            time.sleep(REQUEST_DELAY)
            continue

        parsed = _parse_search_html(html, params)
        for job in parsed:
            if job.url not in seen_urls:
                seen_urls.add(job.url)
                jobs.append(job)

        time.sleep(REQUEST_DELAY)

    log.info(f"LinkedIn: fetched {len(jobs)} jobs.")
    return jobs


def _parse_search_html(html: str, search_params: dict) -> list[Job]:
    """Parse LinkedIn search results HTML into Job objects."""
    jobs = []

    # LinkedIn returns a list of <li> with job cards
    # Each card has: data-entity-urn, title in <h3>, company in <h4>, location in <span>
    # We'll use regex since it's simple HTML fragments

    # Find all job card blocks
    cards = re.findall(
        r'<li>.*?</li>',
        html,
        re.DOTALL,
    )

    if not cards:
        # Try alternate pattern — LinkedIn sometimes wraps differently
        cards = re.findall(
            r'<div class="base-card.*?</div>\s*</div>\s*</div>',
            html,
            re.DOTALL,
        )

    for card in cards:
        try:
            # Extract title
            title_match = re.search(
                r'class="base-search-card__title[^"]*"[^>]*>(.*?)</(?:h3|a|span)>',
                card, re.DOTALL
            )
            title = _clean(title_match.group(1)) if title_match else ""

            # Extract company
            company_match = re.search(
                r'class="base-search-card__subtitle[^"]*"[^>]*>(.*?)</(?:h4|a|span)>',
                card, re.DOTALL
            )
            company = _clean(company_match.group(1)) if company_match else ""

            # Extract location
            location_match = re.search(
                r'class="job-search-card__location[^"]*"[^>]*>(.*?)</span>',
                card, re.DOTALL
            )
            location = _clean(location_match.group(1)) if location_match else ""

            # Extract URL
            url_match = re.search(r'href="(https://[^"]*linkedin\.com/jobs/view/[^"]*)"', card)
            url = url_match.group(1).split("?")[0] if url_match else ""

            if not title or not url:
                continue

            # Determine if remote from search params or location
            is_remote = search_params.get("f_WT") == "2" or "remote" in location.lower()

            jobs.append(Job(
                title=title,
                company=company,
                location=location or search_params.get("location", "Remote"),
                url=url,
                source="linkedin",
                is_remote=is_remote,
            ))
        except Exception as e:
            log.debug(f"LinkedIn: error parsing card: {e}")
            continue

    return jobs


def _clean(text: str) -> str:
    """Strip HTML tags and whitespace."""
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()
