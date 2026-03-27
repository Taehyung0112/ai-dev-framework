"""
週報自動填寫腳本
-----------------
用法:
  python weekly_report.py              # 乾跑模式（只印出不送出）
  python weekly_report.py --submit     # 真正送出到 NocoDB
  python weekly_report.py --submit --force  # 刪除既有記錄並重建

【首次使用前請設定以下環境變數】

  必填:
    ANTHROPIC_API_KEY   你的 Claude API Key（用於智慧摘要 commit）
    NOCODB_PEOPLE_ID    你在工作日誌系統的員工 ID（整數，向管理員確認）
    GIT_REPOS           你的 git repo 路徑，多個用分號分隔
                        例: C:/Users/yourname/incubator

  選填:
    NOCODB_XC_TOKEN     NocoDB API token（預設使用共享 token，輪換時才需設定）

  ── 什麼是 NOCODB_PEOPLE_ID？ ──────────────────────────────────────────
  工作日誌的「回報人」欄位需要對應你在系統裡的員工 ID。
  執行以下指令查詢（需要先設定 NOCODB_XC_TOKEN 或使用預設值）：

    python weekly_report.py --list-people

  ────────────────────────────────────────────────────────────────────────
"""

import sys
import io
import os
import json
import subprocess
import ssl
import urllib.request
import urllib.parse
import re
from datetime import date, timedelta
from typing import Optional

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

# ─── CONFIG ─────────────────────────────────────────────────────────────────
NOCODB_BASE = "https://ptii-test.concords.com.tw:20012"
XC_TOKEN    = os.environ.get("NOCODB_XC_TOKEN", "60ltJ2FtFq-SwG4FxlGxCKVIuaT__Wpo-YJWLpqz")
TABLE_WORK  = "m34tdo4qg7lz1kd"   # 工作項目表

_people_id_env = os.environ.get("NOCODB_PEOPLE_ID", "")
PEOPLE_ID = int(_people_id_env) if _people_id_env else 0

# GIT_REPOS 必填：每個人本機 repo 路徑不同，不提供預設值
_repos_env = os.environ.get("GIT_REPOS", "")
DEFAULT_REPOS: list[str] = [r.strip() for r in _repos_env.split(";") if r.strip()]

DRY_RUN = "--submit" not in sys.argv
FORCE   = "--force"  in sys.argv

# Noise commit patterns — bare words with no meaningful scope
_NOISE_PATTERNS = re.compile(
    r'^(fix|test|wip|tmp|temp|debug|log|update|misc|chore|format files?'
    r'|delete \S+|remove \S+|add \S+|fix log|fix test|update sonar\S*'
    r'|change sonarqube\S*|format \S+|update sonar \S+|update sonar$'
    r'|\d+|\.+)$',
    re.IGNORECASE,
)

# ─── DATE UTILS ─────────────────────────────────────────────────────────────

def get_week_range() -> tuple[date, date]:
    """Return (monday, sunday) for the current week."""
    today   = date.today()
    monday  = today - timedelta(days=today.weekday())
    sunday  = monday + timedelta(days=6)
    return monday, sunday

def format_week_period(monday: date, sunday: date) -> str:
    return f"{monday.isoformat()}~{sunday.isoformat()}"

# ─── GIT ────────────────────────────────────────────────────────────────────

def run_git(args: list[str], cwd: str) -> str:
    try:
        result = subprocess.run(
            ["git"] + args, cwd=cwd, capture_output=True, timeout=15,
            encoding="utf-8", errors="replace",
        )
        return result.stdout.strip()
    except Exception as e:
        return f"[git error: {e}]"

def is_noise_commit(subject: str) -> bool:
    """Return True for commit messages that carry no meaningful information."""
    return bool(_NOISE_PATTERNS.match(subject.strip()))

