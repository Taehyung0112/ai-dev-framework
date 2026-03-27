<!-- version: 2.1 | framework: ai-dev-framework -->
# Code Quality & Architecture Standards

> 本文件基於 incubator repo 實際程式碼分析撰寫，涵蓋 C++ (528 files)、Python (132 files)、TypeScript (41 files)。
> 所有範例均來自真實的 codebase（arber、order-hub、order-gateway、cert-server-rest、freqtrade-sdk）。

---

## 1. 核心哲學

- **可讀性優先**：程式碼是寫給人讀的。優先考慮清晰，而非簡短。
- **顯性優於隱性**：邏輯必須清楚可見，避免過度 meta-programming。
- **KISS**：兩種實作方式，選維護成本更低的那種。
- **Fail Fast**：在函數入口做參數校驗，不符合條件立即中止，減少巢狀 `if`。

---

## 2. 通用命名規範

| 情境 | 規則 | 範例 |
|---|---|---|
| 布林變數 | 必須帶前綴 `is`, `has`, `can`, `should` | `isVisible`, `hasPermission`, `canUpdate` |
| 函數命名 | 動詞開頭，明確表達行為 | `fetchUserData()`, `validateEmail()`, `buildRawebRequestBody()` |
| 禁止單字母 | 僅迴圈 index 例外 | ❌ `let d = new Date()` ✅ `let currentDate = new Date()` |
| 常數 | 語言各有規範，見各語言章節 | |

---

## 3. C++ 標準

### 3.1 命名規範

| 元素 | 規範 | 範例 |
|---|---|---|
| 類別名稱 | PascalCase | `AccountAuthoriser`, `LoggerInstance`, `NewLoginRequest` |
| 方法名稱 | PascalCase | `Init()`, `Start()`, `Stop()`, `GetSymbol()`, `Authorise()` |
| 私有成員變數 | trailing underscore (snake_case_) | `running_`, `ticker_client_`, `expiry_date_` |
| 常數 / constexpr | `k` prefix + CamelCase | `kGaugeLiveness`, `kServiceLabel`, `kArber` |
| Namespace | 全小寫 | `namespace api`, `namespace metrics`, `namespace concreteservice` |
| 檔案名稱 | snake_case | `account_authoriser.h`, `channel_request.cpp` |

```cpp
// 正確示範
namespace api {

class AccountAuthoriser {
 public:
  bool Authorise(Authentication authentication, const auto& branch_account);

 private:
  std::shared_ptr<SomeService> service_;
  bool is_initialized_;
};

inline const char kMetricServerPort[] = "";

}  // namespace api
```

### 3.2 Header Guard

使用完整路徑風格（非 `#pragma once`，確保跨編譯器相容）：

```cpp
#ifndef ORDER_HUB_SRC_API_ACCOUNT_AUTHORISER_H_
#define ORDER_HUB_SRC_API_ACCOUNT_AUTHORISER_H_
// ...
#endif  // ORDER_HUB_SRC_API_ACCOUNT_AUTHORISER_H_
```

### 3.3 Include 順序

```cpp
// 1. 對應 .h 檔（若為 .cpp）
#include "my_class.h"

// 2. 系統標準庫（尖括號）
#include <memory>
#include <string>
#include <vector>

// 3. 第三方庫
#include <grpcpp/channel.h>
#include <jwt-cpp/jwt.h>

// 4. 專案內部（雙引號，完整路徑）
#include "garage/logging/logger.h"
#include "order-hub/src/traits.h"
```

### 3.4 Namespace 使用

```cpp
// 在 .cpp 內可使用 using，但不得在 .h 內使用 using namespace
// .cpp 可接受：
using grpc::Channel;
using grpc::ClientContext;

// .h 嚴禁：
// using namespace grpc;  // 污染所有 include 此 header 的檔案
```

### 3.5 記憶體管理

- 優先使用 `std::unique_ptr` / `std::shared_ptr`，避免裸指標擁有權
- 有 arena allocator 需求時使用 `std::pmr::monotonic_buffer_resource`（參考 `account_authoriser.h`）
- `std::pmr::string` 搭配 local buffer 避免小字串 heap 分配

### 3.6 Thread Safety

- 共用狀態必須加鎖（`std::mutex` 或 `std::shared_mutex`）
- 需要同執行緒可重入時用 `std::recursive_mutex`（`RLock` 等價）
- Callback 來自 C++ thread 時，所有 shared state mutation 必須在鎖內進行
- 公開說明 thread safety 保證（在 class docstring 或 NOTE 中）

