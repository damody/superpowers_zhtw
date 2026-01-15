# 測試反模式

**載入此參考文檔的時機:** 撰寫或修改測試、添加 mock、或將測試專用方法添加到生產代碼時。

## 概述

測試必須驗證真實行為，而非 mock 行為。Mock 是隔離的工具，不是被測試的對象。

**核心原則:** 測試代碼的實際行為，不要測試 mock 的行為。

**遵循嚴格的 TDD 可以防止這些反模式出現。**

## 鐵律

```
1. 絕不測試 mock 行為
2. 絕不向生產類中添加測試專用方法
3. 絕不在不理解依賴關係的情況下進行 mock
```

## 反模式 1: 測試 Mock 行為

**違反情況:**
```typescript
// ❌ 錯誤: 測試 mock 是否存在
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});
```

**為什麼這是錯誤的:**
- 你驗證的是 mock 是否有效，而不是組件是否有效
- 當 mock 存在時測試通過，當它不存在時失敗
- 對真實行為一無所知

**你的人類合作夥伴的糾正:** "我們是在測試 mock 的行為嗎?"

**修正方法:**
```typescript
// ✅ 正確: 測試真實組件或不進行 mock
test('renders sidebar', () => {
  render(<Page />);  // 不要 mock sidebar
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});

// 或者如果 sidebar 必須被 mock 以進行隔離:
// 不要斷言 mock - 在 sidebar 存在的情況下測試 Page 的行為
```

### 門控函數

```
在斷言任何 mock 元素之前:
  問: "我是在測試真實組件行為，還是只在測試 mock 是否存在?"

  如果在測試 mock 是否存在:
    停止 - 刪除斷言或移除組件的 mock

  改為測試真實行為
```

## 反模式 2: 生產代碼中的測試專用方法

**違反情況:**
```typescript
// ❌ 錯誤: destroy() 僅在測試中使用
class Session {
  async destroy() {  // 看起來像生產 API!
    await this._workspaceManager?.destroyWorkspace(this.id);
    // ... 清理
  }
}

// 在測試中
afterEach(() => session.destroy());
```

**為什麼這是錯誤的:**
- 生產類被測試專用代碼污染
- 如果在生產環境中意外調用會很危險
- 違反了 YAGNI 原則和關注點分離
- 混淆了對象生命週期與實體生命週期

**修正方法:**
```typescript
// ✅ 正確: 測試工具處理測試清理
// Session 沒有 destroy() - 它在生產中是無狀態的

// 在 test-utils/ 中
export async function cleanupSession(session: Session) {
  const workspace = session.getWorkspaceInfo();
  if (workspace) {
    await workspaceManager.destroyWorkspace(workspace.id);
  }
}

// 在測試中
afterEach(() => cleanupSession(session));
```

### 門控函數

```
在向生產類添加任何方法之前:
  問: "這是否僅由測試使用?"

  如果是:
    停止 - 不要添加它
    改為將其放在測試工具中

  問: "這個類是否擁有此資源的生命週期?"

  如果否:
    停止 - 這個類不適合此方法
```

## 反模式 3: 不理解依賴關係的情況下進行 Mock

**違反情況:**
```typescript
// ❌ 錯誤: Mock 破壞測試邏輯
test('detects duplicate server', () => {
  // Mock 阻止了測試依賴的配置寫入!
  vi.mock('ToolCatalog', () => ({
    discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
  }));

  await addServer(config);
  await addServer(config);  // 應該拋出異常 - 但不會!
});
```

**為什麼這是錯誤的:**
- 被 mock 的方法具有測試依賴的副作用(寫入配置)
- "為了安全" 過度 mock 會破壞實際行為
- 測試因錯誤的原因通過或神秘地失敗

**修正方法:**
```typescript
// ✅ 正確: 在正確的層級進行 mock
test('detects duplicate server', () => {
  // Mock 緩慢的部分，保留測試需要的行為
  vi.mock('MCPServerManager'); // 只 mock 緩慢的伺服器啟動

  await addServer(config);  // 配置已寫入
  await addServer(config);  // 檢測到重複 ✓
});
```

### 門控函數

