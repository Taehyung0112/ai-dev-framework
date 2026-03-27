<!-- version: 2.1 | framework: ai-dev-framework -->
# Git Workflow & Commit Standard

> 本文件基於 incubator repo 4,204 個 commit 完整歷史分析撰寫（2026-03-23）。
> 資料分佈：UPPERCASE 風格 2,437 commits（58%）、lowercase conventional 121 commits（3%）、
> 裸提交 1,646 commits（39%，WIP/個人分支，不納入規範）。

---

## 1. Commit Message 格式

### 1.1 主線風格：UPPERCASE（強制）

這是 incubator **唯一指定的正式 commit 格式**。
由 tony、vincent、limon、brendan、michael 等核心成員持續使用，
佔所有正式 commit 的 95% 以上。MR 標題必須一律採用此格式。

```
TYPE: scope — subject
```

規則：
- `TYPE` 全大寫（見 §1.2 Type 表）
- `scope` 小寫，描述受影響的服務或模組
- ` — ` 為 **em dash（—）**，前後各一個空格，嚴格不得替換為 `-`（連字號）
- `subject` 英文小寫開頭，動詞原形，不加句號，≤ 72 字元

範例（直接來自 git 歷史）：
```
CHORE: ai-dev-framework — add Agentic Workflow 2.0
FEATURE: freqtrade-sdk — add Concords exchange shim
FIX: cpp sdk — fix stockclient callback init sequence
REFACTOR: order-hub — extract auth middleware to separate module
CI: freqtrade-sdk — add unit_test_freqtrade_sdk CI job
DOCS: network-topology — add vip.md
MINOR: cpp sdk — apply cmake-format
```

> **MR 標題必須與 commit 格式一致**：`CHORE: ai-dev-framework — ...`，
> 不得使用 `chore(scope):` 或混用大小寫。

---

### 1.2 Type 對照表

| Type | 使用時機 | 歷史出現次數 |
|---|---|---|
| `FEATURE` | 新功能 | 832 |
| `FIX` | Bug 修補 | 649 |
| `MINOR` | 微調（格式、log 訊息、連結、無行為變更） | 272 |
| `CI` | CI/CD pipeline 變更 | 252 |
| `REFACTOR` | 重構（不改行為） | 200 |
| `CHORE` | 雜務（工具設定、依賴升級、環境維護） | 54 |
| `DOCS` | 文件變更 | 17 |
| `TEST` | 新增或修改測試 | 8 |

**`MINOR` vs `CHORE` 區分**：
- `MINOR`：微調現有代碼/設定，不新增功能（cmake-format、修 typo、更新下載連結）
- `CHORE`：工具、流程、環境相關的維護工作（CI job、依賴升級、格式化工具執行）

---

### 1.3 禁用 Typo 清單（歷史紀錄實際出現過）

| 錯誤寫法 | 正確寫法 |
|---|---|
| `FXI` | `FIX` |
| `FATURE` / `FEATRUE` / `FETAURE` | `FEATURE` |
| `REFACTORING` | `REFACTOR` |
| `CHORES` | `CHORE` |
| `DEPENCENCY` | `CHORE`（依賴升級屬 CHORE 類） |
| `DOCUMENTATION` | `DOCS` |
| `chore(scope):` | `CHORE: scope —` |
| `feat(scope):` | `FEATURE: scope —` |
| `scope - subject`（連字號） | `scope — subject`（em dash） |

---

### 1.4 Scope 規範

- 全小寫，kebab-case
- 置於 `TYPE: ` 之後，` — ` 之前
- 短小改動可省略 scope（直接寫 subject）

常用 scope（依使用頻率）：
`cpp sdk`, `freqtrade-sdk`, `order-hub`, `order-gateway`, `cert-server-rest`,
`cert-client-web`, `ticker`, `pkg`, `ai-dev-framework`

```
# Scope 存在
CHORE: freqtrade-sdk — add unit_test_freqtrade_sdk CI job

# Scope 省略（全局性或短小改動）
CHORE: apply yapf formatting to freqtrade-sdk src
FIX: ci tag trigger pipeline
```

---

### 1.5 例外：Sub-project Conventional Commits（限定範圍）

以下情況**允許**使用 lowercase conventional commit，但**同一 PR 內不得混用**：

| 允許場合 | 原因 |
|---|---|
| `sdk/freqtrade_sdk/` 內的 commit | 該子模組歷史已建立 `fix(sdk):` 慣例 |
| 全局依賴升級（無明確 scope） | 例：`chore: upgrade packages(CVE-2025-55182)` |

**這些 commit 格式不得用於 MR 標題**。MR 標題統一使用 UPPERCASE 格式。

---

## 2. Branch 命名規範

### 2.1 格式

```
type/{author}/{project}/{task-name}
```

| 段落 | 規則 | 範例 |
|---|---|---|
| `type` | 見 §2.2 | `feature`, `fix`, `ci`, `chore` |
| `author` | 個人 handle（小寫） | `vincent`, `tony`, `justin`, `zenic` |
| `project` | 服務或子模組名稱 | `sdk`, `order-hub`, `freqtrade-sdk` |
| `task-name` | 簡短描述，全小寫 kebab-case | `add-jwt-middleware`, `fix-callback-init` |

