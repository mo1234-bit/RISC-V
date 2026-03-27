# 💻 Programming Jobs Telegram Community Bot

Automated Telegram bot that aggregates **programming jobs** from **15 free sources** and routes them to specialized **topics** in a Telegram community group — updated every 5 minutes via GitHub Actions (free).

## 🎯 What it does

- Fetches jobs from 15 sources every 5 minutes
- Filters by **253 keywords** across all programming fields
- **Geo-filtering**: Egypt & Saudi Arabia → all jobs (onsite + remote) | Rest of world → remote only
- **Smart routing**: each job goes to the right topic(s) automatically
- Deduplicates — never sends the same job twice
- Runs 100% free on GitHub Actions

## 📡 Sources (15)

| # | Source | Type | Coverage |
|---|--------|------|----------|
| 1 | Remotive | API | Remote worldwide |
| 2 | Himalayas | API | Remote worldwide |
| 3 | Jobicy | API | Remote worldwide |
| 4 | RemoteOK | JSON Feed | Remote worldwide |
| 5 | Arbeitnow | API | Europe + Remote |
| 6 | We Work Remotely | RSS (5 feeds) | Remote worldwide |
| 7 | Working Nomads | API/RSS | Remote worldwide |
| 8 | JSearch/RapidAPI | API | LinkedIn + Indeed + Glassdoor (Global + Egypt + Saudi) |
| 9 | LinkedIn | Guest API | Egypt + Saudi + Remote worldwide |
| 10 | Adzuna | API | Multi-country |
| 11 | The Muse | API | Software Engineering |
| 12 | Findwork.dev | API | Software dev remote |
| 13 | Jooble | API | Global (Egypt + Saudi + Remote) |
| 14 | Reed.co.uk | API | UK + Remote |
| 15 | USAJobs | API | US Gov remote IT |

## 📋 Community Topics (14)

Each job is automatically routed to the matching topic(s). One job can go to multiple topics.

| Topic | What goes there |
|-------|----------------|
| 💻 **General** | All jobs (everything) |
| ⚙️ **Backend** | Backend + Full-Stack jobs |
| 🎨 **Frontend** | Frontend + Full-Stack jobs |
| 📱 **Mobile** | Flutter, React Native, iOS, Android |
| 🚀 **DevOps & Cloud** | DevOps, SRE, AWS, Kubernetes, Docker |
| 🧪 **QA & Testing** | QA, SDET, Test Automation |
| 🤖 **AI/ML & Data Science** | Machine Learning, Data Science, NLP, LLM |
| 🔒 **Cybersecurity** | Security, Penetration Testing, SOC |
| 🎮 **Game Development** | Unity, Unreal, Game Programming |
| ⛓️ **Blockchain & Web3** | Solidity, Smart Contracts, DeFi |
| 🇪🇬 **Egypt Jobs** | All programming jobs located in Egypt |
| 🇸🇦 **Saudi Jobs** | All programming jobs located in Saudi Arabia |
| 🎓 **Internships** | Internships, Trainee, Entry Level, Fresh Grad |
| 🏢 **ERP & Accounting** | Odoo, SAP, Salesforce, Oracle, Dynamics |

### Routing examples:
- `Flutter Developer in Cairo` → **General + Mobile + Egypt**
- `Full Stack Developer` → **General + Backend + Frontend**
- `ML Engineer Remote` → **General + AI/ML**
- `Software Intern in Egypt` → **General + Egypt + Internships**
- `Odoo Developer in Riyadh` → **General + Saudi + ERP**

## 🚀 Setup

### 1. Create Telegram Community

