# Superpowers for OpenCode

Superpowers 與 [OpenCode.ai](https://opencode.ai) 搭配使用的完整指南。

## 快速安裝

告訴 OpenCode：

```
Clone https://github.com/obra/superpowers to ~/.config/opencode/superpowers, then create directory ~/.config/opencode/plugin, then symlink ~/.config/opencode/superpowers/.opencode/plugin/superpowers.js to ~/.config/opencode/plugin/superpowers.js, then restart opencode.
```

## 手動安裝

### 先決條件

- [OpenCode.ai](https://opencode.ai) 已安裝
- Node.js 已安裝
- Git 已安裝

### 安裝步驟

#### 1. 安裝 Superpowers

```bash
mkdir -p ~/.config/opencode/superpowers
git clone https://github.com/obra/superpowers.git ~/.config/opencode/superpowers
```

#### 2. 註冊插件

OpenCode 從 `~/.config/opencode/plugin/` 中發現插件。創建符號連結：

```bash
mkdir -p ~/.config/opencode/plugin
ln -sf ~/.config/opencode/superpowers/.opencode/plugin/superpowers.js ~/.config/opencode/plugin/superpowers.js
```

或者，用於專案本地安裝：

```bash
# 在您的 OpenCode 專案中
mkdir -p .opencode/plugin
ln -sf ~/.config/opencode/superpowers/.opencode/plugin/superpowers.js .opencode/plugin/superpowers.js
```

#### 3. 重新啟動 OpenCode

重新啟動 OpenCode 以載入插件。Superpowers 將自動啟動。

## 使用方法

### 查找技能

使用 `find_skills` 工具列出所有可用技能：

```
use find_skills tool
```

### 載入技能

使用 `use_skill` 工具載入特定技能：

```
use use_skill tool with skill_name: "superpowers:brainstorming"
```

技能會自動插入對話中，並在上下文壓縮時保持存在。

### 個人技能

在 `~/.config/opencode/skills/` 中創建您自己的技能：

```bash
mkdir -p ~/.config/opencode/skills/my-skill
```

創建 `~/.config/opencode/skills/my-skill/SKILL.md`：

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

### 專案技能

在您的 OpenCode 專案中創建專案特定技能：

```bash
# 在您的 OpenCode 專案中
mkdir -p .opencode/skills/my-project-skill
```

創建 `.opencode/skills/my-project-skill/SKILL.md`：

```markdown
---
name: my-project-skill
description: Use when [condition] - [what it does]
---

# My Project Skill

[Your skill content here]
```

## 技能優先級

技能按以下優先級順序解析：

1. **專案技能** (`.opencode/skills/`) - 最高優先級
2. **個人技能** (`~/.config/opencode/skills/`)
3. **Superpowers 技能** (`~/.config/opencode/superpowers/skills/`)

您可以強制解析到特定級別：
- `project:skill-name` - 強制專案技能
- `skill-name` - 搜索專案 → 個人 → superpowers
- `superpowers:skill-name` - 強制 superpowers 技能

## 功能特點

### 自動上下文注入

插件通過 chat.message 鉤子在每個會話上自動注入 superpowers 上下文。無需手動配置。

### 消息插入模式

當您使用 `use_skill` 載入技能時，它將作為設置了 `noReply: true` 的用戶消息插入。這確保技能在長對話中保持存在，即使在 OpenCode 壓縮上下文時也不例外。

### 壓縮恢復力

插件偵聽 `session.compacted` 事件，並自動重新注入核心 superpowers 引導程序以在上下文壓縮後維持功能。

### 工具映射

為 Claude Code 編寫的技能會自動為 OpenCode 調整。插件提供映射說明：

- `TodoWrite` → `update_plan`
- `Task` with subagents → OpenCode 的 `@mention` 系統
- `Skill` tool → `use_skill` 自訂工具
- 文件操作 → OpenCode 原生工具

## 架構

### 插件結構

**位置：** `~/.config/opencode/superpowers/.opencode/plugin/superpowers.js`

**組件：**
- 兩個自訂工具：`use_skill`、`find_skills`
- 用於初始上下文注入的 chat.message 鉤子
- 用於會話壓縮重新注入的事件處理程序
- 使用共享 `lib/skills-core.js` 模塊（Codex 也使用）

### 共享核心模塊

**位置：** `~/.config/opencode/superpowers/lib/skills-core.js`

**功能：**
- `extractFrontmatter()` - 解析技能元數據
- `stripFrontmatter()` - 從內容中移除元數據
- `findSkillsInDir()` - 遞迴技能發現
- `resolveSkillPath()` - 技能解析及遮蔽
- `checkForUpdates()` - Git 更新檢測

此模塊在 OpenCode 和 Codex 實現之間共享以進行代碼重用。

## 更新

```bash
cd ~/.config/opencode/superpowers
git pull
```

重新啟動 OpenCode 以載入更新。

## 故障排除

### 插件未載入

1. 檢查插件文件是否存在：`ls ~/.config/opencode/superpowers/.opencode/plugin/superpowers.js`
2. 檢查符號連結：`ls -l ~/.config/opencode/plugin/superpowers.js`
3. 檢查 OpenCode 日誌：`opencode run "test" --print-logs --log-level DEBUG`
4. 查找：`service=plugin path=file:///.../superpowers.js loading plugin`

### 找不到技能

1. 驗證技能目錄：`ls ~/.config/opencode/superpowers/skills`
2. 使用 `find_skills` 工具查看發現的內容
3. 檢查技能結構：每個技能都需要有 `SKILL.md` 文件

### 工具不工作

1. 驗證插件已載入：檢查 OpenCode 日誌中的插件載入消息
2. 檢查 Node.js 版本：插件需要 Node.js 以支持 ES 模塊
3. 手動測試插件：`node --input-type=module -e "import('file://~/.config/opencode/plugin/superpowers.js').then(m => console.log(Object.keys(m)))"`

### 上下文未注入

1. 檢查 chat.message 鉤子是否運行
2. 驗證 using-superpowers 技能是否存在
3. 檢查 OpenCode 版本（需要支持插件的最新版本）

## 獲取幫助

- 報告問題：https://github.com/obra/superpowers/issues
- 主文檔：https://github.com/obra/superpowers
- OpenCode 文檔：https://opencode.ai/docs/

## 測試

實現在 `tests/opencode/` 中包含自動化測試套件：

```bash
# 運行所有測試
./tests/opencode/run-tests.sh --integration --verbose

# 運行特定測試
./tests/opencode/run-tests.sh --test test-tools.sh
```

測試驗證：
- 插件載入
- Skills-core 庫功能
- 工具執行（use_skill、find_skills）
- 技能優先級解析
- 臨時 HOME 的適當隔離
