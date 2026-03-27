<!-- version: 2.1 | framework: ai-dev-framework -->
# Architecture Guide

## 1. 架構原則
* **SOLID 原則**：特別是「單一職責」與「依賴反轉」。
* **高內聚、低耦合**：模組之間應透過定義良好的 Interface 通訊。
* **DRY (Don't Repeat Yourself)**：但請注意「錯誤的抽象比重複更可怕」，不要為了重用而強行耦合不相關的業務。

## 2. 分層架構 (Layered Architecture)
我們採用邏輯分層，確保業務邏輯與基礎設施隔離：
1.  **Transport/Interface Layer**：處理 HTTP Request、驗證輸入（Controller/Resolver）。
2.  **Application/Service Layer**：核心業務邏輯所在，控制事務 (Transaction)。
3.  **Domain Layer**：業務實體與領域模型（Pure Logic）。
4.  **Infrastructure/Data Layer**：資料庫存取 (Repository)、外部 API 呼叫。

## 3. 資料庫設計
* **軟刪除 (Soft Delete)**：核心業務數據（如訂單、用戶）禁止物理刪除，統一使用 `deleted_at` 欄位。
* **索引優化**：所有查詢頻率高的欄位必須建立索引，且避免在索引欄位上使用運算。
* **資料一致性**：跨服務的資料一致性優先考慮「最終一致性 (Eventual Consistency)」。

## 4. 狀態管理 (State Management)
* **Single Source of Truth**：確保同一份數據在系統中只有一個來源。
* **不可變性 (Immutability)**：優先使用不可變數據結構，減少副作用產生的 Bug。