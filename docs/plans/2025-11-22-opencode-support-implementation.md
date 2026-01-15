# OpenCode 支持實現計劃

> **對於 Claude：** 需要的子技能：使用 superpowers:executing-plans 逐任務實現此計劃。

**目標：** 為 OpenCode.ai 添加完整的 superpowers 支持，使用原生 JavaScript 插件，與現有 Codex 實現共享核心功能。

**架構：** 將常見的技能發現/解析邏輯提取到 `lib/skills-core.js`，重構 Codex 使用它，然後使用其原生插件 API 與自定義工具和會話鉤子構建 OpenCode 插件。

**技術棧：** Node.js、JavaScript、OpenCode 插件 API、Git worktrees

---

## 階段 1：創建共享核心模塊

### 任務 1：提取 Frontmatter 解析

**文件：**
- 創建：`lib/skills-core.js`
- 參考：`.codex/superpowers-codex` (第 40-74 行)

**步驟 1：使用 extractFrontmatter 函數創建 lib/skills-core.js**

```javascript
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * 從技能文件中提取 YAML frontmatter。
 * 當前格式：
 * ---
 * name: skill-name
 * description: Use when [condition] - [what it does]
 * ---
 *
 * @param {string} filePath - 指向 SKILL.md 文件的路徑
 * @returns {{name: string, description: string}}
 */
function extractFrontmatter(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        const lines = content.split('\n');

        let inFrontmatter = false;
        let name = '';
        let description = '';

        for (const line of lines) {
            if (line.trim() === '---') {
                if (inFrontmatter) break;
                inFrontmatter = true;
                continue;
            }

            if (inFrontmatter) {
                const match = line.match(/^(\w+):\s*(.*)$/);
                if (match) {
                    const [, key, value] = match;
                    switch (key) {
                        case 'name':
                            name = value.trim();
                            break;
                        case 'description':
                            description = value.trim();
                            break;
                    }
                }
            }
        }

        return { name, description };
    } catch (error) {
        return { name: '', description: '' };
    }
}

module.exports = {
    extractFrontmatter
};
```

**步驟 2：驗證文件已創建**

運行：`ls -l lib/skills-core.js`
預期：文件存在

**步驟 3：提交**

```bash
git add lib/skills-core.js
git commit -m "feat: create shared skills core module with frontmatter parser"
```

---

### 任務 2：提取技能發現邏輯

**文件：**
- 修改：`lib/skills-core.js`
- 參考：`.codex/superpowers-codex` (第 97-136 行)

**步驟 1：向 skills-core.js 添加 findSkillsInDir 函數**

在 `module.exports` 之前添加：

```javascript
/**
 * 遞歸地在目錄中找到所有 SKILL.md 文件。
 *
 * @param {string} dir - 要搜索的目錄
 * @param {string} sourceType - 命名空間用的「個人」或「superpowers」
 * @param {number} maxDepth - 最大遞歸深度（默認：3）
 * @returns {Array<{path: string, name: string, description: string, sourceType: string}>}
 */
function findSkillsInDir(dir, sourceType, maxDepth = 3) {
    const skills = [];

    if (!fs.existsSync(dir)) return skills;

    function recurse(currentDir, depth) {
        if (depth > maxDepth) return;

        const entries = fs.readdirSync(currentDir, { withFileTypes: true });

        for (const entry of entries) {
            const fullPath = path.join(currentDir, entry.name);

            if (entry.isDirectory()) {
                // 檢查此目錄中是否有 SKILL.md
                const skillFile = path.join(fullPath, 'SKILL.md');
                if (fs.existsSync(skillFile)) {
                    const { name, description } = extractFrontmatter(skillFile);
                    skills.push({
                        path: fullPath,
                        skillFile: skillFile,
                        name: name || entry.name,
                        description: description || '',
                        sourceType: sourceType
                    });
                }

                // 遞歸進入子目錄
                recurse(fullPath, depth + 1);
            }
        }
    }

    recurse(dir, 0);
    return skills;
}
```

**步驟 2：更新 module.exports**

用以下代碼替換 exports 行：

```javascript
module.exports = {
    extractFrontmatter,
    findSkillsInDir
};
```

