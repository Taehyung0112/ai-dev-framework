<!-- version: 2.1 | framework: ai-dev-framework -->
# Team Engineering Standards

## 1. 核心哲學 (Core Philosophy)
* **代碼是寫給人看的**：優化閱讀體驗，而非寫作速度。
* **顯性優於隱性**：邏輯應清晰可見，避免過度使用神奇的黑魔法（如過度複雜的 Meta-programming）。
* **保持簡單 (KISS)**：如果一個功能有兩種實現方式，選擇維護成本較低的那種。

## 2. 命名規範 (Naming Conventions)
* **具備描述性**：嚴禁使用單字母變數（迴圈 index `i`, `j` 除外）。
    * ❌ `let d = new Date();`
    * ✅ `let currentDate = new Date();`
* **布林值命名**：必須帶有前綴，如 `is`, `has`, `can`, `should`。
    * 例：`isVisible`, `hasPermission`, `canUpdate`。
* **函數命名**：應以動詞開頭，明確表示行為。
    * 例：`fetchUserData()`, `validateEmail()`, `convertCurrency()`。

## 3. 代碼風格 (Code Style)
* **自動化格式化**：專案必須包含 `.prettierrc` 或 `.eslintrc`，並在 Pre-commit Hook 強制執行。
* **縮排與長度**：統一使用 2 或 4 空格（依專案規定），單行代碼建議不超過 100 字元。
* **註解規範**：
    * 不要描述「程式碼在做什麼」（Code tells you how, comments tell you why）。
    * 針對複雜演算法或業務邏輯的「特殊坑」必須撰寫 `// NOTE:` 或 `// FIXME:`。

## 4. 錯誤處理 (Error Handling)
* **嚴禁吞掉錯誤**：不要使用空的 `catch {}`。
* **自定義錯誤**：重要業務邏輯應建立自定義 Error Class，並攜帶正確的狀態碼。
* **Fail Fast**：在函數開始處進行參數校驗，不符合則立即拋錯或回傳，減少巢狀 `if`。

## 5. 文件化 (Documentation)
* **README**：每個 Repos 必須有包含「如何啟動」、「環境變數」、「架構圖」的 README。
* **JSDoc/TSDoc**：Public API 或複雜 Function 必須撰寫註解標明輸入與輸出。