"""
Source registry — maps source names to their fetch functions.
Import order determines fetch order.
"""

from sources.remotive import fetch_remotive
from sources.himalayas import fetch_himalayas
from sources.jobicy import fetch_jobicy
from sources.remoteok import fetch_remoteok
from sources.arbeitnow import fetch_arbeitnow
from sources.wwr import fetch_wwr
from sources.workingnomads import fetch_workingnomads
from sources.jsearch import fetch_jsearch
from sources.linkedin import fetch_linkedin
from sources.adzuna import fetch_adzuna
from sources.themuse import fetch_themuse
from sources.findwork import fetch_findwork
from sources.jooble import fetch_jooble
from sources.reed import fetch_reed
from sources.usajobs import fetch_usajobs

# (display_name, fetch_function)
ALL_FETCHERS = [
    ("Remotive",        fetch_remotive),
    ("Himalayas",       fetch_himalayas),
    ("Jobicy",          fetch_jobicy),
    ("RemoteOK",        fetch_remoteok),
    ("Arbeitnow",       fetch_arbeitnow),
    ("WWR",             fetch_wwr),
    ("Working Nomads",  fetch_workingnomads),
    ("JSearch",         fetch_jsearch),
    ("LinkedIn",        fetch_linkedin),
    ("Adzuna",          fetch_adzuna),
    ("The Muse",        fetch_themuse),
    ("Findwork",        fetch_findwork),
    ("Jooble",          fetch_jooble),
    ("Reed",            fetch_reed),
    ("USAJobs",         fetch_usajobs),
]
