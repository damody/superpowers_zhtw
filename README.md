# Superpowers

Superpowers 是一個為您的編程代理設計的完整軟體開發工作流程系統，建立在一組可組合的「技能」(skills) 和一些確保代理使用這些技能的初始指令之上。

## 工作原理

從您啟動編程代理的那一刻開始，一旦它發現您正在構建某些東西，它*不會*直接跳入嘗試編寫代碼。相反，它會退後一步，詢問您真正想要做什麼。

一旦它從對話中梳理出規格說明，它會以足夠短的片段向您展示，以便您能夠實際閱讀和消化。

在您批准設計後，您的代理會組建一個實作計劃，該計劃清晰到足以讓一個熱情但品味欠佳、缺乏判斷力、沒有專案背景且厭惡測試的初級工程師遵循。它強調真正的紅/綠 TDD、YAGNI（You Aren't Gonna Need It，你不會需要它）和 DRY。

接下來,一旦您說「開始」,它就會啟動一個*子代理驅動開發* (subagent-driven-development) 流程，讓代理完成每個工程任務，檢查和審查他們的工作，然後繼續前進。Claude 通常能夠自主工作幾個小時而不偏離您制定的計劃，這並不罕見。

系統還有更多功能，但這就是核心。由於技能會自動觸發，您不需要做任何特殊的事情。您的編程代理就這樣擁有了 Superpowers。


## 贊助

如果 Superpowers 幫助您完成了賺錢的工作，並且您願意的話，我會非常感激您考慮[贊助我的開源工作](https://github.com/sponsors/obra)。

謝謝！

- Jesse


## 安裝

**注意：** 不同平台的安裝方式不同。Claude Code 有內建的插件系統。Codex 和 OpenCode 需要手動設置。

### Claude Code（通過插件市場）

在 Claude Code 中，首先註冊市場：

```bash
/plugin marketplace add obra/superpowers-marketplace
```

然後從此市場安裝插件：

```bash
/plugin install superpowers@superpowers-marketplace
```

### 驗證安裝

檢查命令是否出現：

```bash
/help
```

```
# 應該看到：
# /superpowers:brainstorm - 互動式設計優化
# /superpowers:write-plan - 創建實作計劃
# /superpowers:execute-plan - 分批執行計劃
```

### Codex

告訴 Codex：

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md
```

**詳細文檔：** [docs/README.codex.md](docs/README.codex.md)

### OpenCode

告訴 OpenCode：

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md
```

**詳細文檔：** [docs/README.opencode.md](docs/README.opencode.md)

## 基本工作流程

1. **brainstorming（腦力激盪）** - 在撰寫代碼前啟動。通過提問優化粗略的想法，探索替代方案，分段呈現設計以供驗證。保存設計文檔。

2. **using-git-worktrees（使用 Git 工作樹）** - 在設計批准後啟動。在新分支上創建隔離的工作空間，運行專案設置，驗證乾淨的測試基線。

3. **writing-plans（撰寫計劃）** - 在設計批准後啟動。將工作分解為小任務（每個 2-5 分鐘）。每個任務都有確切的文件路徑、完整的代碼和驗證步驟。

4. **subagent-driven-development（子代理驅動開發）** 或 **executing-plans（執行計劃）** - 有計劃時啟動。為每個任務派遣新的子代理並進行兩階段審查（規格合規性，然後代碼質量），或者分批執行並設置人工檢查點。

5. **test-driven-development（測試驅動開發）** - 在實作期間啟動。強制執行 RED-GREEN-REFACTOR：撰寫失敗的測試，觀察其失敗，撰寫最小化代碼，觀察其通過，提交。刪除在測試之前撰寫的代碼。

6. **requesting-code-review（請求代碼審查）** - 在任務之間啟動。根據計劃審查，按嚴重程度報告問題。關鍵問題會阻止進度。

7. **finishing-a-development-branch（完成開發分支）** - 任務完成時啟動。驗證測試，呈現選項（合併/PR/保留/丟棄），清理工作樹。

**代理在執行任何任務前都會檢查相關技能。** 這些是強制性工作流程，而非建議。

## 內容

### 技能庫

**測試**
- **test-driven-development（測試驅動開發）** - RED-GREEN-REFACTOR 循環（包含測試反模式參考）

**除錯**
- **systematic-debugging（系統性除錯）** - 4 階段根本原因流程（包含根本原因追蹤、縱深防禦、基於條件的等待技術）
- **verification-before-completion（完成前驗證）** - 確保真正修復

**協作**
- **brainstorming（腦力激盪）** - 蘇格拉底式設計優化
- **writing-plans（撰寫計劃）** - 詳細的實作計劃
- **executing-plans（執行計劃）** - 帶檢查點的分批執行
- **dispatching-parallel-agents（派遣並行代理）** - 並發子代理工作流程
- **requesting-code-review（請求代碼審查）** - 預審查檢查清單
- **receiving-code-review（接收代碼審查）** - 回應反饋
- **using-git-worktrees（使用 Git 工作樹）** - 並行開發分支
- **finishing-a-development-branch（完成開發分支）** - 合併/PR 決策工作流程
- **subagent-driven-development（子代理驅動開發）** - 快速迭代與兩階段審查（規格合規性，然後代碼質量）

**元技能**
- **writing-skills（撰寫技能）** - 遵循最佳實踐創建新技能（包含測試方法論）
- **using-superpowers（使用 Superpowers）** - 技能系統介紹

## 理念

- **測試驅動開發** - 總是先撰寫測試
- **系統性優於臨時性** - 流程優於猜測
- **降低複雜性** - 簡單性是首要目標
- **證據優於聲稱** - 在宣布成功前先驗證

閱讀更多：[Superpowers for Claude Code](https://blog.fsck.com/2025/10/09/superpowers/)

## 貢獻

技能直接存在於此存儲庫中。要貢獻：

1. Fork 此存儲庫
2. 為您的技能創建一個分支
3. 遵循 `writing-skills` 技能來創建和測試新技能
4. 提交 PR

查看 `skills/writing-skills/SKILL.md` 以獲取完整指南。

## 更新

更新插件時技能會自動更新：

```bash
/plugin update superpowers
```

## 授權

MIT 授權 - 詳情請參閱 LICENSE 文件

## 支持

- **問題回報**: https://github.com/obra/superpowers/issues
- **市場**: https://github.com/obra/superpowers-marketplace
