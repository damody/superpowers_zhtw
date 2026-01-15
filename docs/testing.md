# 測試 Superpowers 技能

本文檔描述了如何測試 Superpowers 技能，特別是對於 `subagent-driven-development` 等複雜技能的集成測試。

## 概述

涉及 subagents、工作流和複雜交互的測試技能需要在無頭模式下運行實際 Claude Code 會話，並通過會話記錄驗證其行為。

## 測試結構

```
tests/
├── claude-code/
│   ├── test-helpers.sh                    # 共享測試實用程序
│   ├── test-subagent-driven-development-integration.sh
│   ├── analyze-token-usage.py             # 令牌分析工具
│   └── run-skill-tests.sh                 # 測試運行器（如果存在）
```

## 運行測試

### 集成測試

集成測試執行具有實際技能的真實 Claude Code 會話：

```bash
# 運行 subagent-driven-development 集成測試
cd tests/claude-code
./test-subagent-driven-development-integration.sh
```

**注意：** 集成測試可以花費 10-30 分鐘，因為它們執行帶有多個 subagents 的真實實現計劃。

### 要求

- 必須從 **superpowers 插件目錄**（而非臨時目錄）運行
- Claude Code 必須已安裝且可作為 `claude` 命令使用
- 本地開發市場必須啟用：`~/.claude/settings.json` 中的 `"superpowers@superpowers-dev": true`

## 集成測試：subagent-driven-development

### 它測試什麼

集成測試驗證 `subagent-driven-development` 技能是否正確：

1. **計劃加載**：在開始時讀一次計劃
2. **完整任務文本**：向 subagents 提供完整的任務描述（不讓他們讀文件）
3. **自審核**：確保 subagents 在報告前進行自審核
4. **審查順序**：在代碼質量審查前運行規格符合性審查
5. **審查循環**：發現問題時使用審查循環
6. **獨立驗證**：規格審查者獨立讀取代碼，不信任實現者報告

### 它的工作原理

1. **設置**：使用最小實現計劃創建臨時 Node.js 項目
2. **執行**：在無頭模式下使用技能運行 Claude Code
3. **驗證**：解析會話記錄（`.jsonl` 文件）以驗證：
   - 技能工具已調用
   - Subagents 已派遣（Task 工具）
   - TodoWrite 已使用於跟蹤
   - 已創建實現文件
   - 測試通過
   - Git 提交顯示正確的工作流
4. **令牌分析**：按 subagent 顯示令牌使用分解

### 測試輸出

```
========================================
 集成測試：subagent-driven-development
========================================

測試項目：/tmp/tmp.xyz123

=== 驗證測試 ===

測試 1：技能工具已調用...
  [通過] subagent-driven-development 技能已調用

測試 2：已派遣 Subagents...
  [通過] 已派遣 7 個 subagents

測試 3：任務跟蹤...
  [通過] 使用 TodoWrite 5 次

測試 6：實現驗證...
  [通過] 已創建 src/math.js
  [通過] add 函數存在
  [通過] multiply 函數存在
  [通過] 已創建 test/math.test.js
  [通過] 測試通過

測試 7：Git 提交歷史...
  [通過] 已創建多個提交（總共 3 個）

測試 8：未添加額外功能...
  [通過] 未添加額外功能

=========================================
 令牌使用分析
=========================================

使用分解：
----------------------------------------------------------------------------------------------------
代理           描述                          消息數      輸入      輸出      緩存       成本
----------------------------------------------------------------------------------------------------
主會話         主會話（協調員）               34         27      3,996  1,213,703 $   4.09
3380c209      實現任務 1：創建添加函數      1          2        787     24,989 $   0.09
34b00fde      實現任務 2：創建乘法函數     1          4        644     25,114 $   0.09
3801a732      審查實現是否匹配...           1          5        703     25,742 $   0.09
4c142934      進行最終代碼審查...                  1          6        854     25,319 $   0.09
5f017a42      代碼審查者。審查任務 2...              1          6        504     22,949 $   0.08
a6b7fbe4      代碼審查者。審查任務 1...              1          6        515     22,534 $   0.08
f15837c0      審查實現是否匹配...           1          6        416     22,485 $   0.07
----------------------------------------------------------------------------------------------------

合計：
  總消息數：         41
  輸入令牌：           62
  輸出令牌：          8,419
  緩存創建令牌：  132,742
  緩存讀取令牌：      1,382,835

  總輸入（含緩存）：1,515,639
  總令牌數：             1,524,058

  估計成本：$4.67
  （輸入/輸出每 100 萬令牌 $3/$15）

========================================
 測試摘要
========================================

狀態：已通過
```

## 令牌分析工具

### 使用方法

分析來自任何 Claude Code 會話的令牌使用：

```bash
python3 tests/claude-code/analyze-token-usage.py ~/.claude/projects/<project-dir>/<session-id>.jsonl
```

### 查找會話文件

會話記錄存儲在 `~/.claude/projects/` 中，編碼了工作目錄路徑：

