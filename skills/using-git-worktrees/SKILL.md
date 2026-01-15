---
name: using-git-worktrees
description: 當開始需要與當前工作空間隔離的功能工作時或在執行實作計劃之前使用 - 創建具有智能目錄選擇和安全驗證的隔離 git 工作樹
---

# 使用 Git 工作樹

## 概述

Git 工作樹創建共享同一存儲庫的隔離工作空間，允許同時在多個分支上工作而無需切換。

**核心原則：** 系統性目錄選擇 + 安全驗證 = 可靠隔離。

**開始時宣告：** 「我正在使用 using-git-worktrees 技能設置隔離的工作空間。」

## 目錄選擇流程

遵循此優先順序：

### 1. 檢查現有目錄

```bash
# 按優先順序檢查
ls -d .worktrees 2>/dev/null     # 首選（隱藏）
ls -d worktrees 2>/dev/null      # 替代
```

**如果找到：** 使用該目錄。如果兩者都存在，`.worktrees` 優先。

### 2. 檢查 CLAUDE.md

```bash
grep -i "worktree.*director" CLAUDE.md 2>/dev/null
```

**如果指定了偏好：** 使用它而不詢問。

### 3. 詢問用戶

如果沒有目錄存在且 CLAUDE.md 沒有偏好：

```
未找到工作樹目錄。我應該在哪裡創建工作樹？

1. .worktrees/（專案本地，隱藏）
2. ~/.config/superpowers/worktrees/<project-name>/（全局位置）

您更喜歡哪個？
```

## 安全驗證

### 對於專案本地目錄（.worktrees 或 worktrees）

**必須在創建工作樹之前驗證目錄被忽略：**

```bash
# 檢查目錄是否被忽略（尊重本地、全局和系統 gitignore）
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**如果未被忽略：**

根據 Jesse 的規則「立即修復損壞的事物」：
1. 將適當的行添加到 .gitignore
2. 提交更改
3. 繼續創建工作樹

**為什麼關鍵：** 防止意外將工作樹內容提交到存儲庫。

### 對於全局目錄（~/.config/superpowers/worktrees）

無需 .gitignore 驗證 - 完全在專案外部。

## 創建步驟

### 1. 檢測專案名稱

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

### 2. 創建工作樹

```bash
# 確定完整路徑
case $LOCATION in
  .worktrees|worktrees)
    path="$LOCATION/$BRANCH_NAME"
    ;;
  ~/.config/superpowers/worktrees/*)
    path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
    ;;
esac

# 使用新分支創建工作樹
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

### 3. 運行專案設置

自動檢測並運行適當的設置：

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 4. 驗證乾淨基線

運行測試以確保工作樹以乾淨狀態開始：

```bash
# 範例 - 使用適合專案的命令
npm test
cargo test
pytest
go test ./...
```

**如果測試失敗：** 報告失敗，詢問是繼續還是調查。

**如果測試通過：** 報告就緒。

### 5. 報告位置

```
工作樹就緒於 <full-path>
測試通過（<N> 個測試，0 個失敗）
準備實作 <feature-name>
```

## 快速參考

| 情況 | 行動 |
|------|------|
| `.worktrees/` 存在 | 使用它（驗證已忽略）|
| `worktrees/` 存在 | 使用它（驗證已忽略）|
| 兩者都存在 | 使用 `.worktrees/` |
| 都不存在 | 檢查 CLAUDE.md → 詢問用戶 |
| 目錄未被忽略 | 添加到 .gitignore + 提交 |
| 基線測試失敗 | 報告失敗 + 詢問 |
| 無 package.json/Cargo.toml | 跳過依賴安裝 |

## 常見錯誤

### 跳過忽略驗證

- **問題：** 工作樹內容被追蹤，污染 git status
- **修復：** 在創建專案本地工作樹之前總是使用 `git check-ignore`

### 假設目錄位置

- **問題：** 創建不一致，違反專案慣例
- **修復：** 遵循優先級：現有 > CLAUDE.md > 詢問

### 在測試失敗時繼續

- **問題：** 無法區分新 bug 和預先存在的問題
- **修復：** 報告失敗，獲得明確許可繼續

### 硬編碼設置命令

- **問題：** 在使用不同工具的專案上中斷
- **修復：** 從專案文件自動檢測（package.json 等）

## 工作流程範例

```
您：我正在使用 using-git-worktrees 技能設置隔離的工作空間。

[檢查 .worktrees/ - 存在]
[驗證已忽略 - git check-ignore 確認 .worktrees/ 已忽略]
[創建工作樹：git worktree add .worktrees/auth -b feature/auth]
[運行 npm install]
[運行 npm test - 47 個通過]

工作樹就緒於 /Users/jesse/myproject/.worktrees/auth
測試通過（47 個測試，0 個失敗）
準備實作 auth 功能
```

## 紅旗警示

**絕不：**
- 在不驗證已忽略的情況下創建工作樹（專案本地）
- 跳過基線測試驗證
- 在測試失敗時不詢問就繼續
- 在模糊時假設目錄位置
- 跳過 CLAUDE.md 檢查

**總是：**
- 遵循目錄優先級：現有 > CLAUDE.md > 詢問
- 驗證專案本地目錄已忽略
- 自動檢測並運行專案設置
- 驗證乾淨的測試基線

## 整合

**被調用：**
- **brainstorming**（階段 4）- 設計批准且實作跟隨時必需
- 任何需要隔離工作空間的技能

**配對使用：**
- **finishing-a-development-branch** - 工作完成後清理所需
- **executing-plans** 或 **subagent-driven-development** - 工作在此工作樹中進行
