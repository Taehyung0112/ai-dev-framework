# Agentic Workflow 2.2 — AI 開發框架

一套**以 Git 管理、全團隊同步**的 Claude Code 多代理人（Multi-Agent）工程基礎建設。
克隆一次，放到穩定位置，全體成員從同一份 Source of Truth 運作。

> **v2.2** 新增：Skills 層（6 個內建 skill + code-review-expert）、TruffleHog Secrets 掃描 CI job、AI MR Review CI job（Claude API）、v2.2 session banner。
> **v2.1** 新增：Context Controller 代理人、`claude-team status`、Monorepo 感知的 `update`、Working Directory 協定、`.clauderules` 觸發詞對照表、跨平台一鍵安裝程式。
> English version: [README.md](./README.md)

---

## 一鍵安裝

**Windows（PowerShell 中執行）：**

```powershell
iwr -UseBasicParsing https://raw.githubusercontent.com/Taehyung0112/ai-dev-framework/main/bin/install.ps1 | iex
```

**Linux / macOS（Bash）：**

```bash
curl -fsSL https://raw.githubusercontent.com/Taehyung0112/ai-dev-framework/main/bin/install.sh | bash
```

安裝程式將自動完成：
1. 檢查必要工具（git、claude、gh、node、python3）
2. 將框架 clone 至 `~/ai-dev-framework`
3. 建立 `~/.claude/framework` 符號連結 / 目錄連接點（Junction）
4. 更新 `~/.claude/CLAUDE.md`，加入所有框架 `@import`
5. 將 `claude-team` 指令注入 Shell Profile（`.bashrc`/`.zshrc`/`$PROFILE`）
6. 執行 `claude-team init --global` 與 `doctor` 確認安裝結果

> **安裝完成後**：重新開啟終端機，再用 `claude-team init` 附加到各專案。

---

## 安裝完成後 — 附加到專案

在每個要啟用代理人工作流程的專案 Repo 內執行一次：

```bash
cd ~/your-project
claude-team init
```

接著在該目錄開啟 Claude Code — Lead Agent 會自動問候你。

---

## 目錄

