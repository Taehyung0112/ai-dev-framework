<!-- version: 1.0 | framework: ai-dev-framework -->
# Skills 索引

Skills 是可按需載入的可執行指令檔，存放於 `~/.claude/framework/skills/`。
分兩種類型：使用者直接呼叫，以及 agent 在任務執行時按需載入。

---

## 使用者直接呼叫的 Skills

直接在對話中輸入 slash command 即可觸發。

| Skill 檔案 | 指令 | 用途 |
|---|---|---|
| `weekly-report.md` | `/weekly-report` | 自動填寫並上傳每週工作日誌到 NocoDB（互動式引導設定） |
| `sprint-planning.md` | `/sprint-plan` | 把 backlog 拆成 sprint 任務，附 L1/L2/L3 複雜度與 P0/P1/P2 優先級標記 |
| `adr-template.md` | `/adr` | 產生架構決策記錄（ADR-NNN 格式） |
| `rollback-procedure.md` | `/rollback #N` | 緊急回滾 SOP：定位問題 commit → hotfix 分支 → GitLab revert → 通知 |
| `security-audit.md` | `/security-audit` | STRIDE 威脅建模 + OWASP Checklist + incubator red lines 審計 |
| `tech-debt-refactor.md` | `/tech-debt` | 技術債分級矩陣、重構不改行為協議、CHORE commit 指引 |
| `code-review.md` | `/code-review` | incubator 代碼審查 overlay（疊加在標準審查之上） |

> **CLAUDE.md session banner 觸發點**：`weekly-report`、`sprint-plan`、`adr`、`security-audit`、
> `tech-debt`、`code-review`、`rollback` 均已列在 `ai-dev-framework/CLAUDE.md` 的啟動橫幅。

---

## Agent 按需載入的 Skills

不由使用者直接呼叫，而是由 agent 在執行任務的特定階段載入。
各 agent 的 `## Framework Skills` 章節定義了載入時機。

| Skill 檔案 | 使用 Agent | 載入時機 |
|---|---|---|
| `adr-template.md` | Architect | L2/L3 設計決策涉及 API 邊界或模組邊界變更時 |
| `security-audit.md` | Architect、Auditor | L3 任務涉及 auth、金融邏輯或外部 I/O 時（必載） |
| `tech-debt-refactor.md` | Coder、QA | 任務類型為重構時 |
| `code-review.md` | Coder、QA | Coder 自我審查步驟 / QA 審查測試代碼時 |
| `sprint-planning.md` | PM | `/sprint-plan` 觸發，或 PM 在分解 Epic 時需要估算參考 |

---

## Skills 與 Playbook 的區別

| | Skills | Playbook |
|---|---|---|
| **用途** | 特定任務的可執行指令（做什麼、怎麼做） | 通用標準與原則（為什麼這樣做） |
| **載入方式** | 按需載入（觸發時才讀） | 被 agent 在需要時引用 |
| **格式** | 步驟式 SOP，包含互動邏輯 | 規範文件，說明原則和規則 |
| **範例** | `weekly-report.md`（含互動引導） | `git-workflow.md`（commit 格式規範） |