實際範例（來自 git 歷史）：
```
feature/vincent/cert-server-rest/add-jwt-middleware
fix/tony/order-hub/trade-report-stream
ci/vincent/ci-job-add-vcpkg-install
fix/vincent/sdk/fix-callback-init-sequence
feat/zenic/sdk/freqtrade-concords-exchange-shim
docs/vincent/update-network-topology
chore/justin/ai-dev-framework/init-framework
```

### 2.2 Branch 類型表

| Type | 使用時機 |
|---|---|
| `feature/` | 新功能開發 |
| `feat/` | 同 feature（zenic 慣用縮寫，兩者均接受） |
| `fix/` | Bug 修復 |
| `ci/` | CI/CD 設定變更 |
| `refactor/` | 重構 |
| `docs/` | 文件 |
| `chore/` | 雜務（格式化、依賴、腳本） |
| `test/` | 獨立測試補充 |
| `minor/` | 小調整 |
| `research/` | 技術研究（不直接合入 develop） |
| `experiment/` | 實驗性 POC（不直接合入 develop） |
| `release-v{x.y.z}` | Release 分支，從 `develop` 切出 |
| `hotfix/` | 緊急修復，從 `master` 切出 |

### 2.3 主幹分支

| 分支 | 用途 |
|---|---|
| `develop` | 日常開發集成分支（所有 MR 的目標分支） |
| `master` / `main` | 受保護，僅接受 Release 合入 |

---

## 3. Pull Request / Merge Request 規範

### 3.1 MR 標題格式（強制）

MR 標題**必須**使用 UPPERCASE commit 格式：

```
CHORE: ai-dev-framework — add Agentic Workflow 2.0
FEATURE: order-hub — add JWT refresh token
FIX: freqtrade-sdk — fix 3 CRITICAL and 5 HIGH/MEDIUM production bugs
```

**禁止**：
```
chore(ai-dev-framework): ...   ← 小寫括號格式
Add something                  ← 無 TYPE 前綴
fix: something                 ← 小寫裸 type
CHORE: scope - subject         ← 連字號（應為 em dash）
```

### 3.2 MR 描述模板

```markdown
## Summary

- 簡述此 MR 做了什麼（1-3 點）
- 說明動機或問題背景

## Changes

- `path/to/file.py`: 說明修改內容
- `tests/xxx_test.py`: 說明測試覆蓋範圍

## Test Results

- [ ] 本地測試指令通過（`pytest tests/` 或對應語言指令）
- [ ] CI pipeline 所有 job 通過
- [ ] 覆蓋率 >= 80%（core business logic 100%）

## Breaking Changes

<!-- 若無則刪除此節 -->
- 說明對現有介面的破壞性影響及遷移方式

## Related Issues

<!-- 選填 -->
- Closes #xxx
```

### 3.3 MR 發起前 Checklist

```
- [ ] git rebase develop（勿使用 merge develop into feature）
- [ ] MR 標題符合 UPPERCASE 格式（TYPE: scope — subject）
- [ ] em dash（—）不是連字號（-）
- [ ] commit message 無 typo（對照 §1.3 禁用清單）
- [ ] 本地測試全部通過
- [ ] 無硬編碼的金鑰、密碼、憑證路徑
- [ ] 新功能已附對應測試
- [ ] 若影響 CI 設定，已驗證 .gitlab-ci.yml 語法
```

### 3.4 Merge 策略

- **feature → develop**：Merge commit（保留 feature 分支歷史，與 GitLab 設定一致）
- **hotfix → master**：Merge commit + 同步 cherry-pick 至 develop
- **release → master**：Tag + Merge commit

---

## 4. CI 整合規範

- CI job 命名：`{action}_{project_name}`，例如 `unit_test_freqtrade_sdk`, `build_windows_python_sdk`
- `pull_policy` 統一使用 array 格式
- 使用 `python3` / `pip3`（`python` binary 在 `incubator-dev` 映像中不存在）
- vcpkg cache 需在 CI 側正確設定

---

## 5. 常見反模式（Anti-Patterns）

| 反模式 | 歷史出現 | 正確做法 |
|---|---|---|
| `FXI:`, `FATURE:` 等 typo | ~11 筆 | 提交前對照 §1.3 清單 |
| 裸 `FIX`（無 scope） | 多筆 | `FIX: freqtrade-sdk — ...` |
| `wip` / `tmp` / `checkpoint` 合入 develop | 多筆 | rebase -i 整理後再 MR |
| MR 標題用 `type(scope):` 格式 | 本次發現 | 改用 `TYPE: scope —` |
| em dash 替換為連字號 `-` | 偶見 | 使用 `—`（em dash） |
| 同一 PR 混用大小寫風格 | 偶見 | 同一 PR 統一格式 |
| subject 超過 72 字元 | 偶見 | 細節放 commit body |

---

## 6. 完整開發流程

1. 從最新 `develop` 切出分支（`git pull --ff-only origin develop` 後再 `checkout -b`）
2. 完成開發，本地測試通過
3. `git rebase develop` 保持線條乾淨
4. 推送至遠端，發起 MR（標題使用 `TYPE: scope — subject`，body 使用 §3.2 模板）
5. 通過 Code Review 與 CI 所有 job
6. Merge commit 合入 develop，刪除 feature 分支