def collect_commits(repo: str, since: date, until: date) -> list[dict]:
    """Collect all non-noise commits (including local-only) in the date range."""
    since_str = since.isoformat()
    until_str = (until + timedelta(days=1)).isoformat()  # exclusive end

    log_all = run_git([
        "log", "--all",
        f"--since={since_str}", f"--until={until_str}",
        "--no-merges",
        "--pretty=format:%H|%ai|%s",
    ], repo)

    log_local_only = run_git([
        "log", "--branches", "--not", "--remotes",
        f"--since={since_str}", f"--until={until_str}",
        "--no-merges",
        "--pretty=format:%H",
    ], repo)
    local_only_hashes = set(log_local_only.splitlines()) if log_local_only else set()

    commits: list[dict] = []
    seen: set[str]      = set()

    for line in log_all.splitlines():
        if not line.strip():
            continue
        parts = line.split("|", 2)
        if len(parts) < 3:
            continue
        hash_, date_str, subject = parts[0], parts[1], parts[2]
        if hash_ in seen:
            continue
        seen.add(hash_)
        if is_noise_commit(subject):
            continue
        commits.append({
            "hash":          hash_[:8],
            "date":          date_str[:10],
            "subject":       subject,
            "is_local_only": hash_ in local_only_hashes,
        })

    return commits

# ─── SUMMARIZE ──────────────────────────────────────────────────────────────

def classify_commit_scope(subject: str) -> str:
    """Extract service scope from commit — only when em dash (—) is present."""
    m = re.match(r'^[A-Z]+:\s+([^—]+?)\s+—\s+', subject)
    return m.group(1).strip().lower() if m else ""

def group_commits_by_service(commits: list[dict]) -> dict[str, list[dict]]:
    """Group commits into service buckets (max 5 + 其他)."""
    BUCKETS: dict[str, list[str]] = {
        "freqtrade-sdk":    ["freqtrade-sdk", "freqtrade_sdk"],
        "ai-dev-framework": ["ai-dev-framework", "framework"],
        "order-hub":        ["order-hub", "order_hub", "order hub"],
        "order-gateway":    ["order-gateway", "order_gateway"],
        "ci/pipeline":      ["sonarqube", "sonar", "vcpkg", "cmake", "vitest",
                             "unit_test", "CI:"],
    }

    groups: dict[str, list[dict]] = {k: [] for k in BUCKETS}
    groups["其他"] = []

    for c in commits:
        scope     = classify_commit_scope(c["subject"])
        full_text = (scope + " " + c["subject"]).lower()
        placed    = False
        for bucket, keywords in BUCKETS.items():
            if any(kw.lower() in full_text for kw in keywords):
                groups[bucket].append(c)
                placed = True
                break
        if not placed:
            groups["其他"].append(c)

    return {k: v for k, v in groups.items() if v}

def build_work_items_simple(commits: list[dict], period: str) -> list[dict]:
    """Rule-based work items grouped by service (fallback when Claude unavailable)."""
    if not commits:
        return []

    groups = group_commits_by_service(commits)
    BUCKET_META: dict[str, tuple[str, str]] = {
        "freqtrade-sdk":    ("專案開發", "freqtrade-sdk Python SDK 開發"),
        "ai-dev-framework": ("專案開發", "AI Dev Framework 維護與升級"),
        "order-hub":        ("專案開發", "Order Hub SDK 開發"),
        "order-gateway":    ("專案開發", "Order Gateway 開發"),
        "ci/pipeline":      ("例行維運", "CI/CD Pipeline 維護與 SonarQube 設定"),
        "其他":              ("專案開發", "其他開發工作"),
    }

    items: list[dict] = []
    for bucket, cs in groups.items():
        subjects      = list(dict.fromkeys(c["subject"] for c in cs))
        content_lines = [f"- {s}" for s in subjects[:20]]
        local_count   = sum(1 for c in cs if c["is_local_only"])
        if local_count:
            content_lines.append(f"\n（含 {local_count} 個尚未推送的本地 commit）")

        work_type, label = BUCKET_META.get(bucket, ("專案開發", f"{bucket} 開發"))
        items.append(_make_item(period, work_type, label, "\n".join(content_lines)))

    return items

