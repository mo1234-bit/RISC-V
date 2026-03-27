"""
Configuration for Programming Jobs Telegram Bot.
Keywords, geo-filtering rules, and settings.
"""

import os

# ─── Telegram ───────────────────────────────────────────────
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_GROUP_ID = os.getenv("TELEGRAM_GROUP_ID", "")  # The supergroup chat ID
TELEGRAM_SEND_DELAY = 3  # seconds between messages

# ─── Community Topics ───────────────────────────────────────
# Each topic has: thread_id (from the topic link) + keywords for routing
# A job can go to MULTIPLE topics (e.g. "Flutter Dev in Egypt" → Mobile + Egypt)
# thread_id comes from the topic link: t.me/TechJobs0/2 → thread_id = 2
#
# Set thread IDs via env vars so you don't need to edit code.
# General topic uses thread_id from env, or falls back to None (sends to main chat).

CHANNELS = {
    "general": {
        "thread_env": "TOPIC_GENERAL",
        "name": "💻 All Jobs",
        "match": "ALL",
    },
    "backend": {
        "thread_env": "TOPIC_BACKEND",
        "name": "⚙️ Backend",
        "keywords": [
            "backend", "back-end", "back end", "server-side", "server side",
            "api developer", "api engineer",
            "full-stack", "full stack", "fullstack",
            "python developer", "python engineer",
            "java developer", "java engineer",
            "golang", "go developer", "go engineer",
            "rust developer", "rust engineer",
            "ruby developer", "rails developer",
            "php developer", "php engineer",
            "node.js developer", "nodejs developer", "node developer",
            "django", "flask", "fastapi", "spring", "laravel", "express",
            ".net developer", "dotnet developer", "c# developer",
        ],
    },
    "frontend": {
        "thread_env": "TOPIC_FRONTEND",
        "name": "🎨 Frontend",
        "keywords": [
            "frontend", "front-end", "front end",
            "ui developer", "ui engineer",
            "full-stack", "full stack", "fullstack",
            "react developer", "react engineer", "next.js",
            "angular developer", "vue developer", "vue.js",
            "javascript developer", "js developer",
            "typescript developer", "ts developer",
            "css", "tailwind", "svelte",
            "web developer", "web engineer",
        ],
    },
    "mobile": {
        "thread_env": "TOPIC_MOBILE",
        "name": "📱 Mobile",
        "keywords": [
            "mobile developer", "mobile engineer", "mobile application",
            "ios developer", "ios engineer",
            "android developer", "android engineer",
            "flutter developer", "flutter engineer", "flutter",
            "react native developer", "react native engineer", "react native",
            "swift developer", "kotlin developer",
            "mobile app developer", "app developer",
            "swiftui", "jetpack compose", "dart developer",
        ],
    },
    "devops": {
        "thread_env": "TOPIC_DEVOPS",
        "name": "🚀 DevOps & Cloud",
        "keywords": [
            "devops", "dev ops", "dev-ops",
            "sre", "site reliability",
            "cloud engineer", "cloud developer", "cloud architect",
            "infrastructure engineer", "platform engineer",
            "kubernetes", "docker", "terraform", "ansible",
            "aws engineer", "azure engineer", "gcp engineer",
            "ci/cd", "jenkins", "github actions",
            "linux engineer", "systems engineer", "systems administrator",
            "network engineer", "network administrator",
        ],
    },
    "qa": {
        "thread_env": "TOPIC_QA",
        "name": "🧪 QA & Testing",
        "keywords": [
            "qa engineer", "qa developer", "quality assurance",
            "test engineer", "sdet", "software tester",
            "automation engineer", "test automation",
            "qa analyst", "qa lead", "qa manager",
            "selenium", "cypress", "playwright",
            "manual testing", "performance testing",
            "load testing", "stress testing",
        ],
    },
    "ai_ml": {
        "thread_env": "TOPIC_AI_ML",
        "name": "🤖 AI/ML & Data Science",
        "keywords": [
            "machine learning", "ml engineer", "ml developer",
            "ai engineer", "ai developer", "artificial intelligence",
            "deep learning", "nlp engineer", "computer vision",
            "data scientist", "data science",
            "data analyst", "data analytics",
            "data engineer", "etl developer", "data pipeline",
            "big data", "hadoop", "spark engineer",
            "llm", "generative ai", "prompt engineer",
            "tensorflow", "pytorch", "hugging face",
        ],
    },
    "cybersecurity": {
        "thread_env": "TOPIC_CYBERSECURITY",
        "name": "🔒 Cybersecurity",
        "keywords": [
            "security engineer", "appsec", "application security",
            "cybersecurity", "cyber security", "infosec",
            "penetration tester", "pen tester", "security analyst",
            "soc analyst", "security architect",
            "vulnerability", "ethical hacker",
            "security operations", "threat",
        ],
    },
    "gamedev": {
        "thread_env": "TOPIC_GAMEDEV",
        "name": "🎮 Game Development",
        "keywords": [
            "game developer", "game engineer", "game programmer",
            "unity developer", "unreal developer",
            "game designer", "gameplay programmer",
            "game studio", "gaming",
            "godot", "cocos2d",
        ],
    },
    "blockchain": {
        "thread_env": "TOPIC_BLOCKCHAIN",
        "name": "⛓️ Blockchain & Web3",
        "keywords": [
            "blockchain developer", "blockchain engineer",
            "smart contract", "solidity developer", "solidity",
            "web3 developer", "web3 engineer", "web3",
            "crypto developer", "defi", "nft",
            "ethereum", "solana developer",
        ],
    },
    "egypt": {
        "thread_env": "TOPIC_EGYPT",
        "name": "🇪🇬 Egypt Jobs",
        "match": "GEO_EGYPT",
    },
    "saudi": {
        "thread_env": "TOPIC_SAUDI",
        "name": "🇸🇦 Saudi Jobs",
        "match": "GEO_SAUDI",
    },
    "internships": {
        "thread_env": "TOPIC_INTERNSHIPS",
        "name": "🎓 Internships",
        "keywords": [
            "intern", "internship", "trainee", "training program",
            "graduate program", "junior", "entry level", "entry-level",
            "fresh graduate", "fresh grad", "co-op",
            "apprentice", "apprenticeship",
            "working student", "student developer",
        ],
    },
    "erp": {
        "thread_env": "TOPIC_ERP",
        "name": "🏢 ERP & Accounting",
        "keywords": [
            "erp developer", "erp consultant", "erp engineer", "erp implementation",
            "odoo developer", "odoo engineer", "odoo consultant", "odoo implementation",
            "sap developer", "sap consultant", "sap engineer", "sap abap",
            "sap fiori", "sap hana", "sap basis", "sap functional",
            "salesforce developer", "salesforce engineer", "salesforce admin",
            "salesforce consultant",
            "dynamics developer", "dynamics consultant", "dynamics 365",
            "oracle ebs", "oracle apps", "oracle financials",
            "netsuite developer", "netsuite consultant", "netsuite admin",
            "quickbooks developer",
            "accounting software", "financial software",
            "crm developer", "crm consultant",
        ],
    },
}