### 3.7 Logging

使用 `garage/logging/logger.h` 的 `LoggerInstance`，等級從低到高：
`Trace` → `Debug` → `Info` → `Warn` → `Error` → `Fatal`

```cpp
#include "garage/logging/logger.h"

// 在 class 或 file scope 建立 logger
logging::LoggerInstance logger_{"MyClassName", logging::INFO_LOG_LEVEL};

// 使用
logger_.Info("Connection established");
logger_.Warnf("Retry %d/%d", retry_count, max_retries);
logger_.Error("Unexpected state: order_id=" + order_id);
```

### 3.8 TODO / NOTE / FIXME 格式

```cpp
// TODO(author): 需要完成的事項
// TODO(brendan): this will be renamed to LoginRequest after all refactoring is done.

// NOTE: 解釋非顯而易見的設計決策
// NOTE: RLock (reentrant) is required because tick_aggregator's property
//       calls self.ticker internally while already holding _init_lock.

// FIXME: 已知問題，尚未修復
```

---

## 4. Python 標準

### 4.1 命名規範

| 元素 | 規範 | 範例 |
|---|---|---|
| 類別名稱 | PascalCase | `CcxtConcordsShim`, `OrderTracker`, `ConcordsConnection` |
| 函數 / 方法 | snake_case | `load_markets()`, `get_tick_size()`, `round_to_tick()` |
| 私有成員 | 單底線前綴 | `_config`, `_ticker`, `_init_lock`, `_orders` |
| 模組級常數 | UPPER_SNAKE_CASE | `SUPPORTED_TIMEFRAMES`, `TSE_TICK_TABLE`, `_TERMINAL_STATUSES` |
| 內部常數（模組私有） | 底線 + UPPER_SNAKE_CASE | `_TERMINAL_STATUSES`, `_SERVER_STATUS_MAP` |

### 4.2 Module Docstring

每個模組的第一行必須是描述其用途的 docstring：

```python
"""TSE/OTC tick size rules for Taiwan stocks."""

"""Async callback → sync query bridge for Concords order tracking."""

"""Fake ccxt exchange object backed by Concords SDK.

Implements the subset of the ccxt.Exchange interface that Freqtrade
actually uses, delegating to ConcordsConnection for SDK access.
"""
```

### 4.3 Type Hints

所有 public API 必須有型別標註：

```python
from __future__ import annotations  # 必須放在所有 import 之前，啟用 PEP 563

from typing import TYPE_CHECKING, Any

# 避免循環 import：僅在 TYPE_CHECKING 下 import
if TYPE_CHECKING:
    from freqtrade_concords.order.order_tracker import OrderTracker

def get_tick_size(price: float) -> float: ...

def wait_for_submit(
    self,
    user_defined_id: str,
    timeout: float = 10.0,
) -> dict | None: ...
```

### 4.4 Class Docstring — Thread Safety 聲明

當 class 有 thread safety 保證時，必須在 docstring 中明確說明：

```python
class OrderTracker:
    """Tracks order state received via Concords Stock callbacks.

    Thread safety:
      All mutations to _orders, _submit_events, _submit_results,
      _cancel_events, _cancel_results, and _transaction_to_user_id
      are performed under _lock.  Public read methods return
      shallow *copies* of stored dicts so callers cannot race with
      in-place callback updates.
    """
```

### 4.5 Logging

```python
import logging

# 使用 __name__ 作為 logger 名稱（不要 hardcode 模組名稱）
logger = logging.getLogger(__name__)

# 等級使用規範
logger.info("Initializing Concords Ticker connection")
logger.warning("wait_for_submit timeout: uid=%s", uid)   # 預期但異常的狀態
logger.error("Callback fired for unknown txn_id: %s", txn_id)  # 需要處理的錯誤
logger.debug("Order update: %s", order)  # 高頻資訊，預設不輸出
```

### 4.6 Double-Check Locking（Lazy Init 標準模式）

```python
@property
def ticker(self) -> Ticker:
    """Lazy-initialize Concords Ticker connection (thread-safe)."""
    if self._ticker is None:
        with self._init_lock:
            if self._ticker is None:  # re-check under lock
                ticker = Ticker(...)
                ticker.set_error_callback(self._on_ticker_error)
                # NOTE: Assign last — ensures other threads see a fully
                # configured object, not a partially constructed one.
                self._ticker = ticker
    return self._ticker
```

