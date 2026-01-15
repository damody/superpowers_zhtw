# Superpowers 發布說明

## v4.0.3 (2025-12-26)

### 改進

**加強 using-superpowers 技能以支持明確的技能請求**

解決了 Claude 在用戶明確按名稱請求技能時仍會跳過該技能的失敗模式（例如「subagent-driven-development, please」）。Claude 會認為「我知道那是什麼意思」，然後直接開始工作，而不是加載該技能。

變更：
- 更新「規則」，從「檢查技能」改為「調用相關或請求的技能」，強調主動調用而非被動檢查
- 添加「在任何回應或操作之前」，原始措辭只提到「回應」，但 Claude 有時會在回應前採取行動
- 添加保證，調用錯誤的技能也沒問題，減少猶豫
- 添加新的危險信號：「我知道那是什麼意思」→ 知道概念 ≠ 使用技能

**添加明確技能請求測試**

在 `tests/explicit-skill-requests/` 中的新測試套件，驗證 Claude 在用戶按名稱請求技能時是否正確調用。包括單轉和多轉測試場景。

## v4.0.2 (2025-12-23)

### 修復

**斜杠命令現在僅限用戶使用**

為所有三個斜杠命令（`/brainstorm`、`/execute-plan`、`/write-plan`）添加了 `disable-model-invocation: true`。Claude 不再能通過技能工具調用這些命令，它們被限制為僅手動用戶調用。

基礎技能（`superpowers:brainstorming`、`superpowers:executing-plans`、`superpowers:writing-plans`）仍然可供 Claude 自主調用。此變更防止了混淆，即當 Claude 調用命令時，該命令只會重定向到技能。

## v4.0.1 (2025-12-23)

### 修復

**澄清如何在 Claude Code 中訪問技能**

修復了一個令人困惑的模式，其中 Claude 會通過技能工具調用技能，然後嘗試單獨讀取技能文件。`using-superpowers` 技能現在明確說明技能工具直接加載技能內容，無需讀取文件。

- 為 `using-superpowers` 添加了「如何訪問技能」部分
- 將說明從「讀取技能」改為「調用技能」
- 更新了斜杠命令以使用完全限定的技能名稱（例如 `superpowers:brainstorming`）

**為 receiving-code-review 添加了 GitHub 線程回復指南** (感謝 @ralphbean)

添加了關於在原始線程中回復內聯審查評論而不是作為頂級拉請求評論的說明。

**為 writing-skills 添加了自動化優於文檔化的指南** (感謝 @EthanJStark)

添加了機械約束應自動化而非文檔化的指南，將技能留給判斷調用。

## v4.0.0 (2025-12-17)

### 新功能

**subagent-driven-development 中的兩階段代碼審查**

Subagent 工作流在每個任務後使用兩個獨立的審查階段：

1. **規格符合性審查** - 持懷疑態度的審查者驗證實現完全符合規格。同時捕獲缺失的需求和過度構建。不會相信實現者的報告，會讀取實際代碼。

2. **代碼質量審查** - 只在規格符合性通過後運行。審查乾淨代碼、測試覆蓋率、可維護性。

這捕獲了常見的失敗模式，其中代碼編寫良好但不符合請求。審查是循環，不是一次性的：如果審查者發現問題，實現者修復問題，然後審查者再次檢查。

其他 subagent 工作流改進：
- 控制器向工作人員提供完整任務文本（不是文件引用）
- 工作人員可以在工作前和工作期間提出澄清問題
- 報告完成前的自審核檢查清單
- 計劃在開始時讀一次，提取到 TodoWrite

`skills/subagent-driven-development/` 中的新提示模板：
- `implementer-prompt.md` - 包括自審核檢查清單，鼓勵提問
- `spec-reviewer-prompt.md` - 對需求的持懷疑態度的驗證
- `code-quality-reviewer-prompt.md` - 標準代碼審查

**調試技術與工具整合**

`systematic-debugging` 現在包含支持技術和工具：
- `root-cause-tracing.md` - 通過調用堆棧向後跟蹤錯誤
- `defense-in-depth.md` - 在多個層添加驗證
- `condition-based-waiting.md` - 用條件輪詢替換任意超時
- `find-polluter.sh` - 平分腳本，找出哪個測試造成污染
- `condition-based-waiting-example.ts` - 來自真實調試會話的完整實現