```
在 mock 任何方法之前:
  停止 - 還不要 mock

  1. 問: "真實方法具有什麼副作用?"
  2. 問: "此測試是否依賴於這些副作用中的任何一個?"
  3. 問: "我是否完全理解此測試需要什麼?"

  如果依賴於副作用:
    在更低層級進行 mock (實際的緩慢/外部操作)
    或使用保留必要行為的測試雙倍物件
    不要 mock 測試依賴的高層級方法

  如果不確定測試依賴什麼:
    先用真實實現運行測試
    觀察實際需要發生什麼
    然後在正確的層級添加最少的 mock

  紅旗:
    - "我會 mock 這個以保安全"
    - "這可能很慢，最好 mock 它"
    - 在不理解依賴關係鏈的情況下進行 mock
```

## 反模式 4: 不完整的 Mock

**違反情況:**
```typescript
// ❌ 錯誤: 部分 mock - 僅包含你認為需要的字段
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' }
  // 缺少: 下游代碼使用的元數據
};

// 稍後: 當代碼訪問 response.metadata.requestId 時中斷
```

**為什麼這是錯誤的:**
- **部分 mock 隱藏了結構假設** - 你只 mock 了你知道的字段
- **下游代碼可能依賴於你沒有包含的字段** - 無聲失敗
- **測試通過但集成失敗** - Mock 不完整，真實 API 完整
- **虛假的信心** - 測試無法證明任何真實行為

**鐵律:** Mock 現實中存在的完整數據結構，而不僅僅是你當前測試使用的字段。

**修正方法:**
```typescript
// ✅ 正確: 反映真實 API 的完整性
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' },
  metadata: { requestId: 'req-789', timestamp: 1234567890 }
  // 真實 API 返回的所有字段
};
```

### 門控函數

```
在創建 mock 響應之前:
  檢查: "真實 API 響應包含哪些字段?"

  行動:
    1. 檢查文檔/示例中的實際 API 響應
    2. 包含系統可能在下游消費的所有字段
    3. 驗證 mock 與真實響應架構完全匹配

  關鍵:
    如果你創建 mock，你必須理解整個結構
    當代碼依賴於省略的字段時，部分 mock 會無聲地失敗

  如果不確定: 包含所有記錄的字段
```

## 反模式 5: 集成測試作為事後考慮

**違反情況:**
```
✅ 實現完成
❌ 沒有寫測試
"準備好測試"
```

**為什麼這是錯誤的:**
- 測試是實現的一部分，不是可選的後續工作
- TDD 會捕捉這個
- 沒有測試不能聲稱完成

**修正方法:**
```
TDD 循環:
1. 寫失敗的測試
2. 實現以通過
3. 重構
4. 然後聲稱完成
```

## 當 Mock 變得太複雜時

**警告標誌:**
- Mock 設置比測試邏輯更長
- 為了讓測試通過而 mock 一切
- Mock 缺少真實組件具有的方法
- 當 mock 更改時測試中斷

**你的人類合作夥伴的問題:** "我們真的需要在這裡使用 mock 嗎?"

**考慮:** 使用真實組件的集成測試通常比複雜的 mock 更簡單

## TDD 防止這些反模式

**TDD 為什麼有幫助:**
1. **先寫測試** → 強制你思考你實際在測試什麼
2. **看它失敗** → 確認測試測試的是真實行為，而不是 mock
3. **最小實現** → 沒有測試專用方法蔓延
4. **真實依賴** → 在 mock 之前，你看到測試實際需要什麼

**如果你在測試 mock 行為，你違反了 TDD** - 你在沒有看到測試對真實代碼失敗的情況下添加了 mock。

## 快速參考

| 反模式 | 修正方法 |
|---------|---------|
| 在 mock 元素上斷言 | 測試真實組件或移除 mock |
| 生產中的測試專用方法 | 移至測試工具 |
| 不理解依賴關係的 mock | 先理解依賴，最少 mock |
| 不完整的 mock | 完全反映真實 API |
| 測試作為事後考慮 | TDD - 先測試 |
| 過度複雜的 mock | 考慮集成測試 |

## 紅旗

- 斷言檢查 `*-mock` 測試 ID
- 方法僅在測試文件中調用
- Mock 設置超過 50% 的測試
- 移除 mock 時測試失敗
- 無法解釋為什麼需要 mock
- "為了安全" 進行 mock

## 底線

**Mock 是隔離的工具，不是要測試的對象。**

如果 TDD 透露你在測試 mock 行為，你出問題了。

修正: 測試真實行為，或質疑為什麼你首先要進行 mock。