**步驟 3：驗證語法**

運行：`node -c lib/skills-core.js`
預期：無輸出（成功）

**步驟 4：提交**

```bash
git add lib/skills-core.js
git commit -m "feat: add skill discovery function to core module"
```

---

### 任務 3：提取技能解決邏輯

**文件：**
- 修改：`lib/skills-core.js`
- 參考：`.codex/superpowers-codex` (第 212-280 行)

**步驟 1：添加 resolveSkillPath 函數**

在 `module.exports` 之前添加：

```javascript
/**
 * 將技能名稱解決為其文件路徑，處理遮蔽
 * （個人技能覆蓋 superpowers 技能）。
 *
 * @param {string} skillName - 名稱如「superpowers:brainstorming」或「my-skill」
 * @param {string} superpowersDir - 指向 superpowers 技能目錄的路徑
 * @param {string} personalDir - 指向個人技能目錄的路徑
 * @returns {{skillFile: string, sourceType: string, skillPath: string} | null}
 */
function resolveSkillPath(skillName, superpowersDir, personalDir) {
    // 如果存在則刪除 superpowers: 前綴
    const forceSuperpowers = skillName.startsWith('superpowers:');
    const actualSkillName = forceSuperpowers ? skillName.replace(/^superpowers:/, '') : skillName;

    // 首先嘗試個人技能（除非明確 superpowers:）
    if (!forceSuperpowers && personalDir) {
        const personalPath = path.join(personalDir, actualSkillName);
        const personalSkillFile = path.join(personalPath, 'SKILL.md');
        if (fs.existsSync(personalSkillFile)) {
            return {
                skillFile: personalSkillFile,
                sourceType: 'personal',
                skillPath: actualSkillName
            };
        }
    }

    // 嘗試 superpowers 技能
    if (superpowersDir) {
        const superpowersPath = path.join(superpowersDir, actualSkillName);
        const superpowersSkillFile = path.join(superpowersPath, 'SKILL.md');
        if (fs.existsSync(superpowersSkillFile)) {
            return {
                skillFile: superpowersSkillFile,
                sourceType: 'superpowers',
                skillPath: actualSkillName
            };
        }
    }

    return null;
}
```

**步驟 2：更新 module.exports**

```javascript
module.exports = {
    extractFrontmatter,
    findSkillsInDir,
    resolveSkillPath
};
```

**步驟 3：驗證語法**

運行：`node -c lib/skills-core.js`
預期：無輸出

**步驟 4：提交**

```bash
git add lib/skills-core.js
git commit -m "feat: add skill path resolution with shadowing support"
```

---

### 任務 4：提取更新檢查邏輯

**文件：**
- 修改：`lib/skills-core.js`
- 參考：`.codex/superpowers-codex` (第 16-38 行)

**步驟 1：在 requires 後添加 checkForUpdates 函數**

在頂部 requires 後添加：

```javascript
const { execSync } = require('child_process');
```

在 `module.exports` 之前添加：

```javascript
/**
 * 檢查 git 倉庫是否有可用的更新。
 *
 * @param {string} repoDir - 指向 git 倉庫的路徑
 * @returns {boolean} - 如果有可用的更新為 true
 */
function checkForUpdates(repoDir) {
    try {
        // 快速檢查，3 秒超時以避免網絡掉線時延遲
        const output = execSync('git fetch origin && git status --porcelain=v1 --branch', {
            cwd: repoDir,
            timeout: 3000,
            encoding: 'utf8',
            stdio: 'pipe'
        });

        // 解析 git status 輸出看我們是否落後
        const statusLines = output.split('\n');
        for (const line of statusLines) {
            if (line.startsWith('## ') && line.includes('[behind ')) {
                return true; // 我們落後於遠程
            }
        }
        return false; // 最新
    } catch (error) {
        // 網絡斷開、git 錯誤、超時等 - 不阻塞引導程序
        return false;
    }
}
```

**步驟 2：更新 module.exports**

```javascript
module.exports = {
    extractFrontmatter,
    findSkillsInDir,
    resolveSkillPath,
    checkForUpdates
};
```

**步驟 3：驗證語法**