**測試反模式參考**

`test-driven-development` 現在包括 `testing-anti-patterns.md`，涵蓋：
- 測試模擬行為而非真實行為
- 向生產類添加僅測試方法
- 在不理解依賴關係的情況下模擬
- 隱藏結構假設的不完整模擬

**技能測試基礎設施**

三個新的測試框架用於驗證技能行為：

`tests/skill-triggering/` - 驗證技能從無指導提示觸發而無需明確命名。測試 6 個技能以確保描述本身是充分的。

`tests/claude-code/` - 使用 `claude -p` 進行無頭測試的集成測試。通過會話記錄（JSONL）分析驗證技能使用。包括用於成本跟蹤的 `analyze-token-usage.py`。

`tests/subagent-driven-dev/` - 具有兩個完整測試項目的端到端工作流驗證：
- `go-fractals/` - 帶有謝爾平斯基/曼德布羅特集的 CLI 工具（10 個任務）
- `svelte-todo/` - 帶有 localStorage 和 Playwright 的 CRUD 應用（12 個任務）

### 主要變更

**DOT 流程圖作為可執行規範**

使用 DOT/GraphViz 流程圖作為權威流程定義重寫了關鍵技能。散文變成支持內容。

**描述陷阱** (記錄在 `writing-skills` 中)：發現當描述包含工作流摘要時，技能描述會覆蓋流程圖內容。Claude 遵循簡短描述而不是讀取詳細流程圖。修復：描述必須是僅觸發「使用時 X」，沒有流程細節。

**using-superpowers 中的技能優先級**

當多個技能適用時，流程技能（腦力激蕩、調試）現在明確優先於實現技能。「構建 X」首先觸發腦力激蕩，然後觸發領域技能。

**加強的腦力激蕩觸發器**

描述更改為祈使句：「在任何創意工作前，您必須使用這個，包括創建功能、構建組件、添加功能或修改行為。」

### 破壞性變更

**技能整合** - 六個獨立技能已合併：
- `root-cause-tracing`、`defense-in-depth`、`condition-based-waiting` → 合併到 `systematic-debugging/`
- `testing-skills-with-subagents` → 合併到 `writing-skills/`
- `testing-anti-patterns` → 合併到 `test-driven-development/`
- `sharing-skills` 已移除（已過時）

### 其他改進

- **render-graphs.js** - 從技能提取 DOT 圖表並渲染為 SVG 的工具
- **using-superpowers 中的合理化表** - 掃描格式，包括新條目：「我需要更多背景首先」、「讓我首先探索」、「這感覺很有成效」
- **docs/testing.md** - 使用 Claude Code 集成測試測試技能的指南

---

## v3.6.2 (2025-12-03)

### 修復

- **Linux 兼容性**：修復了多語言鉤子包裝器 (`run-hook.cmd`) 以使用 POSIX 兼容語法
  - 在第 16 行將 bash 特定的 `${BASH_SOURCE[0]:-$0}` 替換為標準的 `$0`
  - 解決了 Ubuntu/Debian 系統上 `/bin/sh` 是 dash 時的「錯誤替換」錯誤
  - 修復 #141

---

## v3.5.1 (2025-11-24)

### 變更

- **OpenCode 引導程序重構**：從 `chat.message` 鉤子切換到 `session.created` 事件用於引導程序注入
  - 引導程序現在通過 `session.prompt()` 帶 `noReply: true` 在會話創建時注入
  - 明確告訴模型 using-superpowers 已加載，防止冗餘技能加載
  - 將引導程序內容生成整合到共享 `getBootstrapContent()` 幫助程序
  - 更乾淨的單實現方法（移除回退模式）

---

## v3.5.0 (2025-11-23)

### 添加

