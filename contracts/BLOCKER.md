# Contract: BLOCKER

**由誰產出**：Architect / Coder / QA / Auditor Agent（任一遇到卡關的 agent）
**由誰接收**：Lead Agent
**用途**：正式記錄任務卡關原因、解除條件，以及 agent 的建議行動。
任務一旦發出 BLOCKER，必須暫停所有工作，等 Lead 或人類解除後才能繼續。

---

## BLOCKER 類型分類

| 類型 | 適用 Agent | 觸發條件範例 |
|---|---|---|
| `SCOPE_TOO_LARGE` | Architect | 變更涉及 8 個以上模組，超出 L2 範圍；需拆分任務 |
| `MISSING_DOMAIN_KNOWLEDGE` | Architect | 無法評估金融/安全風險，缺少現有業務邏輯的背景知識 |
| `SPEC_CONFLICT` | Coder | 合約 §Interface Contract 與現有代碼 API 直接矛盾 |
| `IMPLEMENTATION_DIVERGENCE` | Coder | 正確實作需要修改 SPEC_SHEET §Files Expected 未列的檔案（超過 2 個） |
| `FUNDAMENTAL_COVERAGE_GAP` | QA | 關鍵路徑在現有架構下無法測試（非代碼問題，是 spec 問題） |
| `ARCHITECTURE_DRIFT` | Auditor | IMPLEMENTATION_LOG 的實際修改與 SPEC_SHEET 的預期差異過大 |
| `UNVERIFIABLE_FINANCIAL_LOGIC` | Auditor | 缺少外部規格（如交易所規則），無法驗證金融計算的正確性 |

---

## 模板

```markdown
## BLOCKER：{任務名稱}（#{issue}）

**Agent**：{agent 名稱}
**日期**：{date}
**類型**：SCOPE_TOO_LARGE | MISSING_DOMAIN_KNOWLEDGE | SPEC_CONFLICT |
         IMPLEMENTATION_DIVERGENCE | FUNDAMENTAL_COVERAGE_GAP |
         ARCHITECTURE_DRIFT | UNVERIFIABLE_FINANCIAL_LOGIC

---

### 卡關描述

{具體說明什麼無法繼續執行，以及原因。
 引用具體的檔案路徑、章節編號、或代碼行數，讓 Lead 能快速定位問題。}

### 解除卡關所需

{明確的需求。範例：
 - 「需要 Architect 澄清 §Interface Contract §2.3 的 return type」
 - 「需要人類確認：order_adapter.py 的現有 API 是否可以被修改」
 - 「任務範圍必須縮減：只修改 file_a.py，排除 file_b.py 和 file_c.py」}

### Agent 建議

{從以下選一個，並說明理由：}
- **ADJUST_SCOPE**：縮減任務範圍後可繼續
- **PROVIDE_INFO**：補充指定資訊後可繼續
- **ESCALATE_TO_HUMAN**：Lead 無法自行解決，需要人類決策
- **CLOSE_TASK**：此任務超出目前可執行的範圍，建議關閉並重新開票

### 已完成的工作（避免遺失）

{目前為止已完成工作的摘要。確保任務恢復時不需從頭開始。
 若尚未開始任何工作，填「尚未開始」。}
```

---

## BLOCKER 處理流程

```
Agent 發現 BLOCKER 條件
  ↓
1. 寫 BLOCKER.md 到 .agents/working/#{issue}/BLOCKER.md
2. 停止所有工作（不得猜測或繼續）
3. 回報 Lead：
   "{Agent} → Lead：#{issue} 發生 BLOCKER，類型：{type}。
    已暫停。詳見 .agents/working/#{issue}/BLOCKER.md。"

Lead 接收 BLOCKER
  ↓
評估：Lead 能自行解決嗎？
  是 → 補充說明，在 team_status.md 記錄決策，重新派發同一 agent
       "Lead → {Agent}：BLOCKER #{issue} 已解除。{具體說明}。請繼續。"
  否 → 附上 BLOCKER.md 內容，升級到人類：
       "Lead → Human：#{issue} 遇到 {type} BLOCKER，需要你的決策。
        問題：{卡關描述摘要}
        Agent 建議：{ADJUST_SCOPE | PROVIDE_INFO | ESCALATE | CLOSE}
        詳見 .agents/working/#{issue}/BLOCKER.md"

人類決策
  ↓
  縮小範圍 → Lead 更新 TASK_CARD，重新派發 Architect（L2/L3）或 Coder（L1）
  補充資訊 → Lead 將資訊附在 SPEC_SHEET Amendment，重新派發原 agent
  關閉任務 → Lead 在 team_status.md 標記 CLOSED，通知人類
```

---

## Lead 的 BLOCKER 回應規則

- NEVER 忽略 BLOCKER — 必須回應，不可靜默繞過
- NEVER 自行猜測解決方案而不告知 agent — 變更必須明確記錄
- NEVER 讓任務在 BLOCKER 狀態下繼續執行其他步驟
- ALWAYS 在 team_status.md 的 Decision Log 記錄 BLOCKER 收到和解除的時間點
