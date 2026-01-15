# OpenCode 支持設計

**日期：** 2025-11-22
**作者：** Bot & Jesse
**狀態：** 設計完成，等待實現

## 概述

使用與現有 Codex 實現共享核心功能的原生 OpenCode 插件架構為 OpenCode.ai 添加完整的 superpowers 支持。

## 背景

OpenCode.ai 是一個類似於 Claude Code 和 Codex 的編碼代理。之前嘗試將 superpowers 移植到 OpenCode（PR #93、PR #116）使用了文件複製方法。此設計採取不同的方法：使用他們的 JavaScript/TypeScript 插件系統構建原生 OpenCode 插件，同時與 Codex 實現共享代碼。

### 平台之間的關鍵差異

- **Claude Code**：原生 Anthropic 插件系統 + 基於文件的技能
- **Codex**：無插件系統 → 引導程序 markdown + CLI 腳本
- **OpenCode**：帶有事件鉤子和自定義工具 API 的 JavaScript/TypeScript 插件

### OpenCode 的代理系統

- **主代理**：構建（默認、完全訪問）和計劃（受限制、只讀）
- **Subagents**：通用（研究、搜索、多步任務）
- **調用**：主代理自動派遣或手動 `@mention` 語法
- **配置**：自定義代理在 `opencode.json` 或 `~/.config/opencode/agent/`

## 架構

### 高級結構

1. **共享核心模塊** (`lib/skills-core.js`)
   - 常見的技能發現和解析邏輯
   - 由 Codex 和 OpenCode 實現使用

2. **平台特定的包裝器**
   - Codex：CLI 腳本（`.codex/superpowers-codex`）
   - OpenCode：插件模塊（`.opencode/plugin/superpowers.js`）

3. **技能目錄**
   - 核心：`~/.config/opencode/superpowers/skills/`（或安裝位置）
   - 個人：`~/.config/opencode/skills/`（遮蔽核心技能）

### 代碼重用策略

從 `.codex/superpowers-codex` 提取常見功能到共享模塊：

```javascript
// lib/skills-core.js
module.exports = {
  extractFrontmatter(filePath),      // 從 YAML 解析名稱 + 描述
  findSkillsInDir(dir, maxDepth),    // 遞歸 SKILL.md 發現
  findAllSkills(dirs),                // 掃描多個目錄
  resolveSkillPath(skillName, dirs), // 處理遮蔽（個人 > 核心）
  checkForUpdates(repoDir)           // Git fetch/status 檢查
};
```

### 技能 Frontmatter 格式

當前格式（無 `when_to_use` 字段）：

```yaml
---
name: skill-name
description: Use when [condition] - [what it does]; [additional context]
---
```

## OpenCode 插件實現

### 自定義工具

**工具 1：`use_skill`**

將特定技能的內容加載到對話中（等同於 Claude 的技能工具）。

```javascript
{
  name: 'use_skill',
  description: 'Load and read a specific skill to guide your work',
  schema: z.object({
    skill_name: z.string().describe('Name of skill (e.g., "superpowers:brainstorming")')
  }),
  execute: async ({ skill_name }) => {
    const { skillPath, content, frontmatter } = resolveAndReadSkill(skill_name);
    const skillDir = path.dirname(skillPath);

    return `# ${frontmatter.name}
# ${frontmatter.description}
# Supporting tools and docs are in ${skillDir}
# ============================================

${content}`;
  }
}
```

**工具 2：`find_skills`**

列出所有可用的技能及其元數據。

```javascript
{
  name: 'find_skills',
  description: 'List all available skills',
  schema: z.object({}),
  execute: async () => {
    const skills = discoverAllSkills();
    return skills.map(s =>
      `${s.namespace}:${s.name}
  ${s.description}
  Directory: ${s.directory}
`).join('\n');
  }
}
```

### 會話啟動鉤子

當新會話開始時（`session.started` 事件）：

1. **注入 using-superpowers 內容**
   - using-superpowers 技能的完整內容
   - 建立強制工作流

2. **自動運行 find_skills**
   - 預先顯示完整的可用技能列表
   - 為每個技能包括技能目錄

3. **注入工具映射說明**
   ```markdown
   **OpenCode 的工具映射：**
   當技能引用你沒有的工具時，替換為：
   - `TodoWrite` → `update_plan`
   - `Task` with subagents → 使用 OpenCode subagent 系統（@mention）
   - `Skill` 工具 → `use_skill` 自定義工具
   - Read、Write、Edit、Bash → 你的原生等價物

   **技能目錄包含：**
   - 支持腳本（用 bash 運行）
   - 額外文檔（用讀取工具讀）
   - 特定於該技能的實用程序
   ```

