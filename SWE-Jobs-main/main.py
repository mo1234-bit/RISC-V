"""
Programming Jobs Telegram Bot — Main entry point.
Orchestrates: fetch → filter → dedup → send.
"""

import os
import sys
import logging
import time

from config import MAX_JOBS_PER_RUN, SEEN_JOBS_FILE, SEED_MODE_ENV
from sources import ALL_FETCHERS
from models import filter_jobs
from dedup import load_seen_ids, save_seen_ids, deduplicate, mark_as_seen
from telegram_sender import send_jobs

# ─── Logging ─────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("main")


def main():
    start = time.time()
    log.info("=" * 60)
    log.info("Programming Jobs Bot — Starting run")
    log.info("=" * 60)

    # ── 1. Load seen IDs ──────────────────────────────────────
    seen = load_seen_ids(SEEN_JOBS_FILE)
    is_seed = os.getenv(SEED_MODE_ENV, "").lower() in ("1", "true", "yes") or len(seen) == 0

    if is_seed:
        log.info("🌱 SEED MODE: will register all jobs without sending.")

    # ── 2. Fetch from all sources ─────────────────────────────
    all_jobs = []
    for name, fetcher in ALL_FETCHERS:
        try:
            log.info(f"📡 Fetching from {name}...")
            jobs = fetcher()
            all_jobs.extend(jobs)
            log.info(f"  ✓ {name}: {len(jobs)} raw jobs")
        except Exception as e:
            log.error(f"  ✗ {name} failed: {e}")

    log.info(f"Total raw jobs fetched: {len(all_jobs)}")

    # ── 3. Filter (keywords + geo) ────────────────────────────
    filtered = filter_jobs(all_jobs)
    log.info(f"After filtering: {len(filtered)} jobs")

    # ── 4. Deduplicate ────────────────────────────────────────
    new_jobs = deduplicate(filtered, seen)
    log.info(f"New jobs to process: {len(new_jobs)}")

    # ── 5. Send or seed ───────────────────────────────────────
    if is_seed:
        log.info(f"🌱 Seed mode: marking {len(new_jobs)} jobs as seen (no sending).")
        seen = mark_as_seen(new_jobs, seen)
        # Also mark ALL filtered (not just new) to catch everything
        seen = mark_as_seen(filtered, seen)
    else:
        # Cap to prevent flooding
        to_send = new_jobs[:MAX_JOBS_PER_RUN]
        if len(new_jobs) > MAX_JOBS_PER_RUN:
            log.warning(f"Capped to {MAX_JOBS_PER_RUN} (had {len(new_jobs)} new)")

        if to_send:
            log.info(f"📨 Sending {len(to_send)} jobs to Telegram...")
            sent = send_jobs(to_send)
            log.info(f"✅ Successfully sent {sent}/{len(to_send)} jobs.")
        else:
            log.info("No new jobs to send.")

        # Mark sent + filtered as seen
        seen = mark_as_seen(new_jobs, seen)

    # ── 6. Save seen IDs ──────────────────────────────────────
    save_seen_ids(seen, SEEN_JOBS_FILE)

    elapsed = time.time() - start
    log.info(f"Run complete in {elapsed:.1f}s. Total seen: {len(seen)}")
    log.info("=" * 60)


if __name__ == "__main__":
    main()