1. [架構總覽](#1-架構總覽)
2. [代理人角色手冊](#2-代理人角色手冊)
3. [通訊合約（I/O）](#3-通訊合約io)
4. [手動設定（不使用安裝程式）](#4-手動設定不使用安裝程式)
5. [Skills 層](#5-skills-層)
6. [claude-team CLI 指令參考](#6-claude-team-cli-指令參考)
7. [團隊同步 — 更新 Playbook](#7-團隊同步--更新-playbook)
8. [目錄結構](#8-目錄結構)
9. [設定層級](#9-設定層級)

---

## 5. Skills 層

Skills 是針對特定開發任務的可執行參考文件，存放於 `skills/`，透過 `~/.claude/framework/skills/` 全域可用。

### 內建 Skills（v2.2）

| 文件 | 指令 | 用途 |
|---|---|---|
| `skills/code-review.md` | `/code-review` | incubator 客製化 Code Review 覆蓋層（C++/Python 規範、安全紅線） |
| `skills/security-audit.md` | `/security-audit` | STRIDE 威脅建模 + OWASP Top 10 + incubator 紅線 |
| `skills/sprint-planning.md` | `/sprint-plan` | Sprint 拆解、L1/L2/L3 估時、GitLab 里程碑設定 |
| `skills/adr-template.md` | `/adr` | 架構決策記錄（ADR-NNN）格式 |
| `skills/rollback-procedure.md` | `/rollback #N` | 緊急回滾 SOP（Production、git revert、資料庫） |
| `skills/tech-debt-refactor.md` | `/tech-debt` | 技術債三角矩陣 + 安全重構協議 |

### 外部 Skills（本機安裝）

以下技能安裝於 `~/.claude/skills/`，不納入框架 Repo，但可被所有代理人呼叫：

| 技能指令 | 來源 | 用途 |
|---|---|---|
| `/code-review-expert` | sanyuan0704/sanyuan-skills（MIT，2.9k ⭐） | SOLID + Security + 品質深度 Code Review，P0–P3 嚴重度模型 |
| `/elite-powerpoint-designer` | willem4130/claude-code-skills | 頂級簡報設計（麥肯錫金字塔、Insight Headline、動畫指引） |

**安裝方式（GitHub CLI）：**
```bash
# code-review-expert（Linux / macOS）
npx skills add sanyuan0704/sanyuan-skills --path skills/code-review-expert

# elite-powerpoint-designer（gh CLI，跨平台）
gh api repos/willem4130/claude-code-skills/contents/skills/elite-powerpoint-designer/SKILL.md --jq '.content' | base64 -d > ~/.claude/skills/elite-powerpoint-designer/SKILL.md
```

使用方式：`/code-review-expert` — 對當前 `git diff` 執行 SOLID + 安全 + 程式碼品質審查。
使用方式：`/elite-powerpoint-designer` — 啟動頂級簡報設計工作流程（受眾問卷 → 結構 → 設計 → 品質檢查）。

### Skills 在 Lead Agent 中的整合

L2/L3 任務中，Lead 在 Coder 完成後、QA 之前自動呼叫 `/code-review-expert`：
```
Architect → Coder → /code-review-expert → QA → (Auditor — L3 only)
```
P0/P1 問題退回 Coder 修復；僅 P2/P3 進入 QA 流程。

### CI/CD 自動化（v2.2 新增）

兩個新 job 加入 `static_analysis` 階段（僅 MR pipeline 觸發）：

**`secrets_scan`** — TruffleHog OSS 機密掃描
- 掃描 MR diff 中的 800+ 種機密類型
- `allow_failure: false` — 偵測到機密即封鎖合併
- 無需額外設定

**`ai_code_review`** — Claude API MR Review
- 將結構化 P0/P1/P2/P3 審查結果發佈為 GitLab MR 留言
- `allow_failure: true` — 僅供參考（不阻斷合併）
- 需設定 GitLab CI/CD 變數：
  - `ANTHROPIC_API_KEY`（Protected + Masked）
  - `GITLAB_TOKEN`（api 範圍，Protected）

### Awesome-Skills 擴充圖書館（未來擴展）

`github.com/sickn33/antigravity-awesome-skills`（26.9k ⭐，1304+ skills）定位為**擴充圖書館**。有特定需求時（如 Docker 優化、Kubernetes 模式）再進入搜尋單一 Skill，不進行 Bulk Import。

---

## 1. 架構總覽

框架在 runtime 由**三層設定**組合而成：

```
Layer 1 — 全域（~/.claude/）
  每個 Claude Code session、每個專案都會載入。
  內容：CLAUDE.md（import lead.md + playbook）、framework/ 符號連結
  擁有者：本 Repo，透過符號連結指向 ~/.claude/framework
  建立方式：claude-team init --global
  更新：git pull → 下次 session 立即生效

Layer 2 — Repo（{your-project}/.clauderules + .agents/）
  Claude Code 在專案目錄內啟動時載入。
  內容：Session 初始化協定（v2.1）、觸發詞對照表、registry.json、team_status.md
  擁有者：各專案 Repo
  建立方式：在專案目錄內執行 claude-team init
  更新：編輯 .clauderules 或 .agents/team_status.md，commit 到專案 Repo

Layer 3 — 專案（{your-project}/CLAUDE.md）
  在特定子專案目錄內啟動時載入。
  內容：該專案專屬的建置指令、測試指令、架構說明。
  擁有者：各子專案團隊
  建立方式：手動建立
  更新：編輯 CLAUDE.md
```

### 組合流程（v2.1）

```
Session 啟動
     │
     ▼
 Layer 1：~/.claude/CLAUDE.md
  → import agents/lead.md         ← 啟動 Lead Agent
  → import playbook/*.md          ← 載入工程標準
     │
     ▼
 Layer 2：{project}/.clauderules  （v2.1：觸發詞 + Context Gate）
  → Lead 讀取 .agents/team_status.md 還原 Sprint 狀態
  → 回報：[LEAD] Session restored. Sprint: X | Active Task: #Y
     │
     ▼
 Layer 3：{project}/CLAUDE.md    （選填，專案專屬）
  → 專案建置指令、架構說明
     │
     ▼
 收到任務
     │
     ▼  僅限 L2 / L3
 ContextController 前置檢查
  → 產出 .agents/working/#{issue}/CONTEXT_ADVISORY.md
  → GREEN：繼續 │ ORANGE：建議 /compact │ RED：強制停止
     │
     ▼
 派送專家鏈（Architect → Coder → QA → Auditor）
 所有交付物寫入 .agents/working/#{issue}/
```

> **為何需要兩個步驟？**
> Layer 1 讓 Lead Agent 全域可用。Layer 2 提供*該專案*的 Sprint 狀態。
> 缺少 Layer 2：Lead 啟動但沒有任務歷史紀錄。
> 缺少 Layer 1：Lead 根本不會啟動。

---

## 2. 代理人角色手冊

### 總覽表

| 代理人 | 啟動方式 | 任務等級 | 輸入 | 輸出 |
|---|---|---|---|---|
| **PM** | 使用者觸發（`開始新任務：`） | 全部 | 自然語言需求 | Task Card + GitHub Issue |
| **Lead** | 自動（Session 啟動） | 全部 | PM 的 Task Card | 路由決策、Gate 檢查 |
| **ContextController** | Lead（L2/L3 派送前） | L2、L3 | 任務 + 當前 Session 狀態 | CONTEXT_ADVISORY.md |
| **Architect** | Lead（L2/L3） | L2、L3 | Task Card + 程式碼庫上下文 | SPEC_SHEET.md |
| **Coder** | Lead | 全部 | SPEC_SHEET.md（L2/L3）或任務說明（L1） | IMPLEMENTATION_LOG.md |
| **QA** | Lead（Coder 完成後） | L2、L3 | IMPLEMENTATION_LOG + 修改過的檔案 | VERIFICATION_REPORT.md |
| **Auditor** | Lead（僅 L3） | 僅 L3 | 所有前序文件 + 修改過的檔案 | PASS 或 BLOCK 裁決 |

---

### PM 代理人 — 產品經理

**檔案**：`agents/pm.md`

**職責**：
- 將模糊的業務需求拆解成 Epic → Story → Task 層級結構
- 透過 `gh issue create` 建立結構化的 GitHub Issue
- 指派優先級（P0/P1/P2）與複雜度（L1/L2/L3）
- 更新 `.agents/team_status.md` 的 Backlog 區段

**觸發詞**：使用者說 `開始新任務：[名稱]` 或 `新增 Epic：[描述]`

---

### Lead 代理人 — 統籌協調者

**檔案**：`agents/lead.md`

**職責**：
- 每次 Session 的預設啟動代理人
- 對每個任務進行分類：L1（瑣碎）/ L2（功能）/ L3（安全關鍵）
- 在每次 L2/L3 派送前啟動 ContextController
- 將工作路由至正確的專家鏈
- 在 PR 建立前執行品質 Gate 檢查

**複雜度矩陣**：

| 等級 | 判斷標準 | 路由鏈 | Coverage Gate |
|---|---|---|---|
| L1 | 文件、typo、config、依賴升級 | 僅 Coder | Smoke test |
| L2 | 新邏輯、重構、API 變更 | **CC** → Arch → Coder → QA | ≥ 80% |
| L3 | 並發、金融計算、Auth、生產穩定性 | **CC** → Arch → Coder → QA → Auditor | ≥ 90%，關鍵路徑 100% |

*CC = ContextController 前置檢查*

---

### ContextController 代理人 — Token 預算執行者 *(v2.1 新增)*

**檔案**：`agents/context_controller.md`

**職責**：
- L2/L3 派送前的強制前置 Gate（不可跳過）
- 估算當前 Context Window 使用率（%）
- 定義每個任務的讀取範圍：MUST / SHOULD / MUST NOT
- 產出 `CONTEXT_ADVISORY.md` 至 `.agents/working/#{issue}/`
- Context > 80% 時強制停止 L3 派送

**紅綠燈系統**：

| 狀態 | Context 使用率 | 行動 |
|---|---|---|
| 🟢 GREEN | < 50% | 正常派送，無限制 |
| 🟡 YELLOW | 50–70% | 警告。要求選擇性讀取。經使用者同意後繼續 |
| 🟠 ORANGE | 70–80% | 強烈建議先執行 `/compact` |
| 🔴 RED | > 80% | **強制停止** L3。L2 需使用者明確覆蓋 |

詳見 §ContextController 完整說明（本文件下方）。

---

### Architect 代理人

**檔案**：`agents/architect.md`

**職責**：
- 掃描受影響模組（範圍由 ContextController 定義）
- L3 威脅建模（Race Condition、資料遺失、Auth Bypass）
- 產出含介面合約與風險表的 SPEC_SHEET.md
- 將紅線問題標示為 CRITICAL

**紅線（自動 CRITICAL）**：
- 可重入路徑中使用 `threading.Lock()`（應改用 `RLock`）
- 共享可變狀態未加鎖保護
- 金融計算未加 `round(..., 10)` 精度保護
- Timeout 無清理邏輯（Ghost Order 風險）
- 硬編碼憑證或 JWT Secret

---

### Coder 代理人 — 資深工程師

**檔案**：`agents/coder.md`

**職責**：
- 依照 Architect 的 SPEC_SHEET 實作（L2/L3）或任務說明（L1）
- 交付前執行 25 項 Self-Review Checklist
- 將 IMPLEMENTATION_LOG.md 寫入 `.agents/working/#{issue}/`
- 使用 `type(scope): description` 格式 commit，明確按檔案 stage

**限制**：禁止 `git add -A`。禁止 TODO 佔位符。禁止實作 Spec 以外的功能。

---

### QA 代理人 — 品質 Gate

**檔案**：`agents/qa.md`

**職責**：
- 設計測試：Happy Path、邊界值、錯誤路徑、並發（L3）
- 執行 `pytest ... --cov` 驗證迴圈
- 將 VERIFICATION_REPORT.md 寫入 `.agents/working/#{issue}/`
- Coverage 低於門檻時 BLOCK；發現實作 Bug 時退回 Coder

**Coverage 門檻**：L1=Smoke、L2=80%、L3=整體 90% + 關鍵路徑 100%

---

### Auditor 代理人 — 可靠性 Gate

**檔案**：`agents/auditor.md`

**職責（僅 L3）**：
- 執行緒安全稽核（Race、Deadlock、鎖誤用）
- 金融精度稽核（浮點數保護、Tick Size、捨入）
- 生產穩定性稽核（Ghost Order、重啟恢復、WebSocket 重連）
- 安全稽核（Auth 路徑、Token 處理、憑證儲存）
- **I/O 合規稽核**（Log 安全、網路超時、資源清理）
- 簽發 PASS 或 BLOCK 裁決

**硬規則**：CRITICAL 或 HIGH 發現 = 自動 BLOCK，不可談判。

---

## 3. 通訊合約（I/O）

五種標準文件驅動所有代理人交接。全部寫入 `.agents/working/#{issue}/`。

| 合約 | 建立者 | 消費者 | 模板 |
|---|---|---|---|
| CONTEXT_ADVISORY | ContextController | Lead、所有代理人 | *內嵌於 context_controller.md* |
| TASK_CARD | PM | Lead、Architect、Coder | `contracts/TASK_CARD.md` |
| SPEC_SHEET | Architect | Coder、Auditor | `contracts/SPEC_SHEET.md` |
| IMPLEMENTATION_LOG | Coder | QA、Auditor | `contracts/IMPLEMENTATION_LOG.md` |
| VERIFICATION_REPORT | QA | Lead、Auditor | `contracts/VERIFICATION_REPORT.md` |

所有模板均含必填與選填區段。代理人不得略過必填區段。
Working 文件放置於 `.agents/working/#{issue}/`，已加入 `.gitignore`（任務結束後不留存）。

---

## 4. 手動設定（不使用安裝程式）

若不想使用一鍵安裝程式，可按以下步驟手動設定。

---

### Step 1 — Clone 框架

```bash
git clone https://github.com/Taehyung0112/ai-dev-framework.git ~/ai-dev-framework
```

### Step 2 — 全域機器設定

```bash
bash ~/ai-dev-framework/bin/claude-team init --global
```

**建立的內容：**

```
~/.claude/
├── CLAUDE.md          ← import lead.md + context_controller.md + 所有 playbook 檔案
└── framework/         ← 符號連結 → ~/ai-dev-framework（Windows 為 Junction）
```

> **Windows 使用者**：在 Git Bash（以管理員身份執行），或使用上方 PowerShell 安裝程式。
> 手動建立 Junction：`cmd /c mklink /J %USERPROFILE%\.claude\framework <路徑>`

### Step 3 — 驗證

```bash
bash ~/ai-dev-framework/bin/claude-team doctor
```

### Step 4 — 附加到專案

```bash
cd ~/your-project
bash ~/ai-dev-framework/bin/claude-team init
```

**建立的內容：**

```
your-project/
├── .clauderules            ← v2.1：Session 初始化 + 觸發詞 + Context Gate
└── .agents/
    ├── registry.json       ← 指向共享框架
    ├── team_status.md      ← Sprint 狀態、任務記錄、代理人名單
    └── working/            ← 已 gitignore：任務工作文件
        └── #{issue}/
            ├── CONTEXT_ADVISORY.md
            ├── SPEC_SHEET.md
            ├── IMPLEMENTATION_LOG.md
            ├── VERIFICATION_REPORT.md
            └── AUDIT_REPORT.md  （僅 L3）
```

> **請 commit** `.clauderules`、`registry.json`、`team_status.md` 到專案 Repo。
> `.agents/working/` 已加入 gitignore。

### Step 5 — 日常使用

在專案目錄內開啟 Claude Code，Lead Agent 會顯示歡迎橫幅：

```
╔═══════════════════════════════════════════════════════════════╗
║   Agentic Workflow 2.2  |  Lead is active                     ║
╠═══════════════════════════════════════════════════════════════╣
║    開始新任務: <描述>          → PM（Task Card + issue）       ║
║    /code-review-expert        → 深度 Code Review（SOLID）     ║
║    /security-audit            → STRIDE 威脅建模               ║
║    /sprint-plan               → Sprint 規劃 SOP               ║
║    /adr                       → 架構決策紀錄                  ║
║    /tech-debt                 → 技術債 Triage                  ║
║    /rollback #N               → 緊急回滾 SOP                  ║
║    /elite-powerpoint-designer → 頂級簡報設計                  ║
╚═══════════════════════════════════════════════════════════════╝
```

**觸發詞（v2.2）**：

| 說 | 效果 |
|---|---|
| `開始新任務：[描述]` | PM → Task Card → Lead 派送 |
| `/review` | Coder 對當前程式碼執行 Self-Review Checklist |
| `/test` | QA 為當前上下文生成測試 |
| `/refactor` | Coder 依 Clean Code 原則重構 |
| `rollback #N` | Lead + Auditor 緊急影響審查 |

---

## 5. claude-team CLI 指令參考

```
claude-team <command> [options]

Commands:
  init [--global]   在當前目錄初始化代理人工作流程。
                    始終建立：.clauderules（v2.1）、.agents/registry.json、
                               .agents/team_status.md
                    --global：同時建立 ~/.claude/framework 符號連結/Junction
                              並建立/更新 ~/.claude/CLAUDE.md（v2.1 import 區塊）。
                              完成後自動執行 doctor。

  status            從 .agents/team_status.md 顯示 Sprint 儀表板。
                    顯示：專案、Sprint 名稱/目標/期間、當前任務 + 代理人、
                          Backlog / In Progress / Done 計數。

  update            從 git remote 拉取最新框架變更。
                    Monorepo 感知（ADR-007）：自動走訪到 git root。
                    支援獨立 Repo 和子目錄兩種配置。

  doctor            診斷本機環境。檢查：
                      gh、python3、pip3、pytest、node、vcpkg、git、
                      ~/.claude/framework 符號連結/目錄連接點、
                      當前目錄的 .agents/team_status.md。
                    報告：每項依賴的 PASS / WARN / FAIL。

  help              顯示此說明文字。
```

---

## 6. 團隊同步 — 更新 Playbook

### 何時執行 `claude-team update`

在隊友推送以下內容到本 Repo 後執行：
- Playbook 文件更新（`playbook/*.md`）
- 代理人定義更新（`agents/*.md`）
- CLI 腳本更新（`bin/claude-team`）

```bash
bash ~/ai-dev-framework/bin/claude-team update
# 重啟 Claude Code 以套用變更
```

### 推送 Playbook 變更

```bash
# 1. 編輯相關文件
edit ~/ai-dev-framework/playbook/coding-standards.md

# 2. Commit 並 push（在 monorepo root 或 standalone repo 內）
git add ai-dev-framework/playbook/coding-standards.md
git commit -m "chore(playbook): update Python logging standard"
git push

# 3. 通知隊友執行：claude-team update
```

### 自動同步的內容（`claude-team update` + 重啟後）

| 變更位置 | 生效時機 |
|---|---|
| `playbook/*.md` | 下次 Claude Code Session |
| `agents/*.md` | 下次 Claude Code Session |
| `contracts/*.md` | 代理人在任務開始讀取模板時 |
| `bin/claude-team` | `claude-team update` 後 |

### 需要手動操作的內容

| 變更位置 | 所需操作 |
|---|---|
| `{project}/.clauderules` | commit + push 到專案 Repo；隊友 `git pull` 即可取得 |
| `{project}/CLAUDE.md` | commit + push 到專案 Repo |
| `{project}/.agents/team_status.md` | 由 Lead Agent 自動更新；定期 commit |

---

## 7. 目錄結構

```
ai-dev-framework/
├── README.md                        ← 本文件（英文版）
├── README.zh-TW.md                  ← 繁體中文版
├── CLAUDE.md                        ← Claude Code 專案指引 + Session Start 橫幅
├── .gitignore
│
├── agents/                          ← 代理人定義文件
│   ├── lead.md                      ← Lead 統籌協調者（預設代理人）
│   ├── pm.md                        ← 產品經理
│   ├── context_controller.md        ← Token 預算執行者（v2.1 新增）
│   ├── architect.md                 ← 架構師
│   ├── coder.md                     ← 資深 Coder
│   ├── qa.md                        ← QA 專家
│   └── auditor.md                   ← 可靠性稽核員（僅 L3）
│
├── contracts/                       ← 代理人 I/O 文件模板
│   ├── TASK_CARD.md                 ← PM → Lead 交接
│   ├── SPEC_SHEET.md                ← Architect → Coder 交接
│   ├── IMPLEMENTATION_LOG.md        ← Coder → QA 交接
│   └── VERIFICATION_REPORT.md      ← QA → Lead/Auditor 交接
│
├── playbook/                        ← 工程標準（version: 2.1）
│   ├── claude-base.md
│   ├── coding-standards.md
│   ├── git-workflow.md
│   ├── architecture-guide.md
│   ├── testing-guide.md
│   ├── team-standards.md
│   ├── ai-workflow.md
│   └── pr-template.md
│
└── bin/
    ├── claude-team                  ← 管理 CLI（bash）
    ├── claude-team.ps1              ← 管理 CLI（PowerShell wrapper）
    ├── install.sh                   ← 一鍵安裝程式（Linux / macOS）
    └── install.ps1                  ← 一鍵安裝程式（Windows）
```

---

## 8. 設定層級

### 層級摘要

```
優先順序（高到低）：
  3. {project}/CLAUDE.md       — 專案專屬指令與說明
  2. {project}/.clauderules    — Session 初始化、觸發詞、Context Gate（v2.1）
  1. ~/.claude/CLAUDE.md       — 全域：Lead Agent + 工程標準
```

### 為何 `init --global` 和 `init` 都是必要的

| 步驟 | 啟用的功能 |
|---|---|
| 僅 `init --global` | Lead 啟動，但沒有 Sprint 上下文。`.agents/team_status.md` 不存在。 |
| 僅 `init`（專案） | `team_status.md` 存在，但 `lead.md` 未載入 → Lead 不會啟動。 |
| 兩者都執行 | Lead 啟動，讀取 Sprint 上下文，回報 `[LEAD] Session restored.` |

### 新增專案專屬 CLAUDE.md（選填）

建立 `{project}/CLAUDE.md` 只放專案專屬內容，不需重複 Playbook 規則。

```markdown
## 工程標準
本專案遵循 `~/.claude/framework/playbook/` 的共享工程 Playbook。

## 建置與測試
\`\`\`bash
pytest tests/ --cov=src
\`\`\`

## 架構說明
- ...
```

---

## ContextController 完整說明

### 監控的任務範疇

ContextController 在以下**每個** L2/L3 任務開始前強制介入，負責監控：

| 監控項目 | 說明 |
|---|---|
| **Context 使用率估算** | 對話歷史深度 + 已載入代理人文件 + 已讀取原始碼 + 已產出文件 |
| **讀取範圍控管** | 為每個下游代理人定義 MUST/SHOULD/MUST NOT 讀取的檔案清單 |
| **反模式偵測** | 標記「讀取整個 300+ 行檔案卻只需要一個函數」等浪費 Token 的行為 |
| **每代理人的讀取指引** | Architect 讀 X，Coder 讀 Y，QA 讀 Z（不重複讀取） |
| **壓縮建議** | 根據估算的 chain 成本決定是否建議 `/compact` |

### 應急措施

當 Context 超過門檻時，ContextController 依以下順序處置：

#### 🟡 YELLOW（50–70%）— 預警期
```
行動：
1. 回報 "Context at ~{n}%. Budget YELLOW."
2. 限制讀取範圍：只允許 MUST READ 清單內的檔案
3. 對所有 SHOULD READ 檔案加上 limit= 參數限制
4. 告知使用者："可選擇 /compact 以增加緩衝空間。繼續？[y/n]"
5. 收到 y 後繼續；收到 n 後等待 /compact 再重新評估
```

#### 🟠 ORANGE（70–80%）— 高風險期
```
行動：
1. 回報 "Context at ~{n}%. Budget ORANGE — HIGH RISK."
2. 強制縮減讀取範圍：只允許最小 MUST READ 子集
3. 建議："強烈建議先 /compact。L3 chain 共需 ~25k tokens，目前剩餘不足。"
4. 若使用者堅持繼續：加入警告標記，提醒 chain 可能中途失敗
5. 確保 CONTEXT_ADVISORY.md 記錄此決定與風險
```

#### 🔴 RED（> 80%）— 強制停止
```
行動：
1. 停止所有 L3 派送。無例外，無覆蓋。
2. 回報：
   "Context critically high (~{n}%). HARD STOP.
    L3 dispatch BLOCKED. This chain requires ~25k tokens for
    Spec + Impl + QA + Audit. Running now risks losing Auditor
    sign-off mid-chain — creating a silent safety gap.
    Action required: /compact → then re-confirm task."
3. 對 L2：警告使用者，等待明確確認後才可繼續
4. 更新 team_status.md Decision Log：記錄 RED stop 事件
```

#### 緊急恢復流程（/compact 後）
```
1. 使用者執行 /compact
2. Lead 重新讀取 .agents/team_status.md 還原任務狀態
3. ContextController 重新評估（通常恢復到 GREEN）
4. 重新產出 CONTEXT_ADVISORY.md（更新後的估算值）
5. Lead 重新確認任務細節後繼續派送
```

#### 其他應急措施
```
任務拆分（當 chain 成本超出可用預算時）：
  Lead 建議將 L3 任務拆成兩個 L2 任務：
  - 任務 #N-a：Architect 設計 + Coder 實作
  - 任務 #N-b：QA 驗證 + Auditor 稽核
  兩個任務分開 session 執行，各自在 GREEN 狀態下開始。

選擇性稽核（極端情況）：
  若 context 在 Auditor 前已達 ORANGE，ContextController 可建議：
  "僅稽核 Auditor Focus Areas（SPEC_SHEET 指定的最高風險區段），
   跳過完整 codebase 重讀。"
  此決定必須記錄於 CONTEXT_ADVISORY.md 並由 Lead 確認。
```

---

*由工程團隊維護。透過 PR 更新 ai-dev-framework。*
*版本：2.1*
