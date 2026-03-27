<!-- version: 2.1 | framework: ai-dev-framework -->
# Testing Guide

## 1. 測試金字塔 (Testing Pyramid)
* **Unit Tests (70%)**：測試單一邏輯單元，需 mock 外部依賴，執行速度必須在毫秒級。
* **Integration Tests (20%)**：測試多個模組間的協作，通常涉及真實的資料庫（使用 Testcontainers）。
* **E2E Tests (10%)**：模擬真實用戶操作（如 Playwright/Cypress），只針對 Critical Path（註冊、支付）。

## 2. 測試準則 (F.I.R.S.T)
* **Fast**：測試運行的速度要快，否則開發者會不想跑。
* **Independent**：測試案例之間不能有依賴順序，每個測試應重置環境。
* **Repeatable**：在任何環境（本地、CI）運行的結果應一致。
* **Self-Validating**：測試應自動判斷 Pass/Fail，不需要人工查看 Log。
* **Timely**：測試應隨功能開發同步撰寫（鼓勵 TDD 或測試先行）。

## 3. 命名與結構
* **描述性名稱**：`should_return_401_when_token_is_expired` 而非 `test_auth_fail`。
* **AAA 模式**：
    * **Arrange**：準備測試數據。
    * **Act**：執行目標代碼。
    * **Assert**：驗證結果。

## 4. 涵蓋率 (Coverage)
* **全域要求**：Line Coverage 應保持在 80% 以上。
* **核心業務**：涉及金流、權限的代碼必須 100% 覆蓋邊界情況。