4. **檢查更新**（非阻塞）
   - 快速 git fetch 帶超時
   - 如果有更新可用通知

### 插件結構

```javascript
// .opencode/plugin/superpowers.js
const skillsCore = require('../../lib/skills-core');
const path = require('path');
const fs = require('fs');
const { z } = require('zod');

export const SuperpowersPlugin = async ({ client, directory, $ }) => {
  const superpowersDir = path.join(process.env.HOME, '.config/opencode/superpowers');
  const personalDir = path.join(process.env.HOME, '.config/opencode/skills');

  return {
    'session.started': async () => {
      const usingSuperpowers = await readSkill('using-superpowers');
      const skillsList = await findAllSkills();
      const toolMapping = getToolMappingInstructions();

      return {
        context: `${usingSuperpowers}\n\n${skillsList}\n\n${toolMapping}`
      };
    },

    tools: [
      {
        name: 'use_skill',
        description: 'Load and read a specific skill',
        schema: z.object({
          skill_name: z.string()
        }),
        execute: async ({ skill_name }) => {
          // 使用 skillsCore 實現
        }
      },
      {
        name: 'find_skills',
        description: 'List all available skills',
        schema: z.object({}),
        execute: async () => {
          // 使用 skillsCore 實現
        }
      }
    ]
  };
};
```

## 文件結構

```
superpowers/
├── lib/
│   └── skills-core.js           # 新：共享技能邏輯
├── .codex/
│   ├── superpowers-codex        # 已更新：使用 skills-core
│   ├── superpowers-bootstrap.md
│   └── INSTALL.md
├── .opencode/
│   ├── plugin/
│   │   └── superpowers.js       # 新：OpenCode 插件
│   └── INSTALL.md               # 新：安裝指南
└── skills/                       # 未改變
```

## 實現計劃

### 階段 1：重構共享核心

1. 創建 `lib/skills-core.js`
   - 從 `.codex/superpowers-codex` 提取 frontmatter 解析
   - 提取技能發現邏輯
   - 提取路徑解決（帶遮蔽）
   - 更新為僅使用 `name` 和 `description`（無 `when_to_use`）

2. 更新 `.codex/superpowers-codex` 使用共享核心
   - 從 `../lib/skills-core.js` 導入
   - 移除重複代碼
   - 保持 CLI 包裝器邏輯

3. 測試 Codex 實現仍然工作
   - 驗證 bootstrap 命令
   - 驗證 use-skill 命令
   - 驗證 find-skills 命令

### 階段 2：構建 OpenCode 插件

1. 創建 `.opencode/plugin/superpowers.js`
   - 從 `../../lib/skills-core.js` 導入共享核心
   - 實現插件函數
   - 定義自定義工具（use_skill、find_skills）
   - 實現 session.started 鉤子

2. 創建 `.opencode/INSTALL.md`
   - 安裝說明
   - 目錄設置
   - 配置指南

3. 測試 OpenCode 實現
   - 驗證會話啟動引導程序
   - 驗證 use_skill 工具工作
   - 驗證 find_skills 工具工作
   - 驗證技能目錄可訪問

### 階段 3：文檔和拋光

1. 使用 OpenCode 支持更新 README
2. 將 OpenCode 安裝添加到主文檔
3. 更新 RELEASE-NOTES
4. 測試 Codex 和 OpenCode 都正確工作

## 下一步

1. **創建隔離的工作區**（使用 git worktrees）
   - 分支：`feature/opencode-support`

2. **在適用的地方遵循 TDD**
   - 測試共享核心函數
   - 測試技能發現和解析
   - 兩個平台的集成測試

3. **增量實現**
   - 階段 1：重構共享核心 + 更新 Codex
   - 在移動前驗證 Codex 仍然工作
   - 階段 2：構建 OpenCode 插件
   - 階段 3：文檔和拋光

4. **測試策略**
   - 帶真實 OpenCode 安裝的手動測試
   - 驗證技能加載、目錄、腳本工作
   - 同時測試 Codex 和 OpenCode
   - 驗證工具映射工作正確

5. **拉請求和合併**
   - 使用完整實現創建拉請求
   - 在乾淨環境中測試
   - 合併到 main

## 好處

- **代碼重用**：技能發現/解析的單一事實來源
- **可維護性**：錯誤修復應用於兩個平台
- **可擴展性**：輕鬆為未來的平台添加（Cursor、Windsurf 等）
- **原生集成**：正確使用 OpenCode 的插件系統
- **一致性**：所有平台上相同的技能體驗
