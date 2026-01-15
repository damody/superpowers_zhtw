# 深度防禦驗證

## 概述

當你修復由無效資料引起的錯誤時,在一個地方添加驗證似乎就足夠了。但該單一檢查可能被不同的程式碼路徑、重構或模擬繞過。

**核心原則：** 在資料通過的每一層驗證。使錯誤在結構上不可能發生。

## 為什麼需要多層

單層驗證："我們修復了錯誤"
多層驗證："我們使錯誤在結構上不可能"

不同層會捕捉到不同的情況:
- 入口驗證捕捉大多數錯誤
- 業務邏輯驗證捕捉邊界情況
- 環境守衛防止上下文特定的危險
- 除錯日誌在其他層失效時提供幫助

## 四層結構

### 第 1 層：入口點驗證
**目的：** 在 API 邊界拒絕明顯無效的輸入

```typescript
function createProject(name: string, workingDirectory: string) {
  if (!workingDirectory || workingDirectory.trim() === '') {
    throw new Error('workingDirectory cannot be empty');
  }
  if (!existsSync(workingDirectory)) {
    throw new Error(`workingDirectory does not exist: ${workingDirectory}`);
  }
  if (!statSync(workingDirectory).isDirectory()) {
    throw new Error(`workingDirectory is not a directory: ${workingDirectory}`);
  }
  // ... 繼續
}
```

### 第 2 層：業務邏輯驗證
**目的：** 確保資料對此操作有意義

```typescript
function initializeWorkspace(projectDir: string, sessionId: string) {
  if (!projectDir) {
    throw new Error('projectDir required for workspace initialization');
  }
  // ... 繼續
}
```

### 第 3 層：環境守衛
**目的：** 防止在特定上下文中執行危險操作

```typescript
async function gitInit(directory: string) {
  // 在測試中,拒絕在臨時目錄外執行 git init
  if (process.env.NODE_ENV === 'test') {
    const normalized = normalize(resolve(directory));
    const tmpDir = normalize(resolve(tmpdir()));

    if (!normalized.startsWith(tmpDir)) {
      throw new Error(
        `Refusing git init outside temp dir during tests: ${directory}`
      );
    }
  }
  // ... 繼續
}
```

### 第 4 層：除錯檢測
**目的：** 捕捉上下文以用於取證

```typescript
async function gitInit(directory: string) {
  const stack = new Error().stack;
  logger.debug('About to git init', {
    directory,
    cwd: process.cwd(),
    stack,
  });
  // ... 繼續
}
```

## 應用模式

當你發現一個錯誤時:

1. **追蹤資料流** - 壞值從何處發生?在何處使用?
2. **標記所有檢查點** - 列出資料通過的每一點
3. **在每一層添加驗證** - 入口、業務、環境、除錯
4. **測試每一層** - 嘗試繞過第 1 層,驗證第 2 層是否捕捉到

## 來自會話的範例

錯誤: 空的 `projectDir` 導致在原始程式碼中執行 `git init`

**資料流:**
1. 測試設置 → 空字符串
2. `Project.create(name, '')`
3. `WorkspaceManager.createWorkspace('')`
4. `git init` 在 `process.cwd()` 中執行

**添加的四層:**
- 第 1 層: `Project.create()` 驗證非空/存在/可寫
- 第 2 層: `WorkspaceManager` 驗證 projectDir 非空
- 第 3 層: `WorktreeManager` 在測試中拒絕在 tmpdir 外執行 git init
- 第 4 層: 在 git init 前的堆棧追蹤日誌

**結果:** 所有 1847 個測試通過,錯誤不可能重現

## 關鍵洞察

所有四層都是必要的。在測試期間,每一層都捕捉到其他層遺漏的錯誤:
- 不同的程式碼路徑繞過了入口驗證
- 模擬繞過了業務邏輯檢查
- 不同平台上的邊界情況需要環境守衛
- 除錯日誌識別了結構濫用

**不要止步於一個驗證點。** 在每一層添加檢查。