def get_topic_thread_id(channel_key: str) -> int | None:
    """Get the topic thread_id from environment variable."""
    ch = CHANNELS.get(channel_key, {})
    env_var = ch.get("thread_env", "")
    val = os.getenv(env_var, "")
    if val:
        try:
            return int(val)
        except ValueError:
            return None
    return None
TELEGRAM_SEND_DELAY = 3  # seconds between messages

# ─── API Keys ───────────────────────────────────────────────
RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "")
ADZUNA_APP_ID = os.getenv("ADZUNA_APP_ID", "")
ADZUNA_APP_KEY = os.getenv("ADZUNA_APP_KEY", "")
FINDWORK_API_KEY = os.getenv("FINDWORK_API_KEY", "")
JOOBLE_API_KEY = os.getenv("JOOBLE_API_KEY", "")
REED_API_KEY = os.getenv("REED_API_KEY", "")
MUSE_API_KEY = os.getenv("MUSE_API_KEY", "")

# ─── Geo-filtering ──────────────────────────────────────────
# Jobs in these countries pass regardless of remote/onsite
ALLOWED_ONSITE_COUNTRIES = {"egypt", "مصر", "saudi arabia", "saudi", "ksa", "السعودية"}

# Patterns that indicate a location is in Egypt
EGYPT_PATTERNS = {
    "egypt", "مصر", "cairo", "القاهرة", "alexandria", "الإسكندرية",
    "giza", "الجيزة", "minya", "المنيا", "mansoura", "المنصورة",
    "tanta", "طنطا", "aswan", "أسوان", "luxor", "الأقصر",
    "port said", "بورسعيد", "suez", "السويس", "ismailia", "الإسماعيلية",
    "fayoum", "الفيوم", "zagazig", "الزقازيق", "damanhur", "دمنهور",
    "beni suef", "بني سويف", "sohag", "سوهاج", "asyut", "أسيوط",
    "qena", "قنا", "hurghada", "الغردقة", "sharm el sheikh",
    "new cairo", "6th of october", "6 october", "smart village",
    "new capital", "العاصمة الإدارية", "nasr city", "مدينة نصر",
    "maadi", "المعادي", "heliopolis", "مصر الجديدة", "dokki", "الدقي",
    "mohandessin", "المهندسين",
}