```bash
# 示例：/Users/jesse/Documents/GitHub/superpowers/superpowers
SESSION_DIR="$HOME/.claude/projects/-Users-jesse-Documents-GitHub-superpowers-superpowers"

# 查找最近的會話
ls -lt "$SESSION_DIR"/*.jsonl | head -5
```

### 它顯示什麼

- **主會話使用**：協調員（你或主 Claude 實例）的令牌使用
- **每個 subagent 的分解**：每個 Task 調用，帶有：
  - 代理 ID
  - 描述（從提示提取）
  - 消息計數
  - 輸入/輸出令牌
  - 緩存使用
  - 估計成本
- **合計**：總體令牌使用和成本估計

### 理解輸出

- **高緩存讀取**：好的 - 表示提示緩存正在工作
- **主上的高輸入令牌**：預期 - 協調員具有完整上下文
- **每個 subagent 的類似成本**：預期 - 每個獲得類似的任務複雜性
- **每個任務的成本**：根據任務複雜性，典型範圍是 $0.05-$0.15 per subagent

## 故障排除

### 技能未加載

**問題**：運行無頭測試時未找到技能

**解決方案**：
1. 確保你從 superpowers 目錄運行：`cd /path/to/superpowers && tests/...`
2. 檢查 `~/.claude/settings.json` 在 `enabledPlugins` 中有 `"superpowers@superpowers-dev": true`
3. 驗證技能存在於 `skills/` 目錄

### 權限錯誤

**問題**：Claude 被阻止寫入文件或訪問目錄

**解決方案**：
1. 使用 `--permission-mode bypassPermissions` 標誌
2. 使用 `--add-dir /path/to/temp/dir` 授予對測試目錄的訪問
3. 檢查測試目錄上的文件權限

### 測試超時

**問題**：測試花費太長時間並超時

**解決方案**：
1. 增加超時：`timeout 1800 claude ...` (30 分鐘)
2. 檢查技能邏輯中的無限循環
3. 審查 subagent 任務複雜性

### 未找到會話文件

**問題**：無法在測試運行後找到會話記錄

**解決方案**：
1. 檢查 `~/.claude/projects/` 中的正確項目目錄
2. 使用 `find ~/.claude/projects -name "*.jsonl" -mmin -60` 查找最近的會話
3. 驗證測試確實運行了（檢查測試輸出中的錯誤）

## 編寫新的集成測試

### 模板

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# 創建測試項目
TEST_PROJECT=$(create_test_project)
trap "cleanup_test_project $TEST_PROJECT" EXIT

# 設置測試文件...
cd "$TEST_PROJECT"

# 運行 Claude 和技能
PROMPT="你的測試提示在這裡"
cd "$SCRIPT_DIR/../.." && timeout 1800 claude -p "$PROMPT" \
  --allowed-tools=all \
  --add-dir "$TEST_PROJECT" \
  --permission-mode bypassPermissions \
  2>&1 | tee output.txt

# 查找並分析會話
WORKING_DIR_ESCAPED=$(echo "$SCRIPT_DIR/../.." | sed 's/\\//-/g' | sed 's/^-//')
SESSION_DIR="$HOME/.claude/projects/$WORKING_DIR_ESCAPED"
SESSION_FILE=$(find "$SESSION_DIR" -name "*.jsonl" -type f -mmin -60 | sort -r | head -1)

# 通過解析會話記錄驗證行為
if grep -q '"name":"Skill".*"skill":"your-skill-name"' "$SESSION_FILE"; then
    echo "[通過] 技能已調用"
fi

# 顯示令牌分析
python3 "$SCRIPT_DIR/analyze-token-usage.py" "$SESSION_FILE"
```

### 最佳實踐

1. **始終清理**：使用 trap 清理臨時目錄
2. **解析記錄**：不要 grep 面向用戶的輸出，而是解析 `.jsonl` 會話文件
3. **授予權限**：使用 `--permission-mode bypassPermissions` 和 `--add-dir`
4. **從插件目錄運行**：技能只在從 superpowers 目錄運行時加載
5. **顯示令牌使用**：始終包括令牌分析以獲得成本可見性
6. **測試真實行為**：驗證實際文件創建、測試通過、提交進行

## 會話記錄格式

會話記錄是 JSONL（JSON Lines）文件，其中每一行都是代表消息或工具結果的 JSON 對象。

### 關鍵字段

```json
{
  "type": "assistant",
  "message": {
    "content": [...],
    "usage": {
      "input_tokens": 27,
      "output_tokens": 3996,
      "cache_read_input_tokens": 1213703
    }
  }
}
```

### 工具結果

```json
{
  "type": "user",
  "toolUseResult": {
    "agentId": "3380c209",
    "usage": {
      "input_tokens": 2,
      "output_tokens": 787,
      "cache_read_input_tokens": 24989
    },
    "prompt": "你正在實現任務 1...",
    "content": [{"type": "text", "text": "..."}]
  }
}
```

`agentId` 字段鏈接到 subagent 會話，`usage` 字段包含該特定 subagent 調用的令牌使用。