運行：`node -c lib/skills-core.js`
預期：無輸出

**步驟 4：提交**

```bash
git add lib/skills-core.js
git commit -m "feat: add git update checking to core module"
```

---

## 階段 2：重構 Codex 以使用共享核心

### 任務 5：更新 Codex 以導入共享核心

**文件：**
- 修改：`.codex/superpowers-codex` (在文件頂部添加導入)

**步驟 1：添加導入語句**

在現有 requires 之後（大約第 6 行），添加：

```javascript
const skillsCore = require('../lib/skills-core');
```

**步驟 2：驗證語法**

運行：`node -c .codex/superpowers-codex`
預期：無輸出

**步驟 3：提交**

```bash
git add .codex/superpowers-codex
git commit -m "refactor: import shared skills core in codex"
```

---

### 任務 6：用核心版本替換 extractFrontmatter

**文件：**
- 修改：`.codex/superpowers-codex` (第 40-74 行)

**步驟 1：移除本地 extractFrontmatter 函數**

刪除第 40-74 行（整個 extractFrontmatter 函數定義）。

**步驟 2：更新所有 extractFrontmatter 調用**

找到並用 `skillsCore.extractFrontmatter(` 替換所有 `extractFrontmatter(` 調用

受影響的行大約：90、310

**步驟 3：驗證腳本仍然工作**

運行：`.codex/superpowers-codex find-skills | head -20`
預期：顯示技能清單

**步驟 4：提交**

```bash
git add .codex/superpowers-codex
git commit -m "refactor: use shared extractFrontmatter in codex"
```

---

### 任務 7：用核心版本替換 findSkillsInDir

**文件：**
- 修改：`.codex/superpowers-codex` (第 97-136 行，大約)

**步驟 1：移除本地 findSkillsInDir 函數**

刪除整個 `findSkillsInDir` 函數定義（大約第 97-136 行）。

**步驟 2：更新所有 findSkillsInDir 調用**

用 `skillsCore.findSkillsInDir(` 替換 `findSkillsInDir(` 的調用

**步驟 3：驗證腳本仍然工作**

運行：`.codex/superpowers-codex find-skills | head -20`
預期：顯示技能清單

**步驟 4：提交**

```bash
git add .codex/superpowers-codex
git commit -m "refactor: use shared findSkillsInDir in codex"
```

---

### 任務 8：用核心版本替換 checkForUpdates

**文件：**
- 修改：`.codex/superpowers-codex` (第 16-38 行，大約)

**步驟 1：移除本地 checkForUpdates 函數**

刪除整個 `checkForUpdates` 函數定義。

**步驟 2：更新所有 checkForUpdates 調用**

用 `skillsCore.checkForUpdates(` 替換 `checkForUpdates(` 的調用

**步驟 3：驗證腳本仍然工作**

運行：`.codex/superpowers-codex bootstrap | head -50`
預期：顯示引導程序內容

**步驟 4：提交**

```bash
git add .codex/superpowers-codex
git commit -m "refactor: use shared checkForUpdates in codex"
```

---

## 階段 3：構建 OpenCode 插件

### 任務 9：創建 OpenCode 插件目錄結構

**文件：**
- 創建：`.opencode/plugin/superpowers.js`

**步驟 1：創建目錄**

運行：`mkdir -p .opencode/plugin`

**步驟 2：創建基本插件文件**

```javascript
#!/usr/bin/env node

/**
 * OpenCode.ai 的 Superpowers 插件
 *
 * 提供自定義工具以加載和發現技能，
 * 具有會話啟動時的自動引導程序。
 */

const skillsCore = require('../../lib/skills-core');
const path = require('path');
const fs = require('fs');
const os = require('os');

const homeDir = os.homedir();
const superpowersSkillsDir = path.join(homeDir, '.config/opencode/superpowers/skills');
const personalSkillsDir = path.join(homeDir, '.config/opencode/skills');

/**
 * OpenCode 插件進入點
 */
export const SuperpowersPlugin = async ({ project, client, $, directory, worktree }) => {
  return {
    // 自定義工具和鉤子將放在這裡
  };
};
```

**步驟 3：驗證文件已創建**

