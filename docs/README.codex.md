# Superpowers for Codex

Superpowers 與 OpenAI Codex 搭配使用的完整指南。

## 快速安裝

告訴 Codex：

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md
```

## 手動安裝

### 先決條件

- OpenAI Codex 存取權限
- Shell 存取權限以安裝文件

### 安裝步驟

#### 1. 複製 Superpowers

```bash
mkdir -p ~/.codex/superpowers
git clone https://github.com/obra/superpowers.git ~/.codex/superpowers
```

#### 2. 安裝 Bootstrap

Bootstrap 文件已包含在存儲庫的 `.codex/superpowers-bootstrap.md` 中。Codex 將自動從複製的位置使用它。

#### 3. 驗證安裝

告訴 Codex：

```
Run ~/.codex/superpowers/.codex/superpowers-codex find-skills to show available skills
```

您應該看到可用技能及其說明的列表。

## 使用方法

### 查找技能

```
Run ~/.codex/superpowers/.codex/superpowers-codex find-skills
```

### 載入技能

```
Run ~/.codex/superpowers/.codex/superpowers-codex use-skill superpowers:brainstorming
```

### 引導所有技能

```
Run ~/.codex/superpowers/.codex/superpowers-codex bootstrap
```

這將載入包含所有技能信息的完整引導程序。

### 個人技能

在 `~/.codex/skills/` 中創建您自己的技能：

```bash
mkdir -p ~/.codex/skills/my-skill
```

創建 `~/.codex/skills/my-skill/SKILL.md`：

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

個人技能會覆蓋同名的 superpowers 技能。

## 架構

### Codex CLI 工具

**位置：** `~/.codex/superpowers/.codex/superpowers-codex`

一個 Node.js CLI 腳本，提供三個命令：
- `bootstrap` - 載入包含所有技能的完整引導程序
- `use-skill <name>` - 載入特定技能
- `find-skills` - 列出所有可用技能

### 共享核心模塊

**位置：** `~/.codex/superpowers/lib/skills-core.js`

Codex 實現使用共享的 `skills-core` 模塊（ES 模塊格式）來進行技能發現和解析。這與 OpenCode 插件使用的模塊相同，確保跨平台的一致行為。

### 工具映射

為 Claude Code 編寫的技能通過以下映射針對 Codex 進行調整：

- `TodoWrite` → `update_plan`
- `Task` with subagents → 告訴用戶 subagents 在 Codex 中不可用，直接完成工作
- `Skill` tool → `~/.codex/superpowers/.codex/superpowers-codex use-skill`
- 文件操作 → Codex 原生工具

## 更新

```bash
cd ~/.codex/superpowers
git pull
```

## 故障排除

### 找不到技能

1. 驗證安裝：`ls ~/.codex/superpowers/skills`
2. 檢查 CLI 是否運行：`~/.codex/superpowers/.codex/superpowers-codex find-skills`
3. 驗證技能有 SKILL.md 文件

### CLI 腳本無法執行

```bash
chmod +x ~/.codex/superpowers/.codex/superpowers-codex
```

### Node.js 錯誤

CLI 腳本需要 Node.js。驗證：

```bash
node --version
```

應顯示 v14 或更高版本（建議 v18+ 以支持 ES 模塊）。

## 獲取幫助

- 報告問題：https://github.com/obra/superpowers/issues
- 主文檔：https://github.com/obra/superpowers
- 部落格文章：https://blog.fsck.com/2025/10/27/skills-for-openai-codex/

## 注意

Codex 支持是實驗性的，可能需要根據用戶反饋進行調整。如果您遇到問題，請在 GitHub 上報告。