1. Create a **Supergroup** on Telegram
2. Enable **Topics** in group settings
3. Create topics for each category you want
4. Create a bot via [@BotFather](https://t.me/BotFather) → get token
5. Add bot as **Admin** in the group

### 2. Get Topic Thread IDs

Each topic has a link like `t.me/YourGroup/2` — the number at the end is the **thread_id**.

To get the Group Chat ID:
1. Add the bot to the group
2. Send a message in the group
3. Open `https://api.telegram.org/bot<TOKEN>/getUpdates` in browser
4. Find `"chat":{"id":` — that's your Group ID (negative number)

### 3. Get API Keys (all free)

| Key | Where | Required? |
|-----|-------|-----------|
| `RAPIDAPI_KEY` | [RapidAPI JSearch](https://rapidapi.com/letscrape-6bRBa3QguO5/api/jsearch) | Recommended |
| `ADZUNA_APP_ID` + `ADZUNA_APP_KEY` | [Adzuna Developer](https://developer.adzuna.com/) | Optional |
| `FINDWORK_API_KEY` | [Findwork.dev](https://findwork.dev/developers/) | Optional |
| `JOOBLE_API_KEY` | [Jooble API](https://jooble.org/api/about) | Optional |
| `REED_API_KEY` | [Reed Developers](https://www.reed.co.uk/developers) | Optional |

Sources without API keys are skipped silently — the bot works with whatever keys you provide.

### 4. GitHub Repository Setup

```bash
git clone https://github.com/YOUR_USERNAME/programming-jobs-bot.git
cd programming-jobs-bot
git push -u origin main
```

### 5. Add GitHub Secrets

Go to **Settings → Secrets → Actions** and add:

**Required:**
| Secret | Value |
|--------|-------|
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather |
| `TELEGRAM_GROUP_ID` | Group chat ID (negative number) |

**Topic Thread IDs (add the ones you created):**
| Secret | Value |
|--------|-------|
| `TOPIC_GENERAL` | Thread ID for General topic |
| `TOPIC_BACKEND` | Thread ID for Backend topic |
| `TOPIC_FRONTEND` | Thread ID for Frontend topic |
| `TOPIC_MOBILE` | Thread ID for Mobile topic |
| `TOPIC_DEVOPS` | Thread ID for DevOps topic |
| `TOPIC_QA` | Thread ID for QA topic |
| `TOPIC_AI_ML` | Thread ID for AI/ML topic |
| `TOPIC_CYBERSECURITY` | Thread ID for Cybersecurity topic |
| `TOPIC_GAMEDEV` | Thread ID for Game Dev topic |
| `TOPIC_BLOCKCHAIN` | Thread ID for Blockchain topic |
| `TOPIC_EGYPT` | Thread ID for Egypt Jobs topic |
| `TOPIC_SAUDI` | Thread ID for Saudi Jobs topic |
| `TOPIC_INTERNSHIPS` | Thread ID for Internships topic |
| `TOPIC_ERP` | Thread ID for ERP topic |

**API Keys (optional):**
`RAPIDAPI_KEY`, `ADZUNA_APP_ID`, `ADZUNA_APP_KEY`, `FINDWORK_API_KEY`, `JOOBLE_API_KEY`, `REED_API_KEY`

Topics without a secret are skipped — you can start with a few and add more later.

### 6. Initialize & Run

```bash
# Create data branch for job tracking
git checkout --orphan data
echo '[]' > seen_jobs.json
git add seen_jobs.json
git commit -m "Init seen_jobs"
git push origin data
git checkout main
```

Go to **Actions → Programming Jobs Bot → Run workflow**.
- First run = **seed mode** (registers existing jobs, sends nothing)
- Second run onwards = **sends only new jobs** every 5 minutes

## 📁 Project Structure

```
├── main.py                 # Entry point — orchestrates everything
├── config.py               # 253 keywords, 14 topics, geo patterns, settings
├── models.py               # Job dataclass + keyword & geo filtering
├── dedup.py                # Deduplication with seen_jobs.json
├── telegram_sender.py      # Multi-topic routing + Telegram API
├── requirements.txt        # requests>=2.31.0
├── sources/
│   ├── __init__.py         # ALL_FETCHERS registry (15 sources)
│   ├── http_utils.py       # Shared HTTP helpers
│   ├── remotive.py         # Remotive API
│   ├── himalayas.py        # Himalayas API
│   ├── jobicy.py           # Jobicy API
│   ├── remoteok.py         # RemoteOK JSON Feed
│   ├── arbeitnow.py        # Arbeitnow API
│   ├── wwr.py              # We Work Remotely RSS (5 feeds)
│   ├── workingnomads.py    # Working Nomads API/RSS
│   ├── jsearch.py          # JSearch/RapidAPI
│   ├── linkedin.py         # LinkedIn Guest API
│   ├── adzuna.py           # Adzuna API
│   ├── themuse.py          # The Muse API
│   ├── findwork.py         # Findwork.dev API
│   ├── jooble.py           # Jooble API
│   ├── reed.py             # Reed.co.uk API
│   └── usajobs.py          # USAJobs API
└── .github/workflows/
    └── job_bot.yml         # GitHub Actions cron (every 5 min)
```

## ⚙️ How It Works

```
Every 5 minutes:
  1. Fetch jobs from all 15 sources
  2. Filter by keywords (253 include / 54 exclude)
  3. Apply geo-filter (Egypt/Saudi = all, others = remote only)
  4. Compare with seen_jobs.json → find new jobs only
  5. Route each job to matching topic(s)
  6. Send to Telegram community
  7. Save updated seen_jobs.json
```

## 🔧 Customization

**Add a new topic:** Edit `CHANNELS` in `config.py` — add a new entry with `thread_env`, `name`, and `keywords`.

**Add keywords:** Edit `INCLUDE_KEYWORDS` or `EXCLUDE_KEYWORDS` in `config.py`.

**Add a new source:** Create a new file in `sources/`, add a `fetch_xxx()` function that returns `list[Job]`, and register it in `sources/__init__.py`.

**Change cron schedule:** Edit the `cron` line in `.github/workflows/job_bot.yml`.

## 🧪 Local Testing

```bash
export TELEGRAM_BOT_TOKEN="your_token"
export TELEGRAM_GROUP_ID="-100xxxxxxxxxx"
export TOPIC_GENERAL="1"
export TOPIC_BACKEND="2"
# ... other topics
export RAPIDAPI_KEY="your_key"

python main.py
```

## 📝 License

MIT
