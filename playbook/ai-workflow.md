<!-- version: 2.1 | framework: ai-dev-framework -->
# AI-Assisted Development Workflow

## 1. 工具鏈
* **Editor**: Cursor / VS Code with GitHub Copilot.
* **LLM**: Claude 3.5 Sonnet (建議用於邏輯與架構) / GPT-4o (建議用於腳本與工具)，隨時更新最新模型版本

## 2. AI 使用規範 (Human-in-the-loop)
* **AI 負責草稿，人類負責審查**：任何 AI 產出的代碼，開發者必須能解釋其邏輯。
* **安全性檢查**：嚴禁將公司敏感金鑰 (API Keys)、客戶隱私數據輸入公有 AI 模型。
* **小步快跑**：不要一次給 AI 太大的任務。將任務拆解成「定義接口 -> 實作邏輯 -> 撰寫測試」。

## 3. 提示詞工程 (Prompting)
* **給予角色**：例如「你是一位資深的 Golang 工程師，注重併發安全」。
* **提供上下文**：附上相關的 `.md` 規範文件，讓 AI 產出符合團隊風格的代碼。
* **範例導向**：給 AI 一個現有的好代碼範例，讓它模仿。

## 4. 代碼評審 (AI Code Review)
* 在提交 PR 前，建議先將代碼餵給 AI，詢問：「這段代碼是否有潛在的效能問題或邊界漏洞？」。