def build_work_items_claude(commits: list[dict], period: str) -> list[dict]:
    """Use Claude haiku to produce intelligent work item summaries."""
    try:
        import anthropic
        import httpx
    except ImportError:
        print("[WARN] anthropic/httpx not installed — falling back to simple mode")
        return build_work_items_simple(commits, period)

    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key:
        print("[WARN] ANTHROPIC_API_KEY not set — falling back to simple mode")
        return build_work_items_simple(commits, period)

    commit_log = "\n".join(
        f"[{'LOCAL-ONLY' if c['is_local_only'] else c['date']}] {c['subject']}"
        for c in commits
    )

    prompt = f"""你是一位工程師，需要根據以下這週的 git commit 記錄，整理出 1~5 條工作項目，填入公司內部週報系統。

Git commit 記錄 (本週 {period}):
{commit_log}

請輸出 JSON 陣列，每個元素代表一個工作項目，格式如下:
{{
  "工作類型": "專案開發" | "例行維運",
  "工作名稱": "簡短標題（不超過 50 字）",
  "工作內容": "詳細說明（條列本週實際完成內容，使用 - 開頭）",
  "流程階段": "開發中" | "已完成" | "待處理",
  "負載狀態": "進行中" | "已完成" | "未開始"
}}

規則:
- 相關 commit 合併成一條工作項目（同一服務/模組）
- LOCAL-ONLY 的 commit 代表尚未推送，一樣要納入
- 只輸出 JSON 陣列，不要其他說明文字"""

    try:
        client = anthropic.Anthropic(
            api_key=api_key,
            http_client=httpx.Client(verify=False),
        )
        response = client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=1500,
            messages=[{"role": "user", "content": prompt}],
        )
        raw = response.content[0].text.strip()
        m   = re.search(r'\[.*\]', raw, re.DOTALL)
        parsed: list[dict] = json.loads(m.group() if m else raw)

        return [
            _make_item(
                period,
                p.get("工作類型", "專案開發"),
                p.get("工作名稱",  "未命名"),
                p.get("工作內容",  ""),
                p.get("流程階段", "開發中"),
                p.get("負載狀態", "進行中"),
            )
            for p in parsed
        ]
    except Exception as e:
        print(f"[WARN] Claude API failed: {e} — falling back to simple mode")
        return build_work_items_simple(commits, period)

def _make_item(
    period: str, work_type: str, name: str, content: str,
    stage: str = "開發中", status: str = "進行中",
) -> dict:
    return {
        "回報週別":  period,
        "回報人":   [{"Id": PEOPLE_ID}],
        "工作類型": work_type,
        "工作名稱": name,
        "工作內容": content,
        "流程階段": stage,
        "負載狀態": status,
        "開始時間":  None,
        "預計完成日": None,
        "關聯系統": [],
        "關聯專案": [],
    }

# ─── NOCODB API ─────────────────────────────────────────────────────────────

def _ssl_ctx() -> ssl.SSLContext:
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode    = ssl.CERT_NONE
    return ctx

def _headers() -> dict:
    return {"xc-token": XC_TOKEN, "Content-Type": "application/json"}

def nocodb_get(path: str, qs: Optional[dict] = None) -> dict:
    url = NOCODB_BASE + path
    if qs:
        url += "?" + urllib.parse.urlencode({k: v for k, v in qs.items() if v is not None})
    req = urllib.request.Request(url, headers={"xc-token": XC_TOKEN})
    with urllib.request.urlopen(req, context=_ssl_ctx()) as resp:
        return json.loads(resp.read())

def nocodb_post(path: str, body: dict) -> dict:
    data = json.dumps(body).encode("utf-8")
    req  = urllib.request.Request(
        NOCODB_BASE + path, data=data, method="POST", headers=_headers()
    )
    with urllib.request.urlopen(req, context=_ssl_ctx()) as resp:
        return json.loads(resp.read())

def nocodb_delete(path: str, body: list) -> None:
    data = json.dumps(body).encode("utf-8")
    req  = urllib.request.Request(
        NOCODB_BASE + path, data=data, method="DELETE", headers=_headers()
    )
    with urllib.request.urlopen(req, context=_ssl_ctx()):
        pass

def get_existing_items(period: str) -> list[dict]:
    data = nocodb_get(
        f"/api/v2/tables/{TABLE_WORK}/records",
        {"where": f"(nc_j4sy__People_id,eq,{PEOPLE_ID})~and(回報週別,eq,{period})",
         "limit": "50"},
    )
    return data.get("list", [])

def delete_existing_items(items: list[dict]) -> None:
    ids = [{"Id": item["Id"]} for item in items]
    nocodb_delete(f"/api/v2/tables/{TABLE_WORK}/records", ids)

def create_work_item(item: dict) -> dict:
    return nocodb_post(f"/api/v2/tables/{TABLE_WORK}/records", item)

# ─── MAIN ────────────────────────────────────────────────────────────────────

def list_people() -> None:
    """印出所有 People 記錄，讓使用者找自己的 NOCODB_PEOPLE_ID。"""
    data = nocodb_get("/api/v2/tables/m1x6jugvhwgqvyb/records", {"limit": "100"})
    print("\n員工列表（設定 NOCODB_PEOPLE_ID=<你的 Id>）:\n")
    for p in data.get("list", []):
        print(f"  Id={p['Id']:4d}  {p.get('Name', p.get('姓名', '?'))}")
    print()