- **OpenCode 支持**：OpenCode.ai 的原生 JavaScript 插件
  - 自定義工具：`use_skill` 和 `find_skills`
  - 用於在上下文精簡中跨技能持久化的消息插入模式
  - 通過 chat.message 鉤子自動上下文注入
  - 在 session.compacted 事件上自動重新注入
  - 三層技能優先級：項目 > 個人 > superpowers
  - 項目本地技能支持（`.opencode/skills/`）
  - 與 Codex 共享的核心模塊（`lib/skills-core.js`）用於代碼重用
  - 具有適當隔離的自動化測試套件（`tests/opencode/`）
  - 平台特定文檔（`docs/README.opencode.md`、`docs/README.codex.md`）

### 變更

- **重構的 Codex 實現**：現在使用共享 `lib/skills-core.js` ES 模塊
  - 消除了 Codex 和 OpenCode 之間的代碼重複
  - 技能發現和解析的單一事實來源
  - Codex 通過 Node.js 互操作成功加載 ES 模塊

- **改進的文檔**：重寫了 README 以清楚地解釋問題/解決方案
  - 移除了重複部分和衝突信息
  - 添加了完整的工作流描述（腦力激蕩 → 計劃 → 執行 → 完成）
  - 簡化了平台安裝說明
  - 強調了技能檢查協議而不是自動激活聲明

---

## v3.4.1 (2025-10-31)

### 改進

- 優化了 superpowers 引導程序以消除冗餘技能執行。`using-superpowers` 技能內容現在直接在會話上下文中提供，清楚地指導僅對其他技能使用技能工具。這降低了開銷並防止了代理會執行 `using-superpowers` 的令人困惑的循環，儘管已經從會話開始時從上下文中獲得了內容。

## v3.4.0 (2025-10-30)

### 改進

- 簡化了 `brainstorming` 技能以回到原始的對話視野。移除了帶有正式檢查清單的重量級 6 階段流程，取而代之的是自然對話：一次提一個問題，然後用 200-300 字部分呈現設計並進行驗證。保持文檔和實現交接功能。

## v3.3.1 (2025-10-28)

### 改進

- 更新了 `brainstorming` 技能以要求在提問前進行自主偵察，鼓勵推薦驅動的決策，並防止代理將優先級設定委派回人類。
- 對 `brainstorming` 技能應用了寫作清晰度改進，遵循 Strunk 的「風格要素」原則（省略不必要的詞，將否定轉換為肯定形式，改進並列結構）。

### 錯誤修復

- 澄清了 `writing-skills` 指南，以便它指向正確的代理特定個人技能目錄（Claude Code 的 `~/.claude/skills`，Codex 的 `~/.codex/skills`）。

## v3.3.0 (2025-10-28)

### 新功能

**實驗性 Codex 支持**
- 添加了統一 `superpowers-codex` 腳本，帶有引導程序/使用技能/查找技能命令
- 跨平台 Node.js 實現（在 Windows、macOS、Linux 上工作）
- 命名空間技能：`superpowers:skill-name` 用於 superpowers 技能，`skill-name` 用於個人技能
- 個人技能在名稱匹配時覆蓋 superpowers 技能
- 乾淨的技能顯示：顯示名稱/描述而無原始 frontmatter
- 有用的上下文：為每個技能顯示支持文件目錄
- Codex 的工具映射：TodoWrite→update_plan、subagents→手動回退等
- 帶有最小 AGENTS.md 的引導程序集成用於自動啟動
- 完整的安裝指南和特定於 Codex 的引導程序說明

**與 Claude Code 集成的關鍵差異：**
- 單個統一腳本而不是單獨的工具
- Codex 特定等價物的工具替換系統
- 簡化的 subagent 處理（手動工作而不是委派）
- 更新的術語：「Superpowers 技能」而不是「核心技能」

### 添加的文件
- `.codex/INSTALL.md` - Codex 用戶的安裝指南
- `.codex/superpowers-bootstrap.md` - 帶有 Codex 適配的引導程序說明
- `.codex/superpowers-codex` - 帶有所有功能的統一 Node.js 可執行文件

**注意：** Codex 支持是實驗性的。該集成提供了核心 superpowers 功能，但可能需要根據用戶反饋進行改進。

## v3.2.3 (2025-10-23)

### 改進