### 4.7 Comment 規範

```python
# NOTE: 說明非直覺的設計決策
# NOTE: Unreachable because the table's last threshold is float("inf").
#       Kept as an explicit guard against accidental table truncation.

# 帶 doctest 的公共函數
def get_tick_size(price: float) -> float:
    """Return the tick size for a given price level on TSE.

    >>> get_tick_size(9.5)
    0.01
    >>> get_tick_size(50.0)
    0.1
    """
```

### 4.8 格式化工具

本專案使用 **yapf** 格式化 Python 代碼（參考 commit `CHORE: apply yapf formatting to freqtrade-sdk src`）：
- 縮排：2 spaces（yapf 預設為 Google style）
- 在提交前執行 `yapf -i -r src/`

---

## 5. TypeScript 標準

### 5.1 命名規範

| 元素 | 規範 | 範例 |
|---|---|---|
| 類別 / Interface | PascalCase | `Config`, `OtpRequest`, `LoginResponse` |
| 函數 / 方法 | camelCase | `requestOtp()`, `buildRawebRequestBody()`, `getClientIp()` |
| Vue Composable | `use` 前綴 + PascalCase | `useCertApply()`, `useCrypto()`, `useDateTime()` |
| 常數（模組級） | camelCase 或 UPPER_SNAKE_CASE | `logger`, `MAX_RETRY` |
| 檔案名稱 | camelCase | `certsController.ts`, `authMiddleware.ts`, `useCertApply.ts` |

### 5.2 型別定義

- 資料形狀（物件結構）：使用 `interface`
- 聯合型別 / 字面量型別：使用 `type`
- **嚴禁 `any`**，若需靈活性使用 `unknown` 並做型別縮窄

```typescript
// 正確：interface 用於物件結構
export interface OtpRequest {
  userId: string
  transferType: OtpMethod
}

// 正確：type 用於聯合型別
export type OtpMethod = 'Email' | 'Cellphone'

// 正確：擴展 Express Request 型別
declare global {
  namespace Express {
    interface Request {
      uid?: string
    }
  }
}

// 禁止
const data: any = response.data  // ❌
```

### 5.3 API 函數型別標註

所有 API 函數必須標註回傳型別：

```typescript
// 正確
export async function requestOtp(data: OtpRequest): Promise<OtpResponse> {
  const response = await publicClient.post<OtpResponse>('/otp/requests', data)
  return response.data
}

// 禁止
export async function requestOtp(data) {  // ❌ 無型別
```

### 5.4 Logging

使用 `createLogger(module)` 建立具名 logger，而非 `console.log`：

```typescript
import { createLogger } from '../utils/logger'

const logger = createLogger('auth')        // 模組名稱（小寫）
const logger = createLogger('CertApply')   // 或 Composable 名稱（PascalCase）

// 等級使用規範：
logger.warn({ ip, method, path }, 'Missing or invalid Authorization header')
logger.warn({ err: error, ip }, 'Invalid token')   // 附帶 context object
logger.info('Server started on port %d', port)
```

### 5.5 Error Handling

```typescript
// Controller 層：try/catch + 語意明確的 HTTP 狀態碼
export const applyCert = async (req: Request, res: Response) => {
  try {
    const { cn, csr } = req.body
    const userId = req.uid

    // Fail Fast：在函數入口校驗，早點 return
    if (!userId || !cn || !csr) {
      res.status(400).json({ message: 'Missing Fields' })
      return
    }

    // ... business logic
  } catch (error) {
    logger.error({ err: error }, 'Unexpected error in applyCert')
    res.status(500).json({ message: 'Internal Server Error' })
  }
}

// Middleware 層：驗證失敗 return，不要 throw
export const authMiddleware = (req, res, next) => {
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ message: 'Missing or invalid Authorization header' })
    return  // 顯式 return，不進入 next()
  }
  // ...
}
```

### 5.6 Config Validation（Fail Fast at Startup）

所有必要的 config 在服務啟動時立即驗證，不要在 runtime 才失敗：

```typescript
// config.ts — 服務啟動時執行，缺少任何參數直接 throw
if (!values.port || typeof values.port !== 'string') {
  throw new Error('Missing required argument: --port')
}
if (!values.jwtSecretFile) {
  throw new Error('Missing required argument: --jwtSecretFile')
}
const secretPath = values.jwtSecretFile
if (!existsSync(secretPath)) {
  throw new Error(`Secret file not found: ${secretPath}`)
}
```

