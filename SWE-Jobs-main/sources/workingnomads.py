"""Working Nomads — RSS feed for development jobs."""

import logging
from models import Job
from sources.http_utils import get_json

log = logging.getLogger(__name__)

URL = "https://www.workingnomads.com/api/exposed_jobs/"


def fetch_workingnomads() -> list[Job]:
    """Fetch development jobs from Working Nomads JSON API."""
    data = get_json(URL)
    if not data or not isinstance(data, list):
        # Fallback: try RSS
        from sources.http_utils import get_text
        xml_text = get_text("https://www.workingnomads.com/jobsrss?category=development")
        if not xml_text:
            log.warning("Working Nomads: no data from API or RSS.")
            return []
        return _parse_rss(xml_text)

    jobs = []
    for item in data:
        cat = item.get("category_name", "")
        # Only development-related categories
        if cat.lower() not in ("development", "dev", "sysadmin", "devops"):
            continue
        title = item.get("title", "")
        company = item.get("company_name", "")
        url = item.get("url", "") or item.get("external_url", "")

        jobs.append(Job(
            title=title,
            company=company,
            location="Remote",
            url=url,
            source="workingnomads",
            tags=[cat] if cat else [],
            is_remote=True,
        ))
    log.info(f"Working Nomads: fetched {len(jobs)} jobs.")
    return jobs


def _parse_rss(xml_text: str) -> list[Job]:
    """Fallback: parse RSS feed."""
    import xml.etree.ElementTree as ET
    jobs = []
    try:
        root = ET.fromstring(xml_text)
        for item in root.findall(".//item"):
            title = item.findtext("title", "")
            link = item.findtext("link", "")
            category = item.findtext("category", "")
            company = ""
            if " at " in title:
                parts = title.rsplit(" at ", 1)
                title = parts[0].strip()
                company = parts[1].strip()
            jobs.append(Job(
                title=title, company=company, location="Remote",
                url=link.strip(), source="workingnomads",
                tags=[category] if category else [], is_remote=True,
            ))
    except ET.ParseError as e:
        log.warning(f"Working Nomads RSS parse error: {e}")
    log.info(f"Working Nomads: fetched {len(jobs)} jobs (RSS fallback).")
    return jobs