**更新了 using-superpowers 技能以使用技能工具而不是讀取工具**
- 將技能調用說明從讀取工具改為技能工具
- 更新描述：「使用讀取工具」→「使用技能工具」
- 更新步驟 3：「使用讀取工具」→「使用技能工具讀取和運行」
- 更新合理化清單：「讀取當前版本」→「運行當前版本」

技能工具是在 Claude Code 中調用技能的適當機制。此更新更正了引導程序說明，以指導代理使用正確的工具。

### 更改的文件
- 已更新：`skills/using-superpowers/SKILL.md` - 將工具引用從讀取改為技能工具

## v3.2.2 (2025-10-21)

### 改進

**加強了 using-superpowers 技能以防對代理合理化**
- 添加了帶有關於強制技能檢查的絕對語言的極度重要塊
  - 「如果有 1% 的機率技能適用，你必須讀它」
  - 「你沒有選擇。你不能通過合理化來逃脫。」
- 添加了強制首次回應協議檢查清單
  - 代理在任何回應前必須完成的 5 步流程
  - 明確「在沒有這個的情況下回應 = 失敗」的後果
- 添加了常見合理化部分，有 8 個特定的規避模式
  - 「這只是一個簡單問題」→ 錯誤
  - 「我可以快速檢查文件」→ 錯誤
  - 「讓我首先收集信息」→ 錯誤
  - 加上 5 個在代理行為中觀察到的其他常見模式

這些變更解決了觀察到的代理行為，即它們對技能使用進行合理化，儘管有明確的說明。有力的語言和預先的反對論點旨在使不遵守更困難。

### 更改的文件
- 已更新：`skills/using-superpowers/SKILL.md` - 添加了三層執行以防止技能跳過合理化

## v3.2.1 (2025-10-20)

### 新功能

**代碼審查者代理現已包含在插件中**
- 為插件的 `agents/` 目錄添加了 `superpowers:code-reviewer` 代理
- 代理根據計劃和編碼標準提供系統代碼審查
- 以前需要用戶進行個人代理配置
- 所有技能引用已更新為使用命名空間 `superpowers:code-reviewer`
- 修復 #55

### 更改的文件
- 新增：`agents/code-reviewer.md` - 帶有審查檢查清單和輸出格式的代理定義
- 已更新：`skills/requesting-code-review/SKILL.md` - 對 `superpowers:code-reviewer` 的引用
- 已更新：`skills/subagent-driven-development/SKILL.md` - 對 `superpowers:code-reviewer` 的引用

## v3.2.0 (2025-10-18)

### 新功能

**腦力激蕩工作流中的設計文檔**
- 在腦力激蕩技能中添加了第 4 階段：設計文檔
- 設計文檔現在在實現前寫入 `docs/plans/YYYY-MM-DD-<topic>-design.md`
- 恢復了原始腦力激蕩命令中丟失的功能，在技能轉換期間丟失
- 文檔在工作樹設置和實現計劃前寫入
- 在時間壓力下與 subagent 測試以驗證符合性

### 破壞性變更

**技能引用命名空間標準化**
- 所有內部技能引用現在使用 `superpowers:` 命名空間前綴
- 更新格式：`superpowers:test-driven-development`（以前只是 `test-driven-development`）
- 影響所有需要的子技能、推薦的子技能和需要的背景引用
- 與技能工具如何調用技能保持一致
- 更新的文件：腦力激蕩、執行計劃、subagent 驅動開發、系統調試、子代理測試技能、寫入計劃、寫入技能

### 改進

**設計與實現計劃命名**
- 設計文檔使用 `-design.md` 後綴以防止文件名衝突
- 實現計劃繼續使用現有 `YYYY-MM-DD-<feature-name>.md` 格式
- 兩者都存儲在 `docs/plans/` 目錄中，具有清晰的命名區分

## v3.1.1 (2025-10-17)

### 錯誤修復