# Patterns that indicate a location is in Saudi Arabia
SAUDI_PATTERNS = {
    "saudi arabia", "saudi", "ksa", "السعودية", "المملكة العربية السعودية",
    "riyadh", "الرياض", "jeddah", "جدة", "mecca", "مكة",
    "medina", "المدينة", "dammam", "الدمام", "khobar", "الخبر",
    "dhahran", "الظهران", "tabuk", "تبوك", "abha", "أبها",
    "taif", "الطائف", "jubail", "الجبيل", "yanbu", "ينبع",
    "neom", "نيوم", "qassim", "القصيم", "hail", "حائل",
    "jazan", "جازان", "najran", "نجران", "al kharj", "الخرج",
}

# Patterns that indicate a job is remote
REMOTE_PATTERNS = {
    "remote", "anywhere", "worldwide", "work from home", "wfh",
    "distributed", "global", "fully remote", "100% remote",
    "remote-friendly", "location independent", "عن بعد",
}

# ─── Job Keywords ────────────────────────────────────────────
# Job MUST contain at least one of these (case-insensitive, checked in title + tags)
INCLUDE_KEYWORDS = [
    # Software Engineering
    "software engineer", "software developer", "software development",
    "swe", "sde",
    # Backend
    "backend", "back-end", "back end",
    "server-side", "server side",
    "api developer", "api engineer",
    # Frontend
    "frontend", "front-end", "front end",
    "ui developer", "ui engineer",
    # Full-Stack
    "full-stack", "full stack", "fullstack",
    # DevOps / SRE / Cloud / Infra
    "devops", "dev ops", "dev-ops",
    "sre", "site reliability",
    "cloud engineer", "cloud developer", "cloud architect",
    "infrastructure engineer", "platform engineer",
    "kubernetes", "docker", "terraform",
    "aws engineer", "azure engineer", "gcp engineer",
    # QA / Testing
    "qa engineer", "qa developer", "quality assurance",
    "test engineer", "sdet", "software tester",
    "automation engineer", "test automation",
    "qa analyst", "qa lead", "qa manager",
    # Mobile — expanded
    "mobile developer", "mobile engineer", "mobile application",
    "ios developer", "ios engineer",
    "android developer", "android engineer",
    "flutter developer", "flutter engineer", "flutter",
    "react native developer", "react native engineer", "react native",
    "swift developer", "kotlin developer",
    "mobile app developer", "app developer",
    # Web Development
    "web developer", "web engineer", "webmaster",
    # AI / ML / Data Science
    "machine learning", "ml engineer", "ml developer",
    "ai engineer", "ai developer", "artificial intelligence",
    "deep learning", "nlp engineer", "computer vision",
    "data scientist", "data science",
    "data analyst", "data analytics",
    "data engineer", "etl developer", "data pipeline",
    "big data", "hadoop", "spark engineer",
    # Cybersecurity
    "security engineer", "appsec", "application security",
    "cybersecurity", "cyber security", "infosec",
    "penetration tester", "pen tester", "security analyst",
    "soc analyst", "security architect",
    # Database
    "database administrator", "dba",
    "database developer", "database engineer",
    "sql developer", "postgresql", "mongodb",
    # Blockchain / Web3
    "blockchain developer", "blockchain engineer",
    "smart contract", "solidity developer",
    "web3 developer", "web3 engineer",
    "crypto developer",
    # Game Development
    "game developer", "game engineer", "game programmer",
    "unity developer", "unreal developer",
    "game designer",  # programming-focused game design
    # Embedded / IoT
    "embedded developer", "embedded engineer", "embedded software",
    "iot developer", "iot engineer",
    "firmware developer", "firmware engineer",
    # Systems / Low-level
    "systems engineer", "systems developer",
    "systems programmer", "kernel developer",
    "linux engineer", "os developer",
    # ERP / CRM
    "salesforce developer", "sap developer", "sap engineer",
    "erp developer", "crm developer",
    "dynamics developer", "odoo developer",
    # Networking
    "network engineer", "network administrator",
    "network architect",
    # Programming Languages (as job titles)
    "python developer", "python engineer",
    "java developer", "java engineer",
    "javascript developer", "js developer",
    "typescript developer", "ts developer",
    "golang developer", "go developer", "go engineer",
    "rust developer", "rust engineer",
    "ruby developer", "ruby engineer", "rails developer",
    "php developer", "php engineer",
    "c# developer", ".net developer", "dotnet developer",
    "c++ developer", "cpp developer",
    "scala developer", "elixir developer",
    "perl developer", "r developer",
    # Frameworks (as job titles)
    "node.js developer", "nodejs developer", "node developer",
    "react developer", "react engineer", "next.js developer",
    "angular developer", "vue developer", "vue.js developer",
    "django developer", "flask developer", "fastapi",
    "spring developer", "spring boot",
    "laravel developer", "symfony developer",
    "express.js developer",
    # CMS / WordPress
    "wordpress developer", "shopify developer",
    "drupal developer", "magento developer",
    # Technical Leadership
    "tech lead", "technical lead", "engineering manager",
    "cto", "vp engineering", "head of engineering",
    "principal engineer", "staff engineer", "architect",
    # Teaching / Tutoring
    "coding instructor", "programming instructor",
    "coding tutor", "programming tutor",
    "coding teacher", "programming teacher",
    "bootcamp instructor", "technical instructor",
    "computer science instructor", "cs instructor",
    "technical trainer", "coding mentor",
    # ERP / CRM / Accounting
    "erp developer", "erp consultant", "erp engineer",
    "odoo developer", "odoo engineer", "odoo consultant", "odoo",
    "sap developer", "sap consultant", "sap engineer",
    "sap abap", "sap fiori", "sap hana", "sap basis",
    "salesforce developer", "salesforce engineer", "salesforce admin",
    "dynamics developer", "dynamics 365", "dynamics consultant",
    "oracle developer", "oracle ebs", "oracle apps", "oracle dba",
    "netsuite developer", "netsuite consultant",
    "quickbooks developer",
    "crm developer", "crm engineer",
    "accounting software", "financial software",
    # Internships / Entry Level
    "intern", "internship", "trainee",
    "graduate program", "training program",
    "co-op", "apprentice", "apprenticeship",
    "working student", "student developer",
    # General (broad catch — filtered by EXCLUDE)
    "programmer", "developer", "engineer",
]

