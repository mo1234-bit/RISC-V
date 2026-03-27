"""We Work Remotely — RSS feeds for programming job categories."""

import logging
import xml.etree.ElementTree as ET
from models import Job
from sources.http_utils import get_text

log = logging.getLogger(__name__)

RSS_FEEDS = {
    "Full-Stack": "https://weworkremotely.com/categories/remote-full-stack-programming-jobs.rss",
    "Back-End": "https://weworkremotely.com/categories/remote-back-end-programming-jobs.rss",
    "Front-End": "https://weworkremotely.com/categories/remote-front-end-programming-jobs.rss",
    "DevOps": "https://weworkremotely.com/categories/remote-devops-sysadmin-jobs.rss",
}


def fetch_wwr() -> list[Job]:
    """Fetch jobs from We Work Remotely RSS feeds."""
    jobs = []
    for category, url in RSS_FEEDS.items():
        xml_text = get_text(url)
        if not xml_text:
            log.warning(f"WWR: no data for {category}")
            continue
        try:
            root = ET.fromstring(xml_text)
            for item in root.findall(".//item"):
                title_raw = item.findtext("title", "")
                link = item.findtext("link", "")

                # WWR title format: "Company: Job Title"
                if ": " in title_raw:
                    company, title = title_raw.split(": ", 1)
                else:
                    company, title = "", title_raw

                jobs.append(Job(
                    title=title.strip(),
                    company=company.strip(),
                    location="Remote",
                    url=link.strip(),
                    source="wwr",
                    tags=[category],
                    is_remote=True,
                ))
        except ET.ParseError as e:
            log.warning(f"WWR: XML parse error for {category}: {e}")

    log.info(f"WWR: fetched {len(jobs)} jobs.")
    return jobs
