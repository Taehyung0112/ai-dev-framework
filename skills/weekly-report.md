<!-- skill: weekly-report | version: 2.0 -->
# Skill: Weekly Report Auto-Fill

> Slash command: `/weekly-report`
> Invoked by user typing: `/weekly-report` or asking Claude to "幫我製作本週周報"

---

## 執行流程（Claude 必須依序完成以下每個步驟）

### Step 1 — 定位腳本

腳本固定路徑：`~/.claude/framework/scripts/weekly_report.py`

PowerShell 等效路徑：`$env:USERPROFILE\.claude\framework\scripts\weekly_report.py`

用以下指令確認腳本存在：

```powershell
Test-Path "$env:USERPROFILE\.claude\framework\scripts\weekly_report.py"
```

若回傳 `False`，告知使用者：
> 腳本不存在，請執行：`git -C ~/.claude/framework pull` 後重試。

---

### Step 2 — 檢查必要環境變數

依序檢查以下三個變數是否已設定：

```powershell
echo "ANTHROPIC_API_KEY: $($env:ANTHROPIC_API_KEY -ne $null -and $env:ANTHROPIC_API_KEY -ne '')"
echo "NOCODB_PEOPLE_ID:  $($env:NOCODB_PEOPLE_ID)"
echo "GIT_REPOS:         $($env:GIT_REPOS)"
```

**若全部已設定 → 跳至 Step 4**

**若有任何一個未設定 → 執行 Step 3（互動引導）**

---

### Step 3 — 首次設定引導（僅在環境變數未設定時執行）

#### 3a. ANTHROPIC_API_KEY

若未設定，詢問使用者：
> 請輸入你的 Anthropic API Key（格式：`sk-ant-...`）：

取得後暫存：`$env:ANTHROPIC_API_KEY = "<使用者輸入>"`

#### 3b. GIT_REPOS

若未設定，詢問使用者：
> 請輸入你的 incubator repo 本機路徑（例：`C:\Users\yourname\incubator`）：

取得後暫存：`$env:GIT_REPOS = "<使用者輸入>"`

#### 3c. NOCODB_PEOPLE_ID

若未設定，先執行查詢指令讓使用者確認自己的 ID：

```powershell
python "$env:USERPROFILE\.claude\framework\scripts\weekly_report.py" --list-people
```

輸出範例：
```
員工列表（設定 NOCODB_PEOPLE_ID=<你的 Id>）:
  Id=  47  楊哲綸
  Id=  48  陳○○
  Id=  49  林○○
```

詢問使用者：
> 請輸入你的員工 ID（從上方列表確認）：

取得後暫存：`$env:NOCODB_PEOPLE_ID = "<使用者輸入>"`

#### 3d. 詢問是否永久寫入 PowerShell Profile

```
是否將這些設定永久寫入 PowerShell Profile？(y/n)
```

若選 `y`，執行：

```powershell
Add-Content $PROFILE "`n# Weekly Report Config"
Add-Content $PROFILE "`$env:ANTHROPIC_API_KEY = '<值>'"
Add-Content $PROFILE "`$env:NOCODB_PEOPLE_ID = '<值>'"
Add-Content $PROFILE "`$env:GIT_REPOS = '<值>'"
```

並告知：
> 已寫入 Profile，下次開啟 PowerShell 自動生效。

---

### Step 4 — 乾跑預覽

執行腳本（不送出），讓使用者確認內容：

```powershell
python "$env:USERPROFILE\.claude\framework\scripts\weekly_report.py"
```

顯示輸出後詢問：
> 以上是本週將送出的工作項目，確認送出嗎？(y/n)

---

### Step 5 — 送出周報

若使用者確認，執行：

```powershell
python "$env:USERPROFILE\.claude\framework\scripts\weekly_report.py" --submit
```

成功後顯示：
> 周報已送出！可至工作日誌系統確認。

若使用者說「已送出過，要重建」，改用：

```powershell
python "$env:USERPROFILE\.claude\framework\scripts\weekly_report.py" --submit --force
```

---

## 環境需求（首次使用前確認）

```powershell
pip install anthropic httpx
```

Python 3.10+

---

## 快速觸發範例

使用者輸入任何以下表達，Claude 都應啟動此 skill：

- `/weekly-report`
- `幫我做本週周報`
- `幫我填寫工作日誌`
- `製作這週的週報並上傳`
