# 為 OpenCode 安裝 Superpowers

## 先決條件

- [OpenCode.ai](https://opencode.ai) 已安裝
- Node.js 已安裝
- Git 已安裝

## 安裝步驟

### 1. 安裝 Superpowers

```bash
mkdir -p ~/.config/opencode/superpowers
git clone https://github.com/obra/superpowers.git ~/.config/opencode/superpowers
```

### 2. 註冊插件

創建符號連結以讓 OpenCode 發現插件：

```bash
mkdir -p ~/.config/opencode/plugin
ln -sf ~/.config/opencode/superpowers/.opencode/plugin/superpowers.js ~/.config/opencode/plugin/superpowers.js
```

### 3. 重新啟動 OpenCode

重新啟動 OpenCode。插件將通過 chat.message 鉤子自動注入 superpowers 上下文。

當您詢問"do you have superpowers?"時，您應該看到 superpowers 已激活。

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

個人技能會覆蓋同名的 superpowers 技能。

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

**技能優先級：** 專案技能會覆蓋個人技能，個人技能覆蓋 superpowers 技能。

**技能命名：**
- `project:skill-name` - 強制專案技能查詢
- `skill-name` - 搜索專案 → 個人 → superpowers
- `superpowers:skill-name` - 強制 superpowers 技能查詢

## 更新

```bash
cd ~/.config/opencode/superpowers
git pull
```

## 故障排除

### 插件未載入

1. 檢查插件文件是否存在：`ls ~/.config/opencode/superpowers/.opencode/plugin/superpowers.js`
2. 檢查 OpenCode 日誌中的錯誤
3. 驗證 Node.js 已安裝：`node --version`

### 找不到技能

1. 驗證技能目錄是否存在：`ls ~/.config/opencode/superpowers/skills`
2. 使用 `find_skills` 工具查看發現的內容
3. 檢查文件結構：每個技能應該有 `SKILL.md` 文件

### 工具映射問題

當技能引用您沒有的 Claude Code 工具時：
- `TodoWrite` → 使用 `update_plan`
- `Task` with subagents → 使用 `@mention` 語法調用 OpenCode subagents
- `Skill` → 使用 `use_skill` 工具
- 文件操作 → 使用您的原生工具

## 獲取幫助

- 報告問題：https://github.com/obra/superpowers/issues
- 文檔：https://github.com/obra/superpowers