def validate_config() -> bool:
    """啟動前驗證必要設定，回傳 False 表示有錯誤。"""
    ok = True
    if not PEOPLE_ID:
        print("[ERROR] NOCODB_PEOPLE_ID 未設定")
        print("        執行: python weekly_report.py --list-people  查詢你的 Id")
        print("        設定: export NOCODB_PEOPLE_ID=<你的 Id>")
        ok = False
    if not DEFAULT_REPOS:
        print("[ERROR] GIT_REPOS 未設定")
        print("        設定: export GIT_REPOS=C:/path/to/your/repo")
        ok = False
    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("[WARN]  ANTHROPIC_API_KEY 未設定，將使用規則分組（無 Claude 摘要）")
    return ok


def main() -> None:
    if "--list-people" in sys.argv:
        list_people()
        return

    monday, sunday = get_week_range()
    period         = format_week_period(monday, sunday)

    if not validate_config():
        sys.exit(1)

    print(f"{'=' * 62}")
    print(f"  週報自動填寫 — {period}")
    mode = "乾跑（不送出）" if DRY_RUN else ("強制重建" if FORCE else "送出")
    print(f"  模式: {mode}  |  People ID: {PEOPLE_ID}")
    print(f"{'=' * 62}\n")

    # 1. Collect commits
    repos            = DEFAULT_REPOS
    all_commits: list[dict] = []

    for repo in repos:
        if not os.path.exists(repo):
            print(f"[SKIP] Repo not found: {repo}")
            continue
        commits = collect_commits(repo, monday, sunday)
        local_n = sum(1 for c in commits if c["is_local_only"])
        print(f"[GIT] {repo}")
        print(f"  {len(commits)} commits ({local_n} local-only)\n")
        for c in commits:
            flag = " [LOCAL]" if c["is_local_only"] else ""
            print(f"  {c['date']} {c['hash']}  {c['subject'][:72]}{flag}")
        all_commits.extend(commits)

    print(f"\n[TOTAL] {len(all_commits)} meaningful commits across {len(repos)} repo(s)")

    # 2. Check existing items
    print(f"\n[CHECK] Existing items for {period}...")
    existing = get_existing_items(period)

    if existing and not FORCE:
        print(f"  Found {len(existing)} existing item(s):")
        for e in existing:
            print(f"    [{e['Id']}] {e.get('工作名稱', '?')}")
        print("\n  Already submitted. Use --force to delete and re-create.\n")
        return

    if existing and FORCE:
        print(f"  --force: deleting {len(existing)} existing item(s)...")
        delete_existing_items(existing)
        print("  Deleted.\n")

    # 3. Build work items
    if not all_commits:
        print("\n[INFO] No commits — creating placeholder item.")
        items = [_make_item(period, "例行維運", "本週例行工作", "本週例行系統維護與開發工作。")]
    elif os.environ.get("ANTHROPIC_API_KEY"):
        print("\n[CLAUDE] Summarising commits with Claude haiku...")
        items = build_work_items_claude(all_commits, period)
    else:
        print("\n[SIMPLE] Rule-based grouping (set ANTHROPIC_API_KEY to use Claude)...")
        items = build_work_items_simple(all_commits, period)

    # 4. Preview
    print(f"\n[PREVIEW] {len(items)} work item(s):\n")
    for i, item in enumerate(items, 1):
        print(f"  ── Item {i} ──────────────────────────────")
        print(f"  工作類型 : {item['工作類型']}")
        print(f"  工作名稱 : {item['工作名稱']}")
        print(f"  流程階段 : {item['流程階段']}  負載狀態 : {item['負載狀態']}")
        print(f"  工作內容 :\n{item['工作內容']}\n")

    # 5. Submit
    if DRY_RUN:
        print("[DRY RUN] Not submitting. Add --submit to send.\n")
        return

    print("[SUBMIT] Creating records in NocoDB...\n")
    for i, item in enumerate(items, 1):
        try:
            result = create_work_item(item)
            print(f"  ✅ Item {i} created Id={result.get('Id', '?')}  「{item['工作名稱']}」")
        except Exception as e:
            print(f"  ❌ Item {i} FAILED: {e}")

    print(f"\n✅ Done! https://ptii-test.concords.com.tw:20011/it_report\n")


if __name__ == "__main__":
    main()