### 5.7 Vue Composable 結構

```typescript
export function useCertApply() {
  // 1. Form / UI / Data state（按區塊分組，附 comment）
  const userId = ref('')
  const loading = ref(false)
  const certString = ref('')

  // 2. 依賴的 composables
  const authStore = useAuthStore()
  const crypto = useCrypto()

  // 3. Actions（async function 定義）
  async function sendOtp() { ... }
  async function login() { ... }

  // 4. Return（只 expose 必要的 state + actions）
  return { userId, loading, certString, sendOtp, login }
}
```

### 5.8 Section 分隔 Comment

在長檔案中使用分隔 comment 增加可讀性：

```typescript
// === Public APIs (no JWT token required) ===
export async function requestOtp(...) { ... }

// === Protected APIs (JWT token required) ===
export async function queryCert(...) { ... }
```

---

## 6. 架構分層規範

### 6.1 後端分層（C++ / TypeScript Express）

```
Transport / Controller Layer   →  驗證 HTTP input，組裝 response
Service Layer                  →  業務邏輯，控制 transaction
Repository / Adapter Layer     →  資料存取，外部 API 呼叫
Domain / Model Layer           →  Pure logic，無 I/O 副作用
```

實際對應：
- **Controller**：`certsController.ts`, `loginController.ts`
- **Service**：`rawebService.ts`, `jwtService.ts`
- **Adapter**：`order_adapter.py`, `concords_connection.py`
- **Domain**：`tick_rules.py`, `market_hours.py`

### 6.2 禁止跨層直接存取

```
❌ Controller 直接操作 DB / SDK
❌ Domain layer 依賴 Transport 型別（如 Request/Response）
✅ 透過 Service / Repository interface 解耦
```

### 6.3 Repository Pattern（C++ SDK Adapter 等價）

```python
# ConcordsConnection = Repository layer
# 提供統一介面，隱藏 Ticker/Stock SDK 的初始化細節

class ConcordsConnection:
    @property
    def ticker(self) -> Ticker: ...  # 統一存取點
    @property
    def stock(self) -> Stock: ...
    def close(self) -> None: ...     # 統一清理
```

---

## 7. AI 生成代碼的特殊規範

- **禁止死代碼**：不生成未被呼叫的函數、未使用的 import、未使用的變數
- **不做防禦性過度包裝**：內部函數不需要重複校驗上層已校驗的參數
- **不生成 TODO 佔位函數**：AI 生成的代碼必須是可立即執行的完整實作，或明確告知 user 哪些部分需要補充
- **保留現有 comment style**：若修改現有檔案，沿用該檔案的 comment 慣例（`// NOTE:`, `# NOTE:`, `/// JSDoc`）
- **公共 API 必須有 docstring / JSDoc**：
  - Python：函數 docstring，可包含 `>>> doctest`
  - TypeScript：JSDoc `/** */` 或至少有型別完整標註
  - C++：class/public method 有 header 層級的 comment 說明用途

---

## 8. 安全紅線

以下為不可違反的硬性規則：

- **禁止 hardcode 金鑰 / 密碼 / 憑證路徑**：統一從環境變數或 config 參數讀取
- **JWT Secret 從檔案讀取，不放環境變數**（參考 cert-server-rest 的 `--jwtSecretFile` 模式）
- **密碼傳輸前必須 Hash**：TypeScript client 傳送 `userPassword` 前需 MD5 處理（見 `LoginRequest` 的 comment）
- **Rate Limiting**：所有對外 API endpoint 必須套用 `rateLimiterMiddleware`
- **Log 不得輸出敏感欄位**：user password、token、certificate private key 禁止出現在任何 log 中

---

## 9. 代碼品質自檢清單

提交前必須確認：

```
- [ ] 函數長度 < 50 行（超過代表需要拆分）
- [ ] 檔案長度 < 800 行（超過代表模組職責過重）
- [ ] 無深度巢狀 > 4 層
- [ ] 無 any 型別（TypeScript）
- [ ] 無空的 try-catch（不吞錯誤）
- [ ] 無 hardcode 金鑰或密碼
- [ ] Public API 有 docstring / 型別標註
- [ ] 新增的 class 有 thread safety 聲明（若涉及並發）
- [ ] 無未使用的 import / 變數 / 函數
- [ ] Logger 使用正確等級（warn 用於預期但異常，error 用於需要處理的錯誤）
```