# Job is EXCLUDED if it contains any of these (case-insensitive)
EXCLUDE_KEYWORDS = [
    # Non-programming roles
    "graphic design", "ui/ux design", "ux design", "ux researcher",
    "product design", "visual design", "brand design", "interior design",
    "marketing", "sales", "account manager", "account executive",
    "recruiter", "talent acquisition", "hr manager", "human resources",
    "customer support", "customer service", "customer success",
    "content writer", "copywriter",
    "project manager", "program manager", "scrum master",
    "product manager", "product owner",
    "business analyst", "business development",
    "financial analyst", "accountant", "bookkeeper",
    "office manager", "administrative",
    "data entry", "virtual assistant",
    "social media manager", "community manager",
    "supply chain", "logistics",
    # Hardware / Non-software engineering
    "mechanical engineer", "electrical engineer", "civil engineer",
    "chemical engineer", "structural engineer",
    "hardware engineer", "pcb",
    # Medical / Other
    "medical coder", "billing coder", "clinical",
    "nurse", "physician", "pharmacist",
    "dental", "veterinary",
]

# ─── Emoji Map ───────────────────────────────────────────────
# Maps keywords in job title/tags to emoji
EMOJI_MAP = {
    "backend": "⚙️",
    "back-end": "⚙️",
    "frontend": "🎨",
    "front-end": "🎨",
    "full-stack": "🔄",
    "fullstack": "🔄",
    "devops": "🚀",
    "sre": "🚀",
    "cloud": "☁️",
    "aws": "☁️",
    "azure": "☁️",
    "qa": "🧪",
    "test": "🧪",
    "quality": "🧪",
    "mobile": "📱",
    "ios": "🍎",
    "android": "🤖",
    "flutter": "🦋",
    "react native": "📱",
    "python": "🐍",
    "java": "☕",
    "javascript": "🟨",
    "typescript": "🔷",
    "react": "⚛️",
    "node": "🟩",
    "golang": "🐹",
    "rust": "🦀",
    "ruby": "💎",
    "php": "🐘",
    ".net": "🟣",
    "c#": "🟣",
    "c++": "🔵",
    "swift": "🍎",
    "kotlin": "🟠",
    "data engineer": "📊",
    "data scien": "📊",
    "machine learning": "🤖",
    "ml ": "🤖",
    "ai ": "🤖",
    "artificial intel": "🤖",
    "deep learning": "🧠",
    "blockchain": "⛓️",
    "web3": "⛓️",
    "solidity": "⛓️",
    "game dev": "🎮",
    "unity": "🎮",
    "unreal": "🎮",
    "security": "🔒",
    "cyber": "🔒",
    "penetration": "🔒",
    "embedded": "🔌",
    "iot": "🔌",
    "firmware": "🔌",
    "database": "🗄️",
    "dba": "🗄️",
    "sql": "🗄️",
    "wordpress": "📝",
    "shopify": "🛒",
    "salesforce": "☁️",
    "sap": "🏢",
    "network": "🌐",
    "instructor": "📚",
    "tutor": "📚",
    "teacher": "📚",
    "mentor": "📚",
    "senior": "👨‍💻",
    "junior": "🌱",
    "lead": "⭐",
    "principal": "⭐",
    "staff": "⭐",
    "intern": "🎓",
    "architect": "🏗️",
    "erp": "🏢",
    "odoo": "🏢",
    "sap": "🏢",
    "salesforce": "☁️",
    "dynamics": "🏢",
    "oracle": "🏢",
    "netsuite": "🏢",
    "accounting": "🏢",
    "remote": "🌍",
    "egypt": "🇪🇬",
    "مصر": "🇪🇬",
    "cairo": "🇪🇬",
    "saudi": "🇸🇦",
    "riyadh": "🇸🇦",
    "jeddah": "🇸🇦",
}

# Default emoji if no match
DEFAULT_EMOJI = "💻"

# ─── Source Display Names ────────────────────────────────────
SOURCE_DISPLAY = {
    "remotive": "Remotive",
    "himalayas": "Himalayas",
    "jobicy": "Jobicy",
    "remoteok": "RemoteOK",
    "arbeitnow": "Arbeitnow",
    "wwr": "We Work Remotely",
    "workingnomads": "Working Nomads",
    "jsearch": None,  # Uses original source (LinkedIn, Indeed, etc.)
    "linkedin": "LinkedIn",
    "adzuna": "Adzuna",
    "themuse": "The Muse",
    "findwork": "Findwork",
    "jooble": "Jooble",
    "reed": "Reed",
    "careerjet": "Careerjet",
    "usajobs": "USAJobs",
}

# ─── Misc ────────────────────────────────────────────────────
SEEN_JOBS_FILE = "seen_jobs.json"
MAX_JOBS_PER_RUN = 50   # safety cap per run
REQUEST_TIMEOUT = 15     # seconds
SEED_MODE_ENV = "SEED_MODE"  # env var to force seed mode