- **修復 README 中的命令語法** (#44) - 更新所有命令引用以使用正確的命名空間語法（`/superpowers:brainstorm` 而不是 `/brainstorm`）。插件提供的命令會自動按 Claude Code 進行命名空間以避免插件之間的衝突。

## v3.1.0 (2025-10-17)

### 破壞性變更

**技能名稱標準化為小寫**
- 所有技能 frontmatter `name:` 字段現在使用與目錄名匹配的小寫 kebab-case
- 範例：`brainstorming`、`test-driven-development`、`using-git-worktrees`
- 所有技能公告和交叉引用已更新為小寫格式
- 這確保了目錄名、frontmatter 和文檔中的一致命名

### 新功能

**增強的腦力激蕩技能**
- 添加了顯示階段、活動和工具使用的快速參考表
- 添加了用於跟蹤進度的可複製工作流檢查清單
- 添加了決策流程圖，用於何時重新訪問早期階段
- 添加了包含具體示例的綜合 AskUserQuestion 工具指南
- 添加了解釋何時使用結構化與開放式問題的「問題模式」部分
- 將關鍵原則重構為可掃描表

**Anthropic 最佳實踐集成**
- 添加了 `skills/writing-skills/anthropic-best-practices.md` - 官方 Anthropic 技能編寫指南
- 在 writing-skills SKILL.md 中引用以獲得全面指南
- 提供了漸進式公開、工作流和評估的模式

### 改進

**技能交叉引用清晰度**
- 所有技能引用現在使用明確的要求標記：
  - `**需要的背景：**` - 必須理解的先決條件
  - `**需要的子技能：**` - 必須在工作流中使用的技能
  - `**補充技能：**` - 可選但有幫助的相關技能
- 移除了舊路徑格式（`skills/collaboration/X` → 只是 `X`）
- 用分類關係（需要的 vs 補充的）更新了集成部分
- 用最佳實踐更新了交叉引用文檔

**與 Anthropic 最佳實踐的對齊**
- 修復了描述語法和語調（完全第三人稱）
- 為掃描添加了快速參考表
- 為 Claude 可以複製和跟蹤的工作流添加了檢查清單
- 對非明顯決策點適當使用流程圖
- 改進了可掃描表格式
- 所有技能遠低於 500 行建議

### 錯誤修復

- **重新添加了缺失的命令重定向** - 恢復了在 v3.0 遷移中意外移除的 `commands/brainstorm.md` 和 `commands/write-plan.md`
- 修復了 `defense-in-depth` 名稱不匹配（曾是 `Defense-in-Depth-Validation`）
- 修復了 `receiving-code-review` 名稱不匹配（曾是 `Code-Review-Reception`）
- 修復了 `commands/brainstorm.md` 到正確技能名稱的引用
- 移除了對不存在的相關技能的引用

### 文檔

**writing-skills 改進**
- 使用明確的要求標記更新了交叉引用指南
- 添加了對 Anthropic 官方最佳實踐的引用
- 改進了顯示適當技能引用格式的示例

## v3.0.1 (2025-10-16)

### 變更

我們現在使用 Anthropic 的一方技能系統！

## v2.0.2 (2025-10-12)

### 錯誤修復

- **修復了當本地技能倉庫領先上游時的錯誤警告** - 初始化腳本在本地倉庫有領先上游的提交時錯誤地警告「有新技能可從上游獲得」。邏輯現在正確區分三個 git 狀態：本地落後（應更新）、本地領先（無警告）和分歧（應警告）。

## v2.0.1 (2025-10-12)

### 錯誤修復

- **修復了插件上下文中的會話啟動鉤子執行** (#8, PR #9) - 鉤子因「插件鉤子錯誤」而靜默失敗，防止技能上下文加載。通過以下方式修復：
  - 在 Claude Code 執行上下文中 BASH_SOURCE 未綁定時使用 `${BASH_SOURCE[0]:-$0}` 回退
  - 向 `|| true` 添加以在篩選狀態標誌時優雅地處理空 grep 結果

---

# Superpowers v2.0.0 發布說明

## 概述

Superpowers v2.0 通過主要架構轉變使技能更易訪問、可維護和社區驅動。

標題更改是**技能倉庫分離**：所有技能、腳本和文檔已從插件移至專用倉庫 ([obra/superpowers-skills](https://github.com/obra/superpowers-skills))。這將 superpowers 從單片插件轉變為管理技能倉庫本地克隆的輕量級墊片。技能在會話開始時自動更新。用戶通過標準 git 工作流分叉和貢獻改進。技能庫獨立於插件進行版本控制。

除了基礎設施外，此版本還添加了九個新技能，重點關注問題解決、研究和架構。我們用祈使語氣和更清晰的結構重寫了核心 **using-skills** 文檔，使 Claude 更容易理解何時以及如何使用技能。**find-skills** 現在輸出可以直接粘貼到讀取工具中的路徑，消除了技能發現工作流中的摩擦。

用戶體驗無縫運行：插件自動處理克隆、分叉和更新。貢獻者發現新架構使改進和共享技能變得簡單。此版本為技能作為社區資源快速演化奠定了基礎。

## 破壞性變更

### 技能倉庫分離

**最大的變更：** 技能不再在插件中。它們已被移至 [obra/superpowers-skills](https://github.com/obra/superpowers-skills) 的獨立倉庫。

**對你的意義：**

- **首次安裝：** 插件自動將技能克隆到 `~/.config/superpowers/skills/`
- **分叉：** 在設置期間，如果安裝了 `gh`，你將被提供分叉技能倉庫的選項
- **更新：** 技能在會話開始時自動更新（可能的情況下進行快進）
- **貢獻：** 在分支上工作，在本地提交，向上游提交拉請求
- **不再遮蔽：** 舊的兩層系統（個人/核心）被單倉庫分支工作流替換

**遷移：**

如果你有現有安裝：
1. 你的舊 `~/.config/superpowers/.git` 將被備份到 `~/.config/superpowers/.git.bak`
2. 舊技能將備份到 `~/.config/superpowers/skills.bak`
3. obra/superpowers-skills 的新克隆將在 `~/.config/superpowers/skills/` 創建

### 移除的功能

- **個人 superpowers 覆蓋系統** - 被 git 分支工作流替換
- **setup-personal-superpowers 鉤子** - 被 initialize-skills.sh 替換

## 新功能

### 技能倉庫基礎設施

**自動克隆和設置** (`lib/initialize-skills.sh`)
- 在首次運行時克隆 obra/superpowers-skills
- 如果安裝了 GitHub CLI，提供創建分叉的選項
- 正確設置上游/原始遠程
- 處理來自舊安裝的遷移

**自動更新**
- 在每個會話開始時從跟蹤遠程獲取
- 可能時使用快進自動合併
- 通知何時需要手動同步（分支分歧）
- 使用 pulling-updates-from-skills-repository 技能進行手動同步

### 新技能

**問題解決技能** (`skills/problem-solving/`)
- **collision-zone-thinking** - 強制不相關概念碰撞以獲得新興洞察
- **inversion-exercise** - 翻轉假設以揭示隱藏的約束
- **meta-pattern-recognition** - 跨領域發現普遍原則
- **scale-game** - 在極端情況下測試以暴露基本真理
- **simplification-cascades** - 發現消除多個組件的洞察
- **when-stuck** - 派遣至正確的問題解決技術

**研究技能** (`skills/research/`)
- **tracing-knowledge-lineages** - 理解想法如何隨時間演變

**架構技能** (`skills/architecture/`)
- **preserving-productive-tensions** - 保持多個有效方法而不是強制過早解決

### 技能改進

**using-skills （以前是 getting-started）**
- 從 getting-started 重命名為 using-skills
- 用祈使語氣完全重寫 (v4.0.0)
- 前置關鍵規則
- 為所有工作流添加了「為什麼」解釋
- 在引用中始終包括 /SKILL.md 後綴
- 硬性規則和靈活模式之間更清晰的區分

**writing-skills**
- 從 using-skills 移動的交叉引用指南
- 添加了 token 效率部分（字數目標）
- 改進的 CSO （Claude 搜索優化）指南

**sharing-skills**
- 為新分支和拉請求工作流更新 (v2.0.0)
- 移除了個人/核心拆分引用

**pulling-updates-from-skills-repository** (新)
- 用於與上游同步的完整工作流
- 替換舊的「updating-skills」技能

### 工具改進

**find-skills**
- 現在輸出帶有 /SKILL.md 後綴的完整路徑
- 使路徑與讀取工具直接可用
- 更新了幫助文本

**skill-run**
- 從 scripts/ 移至 skills/using-skills/
- 改進的文檔

### 插件基礎設施

**會話啟動鉤子**
- 現在從技能倉庫位置加載
- 在會話開始時顯示完整的技能列表
- 打印技能位置信息
- 顯示更新狀態（成功更新 / 落後上游）
- 將「技能落後」警告移至輸出末尾

**環境變數**
- `SUPERPOWERS_SKILLS_ROOT` 設為 `~/.config/superpowers/skills`
- 在所有路徑中一致使用

## 錯誤修復

- 修復了分叉時重複添加上游遠程
- 修復了 find-skills 輸出中的雙重「skills/」前綴
- 從會話啟動移除了過時的 setup-personal-superpowers 調用
- 修復了整個鉤子和命令中的路徑引用

## 文檔

### README
- 為新的技能倉庫架構更新
- 向 superpowers-skills 倉庫的突出鏈接
- 更新了自動更新描述
- 修復了技能名稱和引用
- 更新了元技能列表

### 測試文檔
- 添加了綜合測試檢查清單（`docs/TESTING-CHECKLIST.md`）
- 為測試創建了本地市場配置
- 記錄的手動測試場景

## 技術細節

### 文件更改

**添加：**
- `lib/initialize-skills.sh` - 技能倉庫初始化和自動更新
- `docs/TESTING-CHECKLIST.md` - 手動測試場景
- `.claude-plugin/marketplace.json` - 本地測試配置

**移除：**
- `skills/` 目錄 (82 個文件) - 現在在 obra/superpowers-skills
- `scripts/` 目錄 - 現在在 obra/superpowers-skills/skills/using-skills/
- `hooks/setup-personal-superpowers.sh` - 過時

**修改：**
- `hooks/session-start.sh` - 從 ~/.config/superpowers/skills 使用技能
- `commands/brainstorm.md` - 更新了路徑至 SUPERPOWERS_SKILLS_ROOT
- `commands/write-plan.md` - 更新了路徑至 SUPERPOWERS_SKILLS_ROOT
- `commands/execute-plan.md` - 更新了路徑至 SUPERPOWERS_SKILLS_ROOT
- `README.md` - 為新架構完全重寫

### 提交歷史

此版本包括：
- 20+ 項提交用於技能倉庫分離
- PR #1：Amplifier 啟發的問題解決和研究技能
- PR #2：個人 superpowers 覆蓋系統（稍後被替換）
- 多項技能改進和文檔改進

## 升級說明

### 新安裝

```bash
# 在 Claude Code 中
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

插件會自動處理所有事情。

### 從 v1.x 升級

1. **備份個人技能** (如果有的話)：
   ```bash
   cp -r ~/.config/superpowers/skills ~/superpowers-skills-backup
   ```

2. **更新插件：**
   ```bash
   /plugin update superpowers
   ```

3. **在下一個會話開始時：**
   - 舊安裝將自動備份
   - 新技能倉庫將被克隆
   - 如果你有 GitHub CLI，你將被提供分叉選項

4. **遷移個人技能** (如果有的話)：
   - 在本地技能倉庫中創建一個分支
   - 從備份複製個人技能
   - 提交並推送到分叉
   - 考慮通過拉請求貢獻回去

## 接下來呢

### 對於用戶

- 探索新的問題解決技能
- 嘗試基於分支的技能改進工作流
- 為社區貢獻技能

### 對於貢獻者

- 技能倉庫現在位於 https://github.com/obra/superpowers-skills
- 分叉 → 分支 → 拉請求工作流
- 參見 skills/meta/writing-skills/SKILL.md 了解 TDD 方法的文檔

## 已知問題

目前無。

## 致謝

- 問題解決技能靈感來自 Amplifier 模式
- 社區貢獻和反饋
- 對技能有效性的廣泛測試和迭代

---

**完整變更日誌：** https://github.com/obra/superpowers/compare/dd013f6...main
**技能倉庫：** https://github.com/obra/superpowers-skills
**問題：** https://github.com/obra/superpowers/issues
