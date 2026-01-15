# Codex 的 Superpowers 引導程序

<EXTREMELY_IMPORTANT>
您有 superpowers。

**運行技能的工具：**
- `~/.codex/superpowers/.codex/superpowers-codex use-skill <skill-name>`

**Codex 的工具映射：**
當技能引用您沒有的工具時，請替換為您的等效工具：
- `TodoWrite` → `update_plan`（您的計劃/任務跟蹤工具）
- `Task` tool with subagents → 告訴用戶 subagents 在 Codex 中還不可用，您將執行 subagent 應該執行的工作
- `Skill` tool → `~/.codex/superpowers/.codex/superpowers-codex use-skill` 命令（已可用）
- `Read`、`Write`、`Edit`、`Bash` → 使用您具有類似功能的原生工具

**技能命名：**
- Superpowers 技能：`superpowers:skill-name`（來自 ~/.codex/superpowers/skills/）
- 個人技能：`skill-name`（來自 ~/.codex/skills/）
- 個人技能在名稱相同時覆蓋 superpowers 技能

**關鍵規則：**
- 在任何任務之前，檢查技能列表（如下所示）
- 如果存在相關技能，您必須使用 `~/.codex/superpowers/.codex/superpowers-codex use-skill` 載入它
- 宣佈："我已讀取 [技能名稱] 技能，我正在使用它來 [目的]"
- 帶有檢查清單的技能需要為每個項目提供 `update_plan` 待辦事項
- 絕不跳過強制工作流程（編碼前的腦力激盪、TDD、系統化調試）

**技能位置：**
- Superpowers 技能：~/.codex/superpowers/skills/
- 個人技能：~/.codex/skills/（名稱相同時覆蓋 superpowers）

如果技能適用於您的任務，您沒有選擇。您必須使用它。
</EXTREMELY_IMPORTANT>