運行：`ls -l .opencode/plugin/superpowers.js`
預期：文件存在

**步驟 4：提交**

```bash
git add .opencode/plugin/superpowers.js
git commit -m "feat: create opencode plugin scaffold"
```

---

### 任務 10：實現 use_skill 工具

**文件：**
- 修改：`.opencode/plugin/superpowers.js`

**步驟 1：添加 use_skill 工具實現**

用以下代碼替換插件返回語句：

```javascript
export const SuperpowersPlugin = async ({ project, client, $, directory, worktree }) => {
  // 導入 zod 用於架構驗證
  const { z } = await import('zod');

  return {
    tools: [
      {
        name: 'use_skill',
        description: 'Load and read a specific skill to guide your work. Skills contain proven workflows, mandatory processes, and expert techniques.',
        schema: z.object({
          skill_name: z.string().describe('Name of the skill to load (e.g., "superpowers:brainstorming" or "my-custom-skill")')
        }),
        execute: async ({ skill_name }) => {
          // 解決技能路徑（處理遮蔽：個人 > superpowers）
          const resolved = skillsCore.resolveSkillPath(
            skill_name,
            superpowersSkillsDir,
            personalSkillsDir
          );

          if (!resolved) {
            return `錯誤：技能「${skill_name}」未找到。\n\n運行 find_skills 查看可用技能。`;
          }

          // 讀取技能內容
          const fullContent = fs.readFileSync(resolved.skillFile, 'utf8');
          const { name, description } = skillsCore.extractFrontmatter(resolved.skillFile);

          // 提取 frontmatter 後的內容
          const lines = fullContent.split('\n');
          let inFrontmatter = false;
          let frontmatterEnded = false;
          const contentLines = [];

          for (const line of lines) {
            if (line.trim() === '---') {
              if (inFrontmatter) {
                frontmatterEnded = true;
                continue;
              }
              inFrontmatter = true;
              continue;
            }

            if (frontmatterEnded || !inFrontmatter) {
              contentLines.push(line);
            }
          }

          const content = contentLines.join('\n').trim();
          const skillDirectory = path.dirname(resolved.skillFile);

          // 格式化輸出類似於 Claude Code 的技能工具
          return `# ${name || skill_name}
# ${description || ''}
# 支持工具和文檔在 ${skillDirectory}
# ============================================

${content}`;
        }
      }
    ]
  };
};
```

**步驟 2：驗證語法**

運行：`node -c .opencode/plugin/superpowers.js`
預期：無輸出

**步驟 3：提交**

```bash
git add .opencode/plugin/superpowers.js
git commit -m "feat: implement use_skill tool for opencode"
```

---

### 任務 11：實現 find_skills 工具

**文件：**
- 修改：`.opencode/plugin/superpowers.js`

**步驟 1：向工具陣列添加 find_skills 工具**

在 use_skill 工具定義後，在關閉工具陣列前添加：

```javascript
      {
        name: 'find_skills',
        description: 'List all available skills in the superpowers and personal skill libraries.',
        schema: z.object({}),
        execute: async () => {
          // 在兩個目錄中找到技能
          const superpowersSkills = skillsCore.findSkillsInDir(
            superpowersSkillsDir,
            'superpowers',
            3
          );
          const personalSkills = skillsCore.findSkillsInDir(
            personalSkillsDir,
            'personal',
            3
          );

          // 合併並格式化技能清單
          const allSkills = [...personalSkills, ...superpowersSkills];

          if (allSkills.length === 0) {
            return '未找到技能。將 superpowers 技能安裝到 ~/.config/opencode/superpowers/skills/';
          }

          let output = '可用技能：\n\n';

          for (const skill of allSkills) {
            const namespace = skill.sourceType === 'personal' ? '' : 'superpowers:';
            const skillName = skill.name || path.basename(skill.path);

            output += `${namespace}${skillName}\n`;
            if (skill.description) {
              output += `  ${skill.description}\n`;
            }
            output += `  目錄：${skill.path}\n\n`;
          }

          return output;
        }
      }
```

**步驟 2：驗證語法**

運行：`node -c .opencode/plugin/superpowers.js`
預期：無輸出

**步驟 3：提交**

```bash
git add .opencode/plugin/superpowers.js
git commit -m "feat: implement find_skills tool for opencode"
```

---

### 任務 12：實現會話啟動鉤子

**文件：**
- 修改：`.opencode/plugin/superpowers.js`

**步驟 1：添加 session.started 鉤子**

在工具陣列後添加：

```javascript
    'session.started': async () => {
      // 讀取 using-superpowers 技能內容
      const usingSuperpowersPath = skillsCore.resolveSkillPath(
        'using-superpowers',
        superpowersSkillsDir,
        personalSkillsDir
      );

      let usingSuperpowersContent = '';
      if (usingSuperpowersPath) {
        const fullContent = fs.readFileSync(usingSuperpowersPath.skillFile, 'utf8');
        // 去掉 frontmatter
        const lines = fullContent.split('\n');
        let inFrontmatter = false;
        let frontmatterEnded = false;
        const contentLines = [];

        for (const line of lines) {
          if (line.trim() === '---') {
            if (inFrontmatter) {
              frontmatterEnded = true;
              continue;
            }
            inFrontmatter = true;
            continue;
          }

          if (frontmatterEnded || !inFrontmatter) {
            contentLines.push(line);
          }
        }

        usingSuperpowersContent = contentLines.join('\n').trim();
      }

      // 工具映射說明
      const toolMapping = `
**OpenCode 的工具映射：**
當技能引用你沒有的工具時，替換為 OpenCode 等價物：
- \`TodoWrite\` → \`update_plan\`（你的計劃/任務跟蹤工具）
- \`Task\` 工具帶 subagents → 使用 OpenCode 的 subagent 系統（@mention 語法或自動派遣）
- \`Skill\` 工具 → \`use_skill\` 自定義工具（已可用）
- \`Read\`、\`Write\`、\`Edit\`、\`Bash\` → 使用你的原生工具

**技能目錄包含支持文件：**
- 可以用 bash 工具運行的腳本
- 可以讀取的額外文檔
- 特定於該技能的實用程序和幫助程序

**技能命名：**
- Superpowers 技能：\`superpowers:skill-name\`（來自 ~/.config/opencode/superpowers/skills/）
- 個人技能：\`skill-name\`（來自 ~/.config/opencode/skills/）
- 個人技能在名稱匹配時覆蓋 superpowers 技能
`;

      // 檢查更新（非阻塞）
      const hasUpdates = skillsCore.checkForUpdates(
        path.join(homeDir, '.config/opencode/superpowers')
      );

      const updateNotice = hasUpdates ?
        '\n\n⚠️ **有可用的更新！** 運行 \`cd ~/.config/opencode/superpowers && git pull\` 以更新 superpowers。' :
        '';

      // 返回要注入到會話中的上下文
      return {
        context: `<極度重要>
你有 superpowers。

**下面是你的「superpowers:using-superpowers」技能的完整內容 - 你使用技能的介紹。對於所有其他技能，使用「use_skill」工具：**

${usingSuperpowersContent}

${toolMapping}${updateNotice}
</極度重要>`
      };
    }
```

**步驟 2：驗證語法**

運行：`node -c .opencode/plugin/superpowers.js`
預期：無輸出

**步驟 3：提交**

```bash
git add .opencode/plugin/superpowers.js
git commit -m "feat: implement session.started hook for opencode"
```

---

## 階段 4：文檔

### 任務 13：創建 OpenCode 安裝指南

**文件：**
- 創建：`.opencode/INSTALL.md`

**步驟 1：創建安裝指南**

```markdown
# 為 OpenCode 安裝 Superpowers

## 前置條件

- [OpenCode.ai](https://opencode.ai) 已安裝
- Node.js 已安裝
- Git 已安裝

## 安裝步驟

### 1. 安裝 Superpowers 技能

\`\`\`bash
# 將 superpowers 技能克隆到 OpenCode 配置目錄
mkdir -p ~/.config/opencode/superpowers
git clone https://github.com/obra/superpowers.git ~/.config/opencode/superpowers
\`\`\`

### 2. 安裝插件

你剛克隆的 superpowers 倉庫中包含該插件。

OpenCode 將自動從以下位置發現它：
- \`~/.config/opencode/superpowers/.opencode/plugin/superpowers.js\`

或者你可以將其鏈接到項目本地插件目錄：

\`\`\`bash
# 在你的 OpenCode 項目中
mkdir -p .opencode/plugin
ln -s ~/.config/opencode/superpowers/.opencode/plugin/superpowers.js .opencode/plugin/superpowers.js
\`\`\`

### 3. 重新啟動 OpenCode

重新啟動 OpenCode 以加載插件。在下一個會話中，你應該看到：

\`\`\`
你有 superpowers。
\`\`\`

## 使用

### 查找技能

使用 \`find_skills\` 工具列出所有可用的技能：

\`\`\`
使用 find_skills 工具
\`\`\`

### 加載技能

使用 \`use_skill\` 工具加載特定技能：

\`\`\`
使用 use_skill 工具，skill_name：「superpowers:brainstorming」
\`\`\`

### 個人技能

在 \`~/.config/opencode/skills/\` 中創建你自己的技能：

\`\`\`bash
mkdir -p ~/.config/opencode/skills/my-skill
\`\`\`

創建 \`~/.config/opencode/skills/my-skill/SKILL.md\`：

\`\`\`markdown
---
name: my-skill
description: 使用時 [條件] - [它的作用]
---

# 我的技能

[你的技能內容在這裡]
\`\`\`

個人技能覆蓋同名的 superpowers 技能。

## 更新

\`\`\`bash
cd ~/.config/opencode/superpowers
git pull
\`\`\`

## 故障排除

### 插件未加載

1. 檢查插件文件存在：\`ls ~/.config/opencode/superpowers/.opencode/plugin/superpowers.js\`
2. 檢查 OpenCode 日誌中的錯誤
3. 驗證 Node.js 已安裝：\`node --version\`

### 未找到技能

1. 驗證技能目錄存在：\`ls ~/.config/opencode/superpowers/skills\`
2. 使用 \`find_skills\` 工具看看發現了什麼
3. 檢查文件結構：每個技能應該有一個 \`SKILL.md\` 文件

### 工具映射問題

當技能引用你沒有的 Claude Code 工具時：
- \`TodoWrite\` → 使用 \`update_plan\`
- \`Task\` with subagents → 使用 \`@mention\` 語法調用 OpenCode subagents
- \`Skill\` → 使用 \`use_skill\` 工具
- 文件操作 → 使用你的原生工具

## 獲得幫助

- 報告問題：https://github.com/obra/superpowers/issues
- 文檔：https://github.com/obra/superpowers
\`\`\`

**步驟 2：驗證文件已創建**

運行：`ls -l .opencode/INSTALL.md`
預期：文件存在

**步驟 3：提交**

```bash
git add .opencode/INSTALL.md
git commit -m "docs: add opencode installation guide"
```

---

### 任務 14：更新主 README

**文件：**
- 修改：`README.md`

**步驟 1：添加 OpenCode 部分**

找到關於支持的平台的部分（在文件中搜索「Codex」），並在其後添加：

```markdown
### OpenCode

Superpowers 通過原生 JavaScript 插件與 [OpenCode.ai](https://opencode.ai) 一起工作。

**安裝：** 見 [.opencode/INSTALL.md](.opencode/INSTALL.md)

**功能：**
- 自定義工具：`use_skill` 和 `find_skills`
- 自動會話引導程序
- 帶遮蔽的個人技能
- 支持文件和腳本訪問
```

**步驟 2：驗證格式**

運行：`grep -A 10 "### OpenCode" README.md`
預期：顯示你添加的部分

**步驟 3：提交**

```bash
git add README.md
git commit -m "docs: add opencode support to readme"
```

---

### 任務 15：更新發布說明

**文件：**
- 修改：`RELEASE-NOTES.md`

**步驟 1：添加 OpenCode 支持條目**

在文件頂部（標題後），添加：

```markdown
## [未發布]

### 添加

- **OpenCode 支持**：OpenCode.ai 的原生 JavaScript 插件
  - 自定義工具：`use_skill` 和 `find_skills`
  - 帶工具映射說明的自動會話引導程序
  - 共享核心模塊（`lib/skills-core.js`）用於代碼重用
  - `.opencode/INSTALL.md` 中的安裝指南

### 變更

- **重構的 Codex 實現**：現在使用共享 `lib/skills-core.js` 模塊
  - 消除了 Codex 和 OpenCode 之間的代碼重複
  - 技能發現和解析的單一事實來源

---

```

**步驟 2：驗證格式**

運行：`head -30 RELEASE-NOTES.md`
預期：顯示你的新部分

**步驟 3：提交**

```bash
git add RELEASE-NOTES.md
git commit -m "docs: add opencode support to release notes"
```

---

## 階段 5：最終驗證

### 任務 16：測試 Codex 仍然工作

**文件：**
- 測試：`.codex/superpowers-codex`

**步驟 1：測試 find-skills 命令**

運行：`.codex/superpowers-codex find-skills | head -20`
預期：顯示技能清單，帶名稱和描述

**步驟 2：測試 use-skill 命令**

運行：`.codex/superpowers-codex use-skill superpowers:brainstorming | head -20`
預期：顯示腦力激蕩技能內容

**步驟 3：測試 bootstrap 命令**

運行：`.codex/superpowers-codex bootstrap | head -30`
預期：顯示帶說明的引導程序內容

**步驟 4：如果所有測試都通過，記錄成功**

無需提交 - 這只是驗證。

---

### 任務 17：驗證文件結構

**文件：**
- 檢查：所有新文件存在

**步驟 1：驗證所有文件已創建**

運行：
```bash
ls -l lib/skills-core.js
ls -l .opencode/plugin/superpowers.js
ls -l .opencode/INSTALL.md
```

預期：所有文件存在

**步驟 2：驗證目錄結構**

運行：`tree -L 2 .opencode/`（或 `find .opencode -type f`，如果 tree 不可用）
預期：
```
.opencode/
├── INSTALL.md
└── plugin/
    └── superpowers.js
```

**步驟 3：如果結構正確，繼續**

無需提交 - 這只是驗證。

---

### 任務 18：最終提交和摘要

**文件：**
- 檢查：`git status`

**步驟 1：檢查 git 狀態**

運行：`git status`
預期：工作樹乾淨，所有變更都已提交

**步驟 2：審查提交日誌**

運行：`git log --oneline -20`
預期：顯示此實現的所有提交

**步驟 3：創建摘要文檔**

創建完成摘要，顯示：
- 進行的總提交數
- 創建的文件：`lib/skills-core.js`、`.opencode/plugin/superpowers.js`、`.opencode/INSTALL.md`
- 修改的文件：`.codex/superpowers-codex`、`README.md`、`RELEASE-NOTES.md`
- 執行的測試：驗證了 Codex 命令
- 準備好：用實際 OpenCode 安裝進行測試

**步驟 4：報告完成**

向用戶呈現摘要並提供以下選項：
1. 推送到遠程
2. 創建拉請求
3. 用實際 OpenCode 安裝進行測試（需要 OpenCode 已安裝）

---

## 測試指南（手動 - 需要 OpenCode）

這些步驟需要 OpenCode 已安裝，不是自動實現的一部分：

1. **安裝技能**：遵循 `.opencode/INSTALL.md`
2. **啟動 OpenCode 會話**：驗證引導程序出現
3. **測試 find_skills**：應列出所有可用技能
4. **測試 use_skill**：加載技能並驗證內容出現
5. **測試支持文件**：驗證技能目錄路徑可訪問
6. **測試個人技能**：創建個人技能並驗證它遮蔽核心
7. **測試工具映射**：驗證 TodoWrite → update_plan 映射工作

## 成功標準

- [ ] `lib/skills-core.js` 已創建，所有核心函數
- [ ] `.codex/superpowers-codex` 已重構以使用共享核心
- [ ] Codex 命令仍然工作（find-skills、use-skill、bootstrap）
- [ ] `.opencode/plugin/superpowers.js` 已創建，帶工具和鉤子
- [ ] 安裝指南已創建
- [ ] README 和 RELEASE-NOTES 已更新
- [ ] 所有變更都已提交
- [ ] 工作樹乾淨
