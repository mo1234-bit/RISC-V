"""
Telegram message formatting and multi-topic sending.
Routes each job to correct topics in a supergroup community.
Uses message_thread_id to send to specific topics.
"""

import time
import logging
import requests
from models import Job
from config import (
    TELEGRAM_BOT_TOKEN, TELEGRAM_GROUP_ID, TELEGRAM_SEND_DELAY,
    CHANNELS, get_topic_thread_id,
)

log = logging.getLogger(__name__)

TELEGRAM_API = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"


# ─── Topic Routing ────────────────────────────────────────────

def _match_keywords(text: str, keywords: list[str]) -> bool:
    text_lower = text.lower()
    return any(kw.lower() in text_lower for kw in keywords)


def _is_egypt_job(job: Job) -> bool:
    from config import EGYPT_PATTERNS
    if not job.location:
        return False
    loc = job.location.lower()
    return any(p in loc for p in EGYPT_PATTERNS)


def _is_saudi_job(job: Job) -> bool:
    from config import SAUDI_PATTERNS
    if not job.location:
        return False
    loc = job.location.lower()
    return any(p in loc for p in SAUDI_PATTERNS)


def route_job(job: Job) -> list[str]:
    """
    Determine which topics a job should be sent to.
    Returns list of channel keys (e.g. ["general", "backend", "egypt"]).
    """
    channels = []
    tags_str = " ".join(str(t) for t in (job.tags or []))
    searchable = f"{job.title} {job.company} {tags_str}".lower()

    for key, ch in CHANNELS.items():
        match_type = ch.get("match", "")

        if match_type == "ALL":
            channels.append(key)
        elif match_type == "GEO_EGYPT":
            if _is_egypt_job(job):
                channels.append(key)
        elif match_type == "GEO_SAUDI":
            if _is_saudi_job(job):
                channels.append(key)
        elif "keywords" in ch:
            if _match_keywords(searchable, ch["keywords"]):
                channels.append(key)

    return channels


# ─── Message Formatting ──────────────────────────────────────

def format_job_message(job: Job) -> str:
    emoji = job.emoji
    title = _escape_html(job.title)
    company = _escape_html(job.company) if job.company else "Unknown"
    location = _escape_html(job.location) if job.location else "Not specified"
    source = _escape_html(job.display_source)

    lines = [
        f"{emoji} <b>{title}</b>",
        f"🏢 {company}",
        f"📍 {location}",
    ]

    if job.salary:
        lines.append(f"💰 {_escape_html(job.salary)}")
    if job.job_type:
        lines.append(f"📋 {_escape_html(job.job_type)}")
    if job.is_remote:
        lines.append("🌍 Remote")

    lines.append("")
    lines.append(f'🔗 <a href="{job.url}">Apply Now</a>')
    lines.append(f"📡 Source: {source}")

    return "\n".join(lines)


# ─── Sending ─────────────────────────────────────────────────

def _send_to_topic(message: str, thread_id: int | None = None) -> bool:
    """Send a message to the supergroup, optionally to a specific topic."""
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_GROUP_ID:
        return False

    payload = {
        "chat_id": TELEGRAM_GROUP_ID,
        "text": message,
        "parse_mode": "HTML",
        "disable_web_page_preview": True,
    }

    if thread_id is not None:
        payload["message_thread_id"] = thread_id

    try:
        resp = requests.post(
            f"{TELEGRAM_API}/sendMessage",
            json=payload,
            timeout=10,
        )
        if resp.status_code == 200:
            return True
        else:
            log.error(f"Telegram error {resp.status_code} (thread={thread_id}): {resp.text}")
            return False
    except requests.RequestException as e:
        log.error(f"Telegram request failed (thread={thread_id}): {e}")
        return False


def send_job(job: Job) -> dict:
    """Route and send a job to all matching topics. Returns {topic_key: success}."""
    target_topics = route_job(job)
    results = {}

    if not target_topics:
        log.debug(f"No matching topics for: {job.title}")
        return results

    message = format_job_message(job)

    for topic_key in target_topics:
        thread_id = get_topic_thread_id(topic_key)
        if thread_id is None:
            continue  # topic not configured, skip silently

        topic_name = CHANNELS[topic_key]["name"]
        success = _send_to_topic(message, thread_id)
        results[topic_key] = success

        if success:
            log.info(f"  ✓ Sent to {topic_name}: {job.title}")
        else:
            log.warning(f"  ✗ Failed {topic_name}: {job.title}")

        time.sleep(0.5)

    return results


def send_jobs(jobs: list[Job]) -> int:
    """Send multiple jobs to their matching topics. Returns total sent count."""
    total_sent = 0
    topic_stats = {}

    for i, job in enumerate(jobs):
        results = send_job(job)
        for t_key, success in results.items():
            if t_key not in topic_stats:
                topic_stats[t_key] = 0
            if success:
                topic_stats[t_key] += 1
                total_sent += 1

        if i < len(jobs) - 1:
            time.sleep(TELEGRAM_SEND_DELAY)

    if topic_stats:
        log.info("📊 Topic send summary:")
        for t_key, count in sorted(topic_stats.items()):
            t_name = CHANNELS.get(t_key, {}).get("name", t_key)
            log.info(f"  {t_name}: {count} jobs")

    return total_sent


def _escape_html(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )
