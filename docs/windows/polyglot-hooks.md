# Claude Code 跨平台多語言鉤子

Claude Code 插件需要在 Windows、macOS 和 Linux 上都能工作的鉤子。本文檔解釋了使這成為可能的多語言包裝器技術。

## 問題

Claude Code 通過系統的默認 shell 運行鉤子命令：
- **Windows**：CMD.exe
- **macOS/Linux**：bash 或 sh

這造成了幾個挑戰：

1. **腳本執行**：Windows CMD 無法直接執行 `.sh` 文件，它試圖在文本編輯器中打開它們
2. **路徑格式**：Windows 使用反斜杠（`C:\path`），Unix 使用正斜杠（`/path`）
3. **環境變數**：`$VAR` 語法在 CMD 中不起作用
4. **PATH 中沒有 `bash`**：即使安裝了 Git Bash，當 CMD 運行時 `bash` 也不在 PATH 中

## 解決方案：多語言 `.cmd` 包裝器

多語言腳本是同時在多種語言中有效的語法。我們的包裝器在 CMD 和 bash 中都有效：

```cmd
: << 'CMDBLOCK'
@echo off
"C:\Program Files\Git\bin\bash.exe" -l -c "\"$(cygpath -u \"$CLAUDE_PLUGIN_ROOT\")/hooks/session-start.sh\""
exit /b
CMDBLOCK

# Unix shell 從這裡運行
"${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"
```

### 它的工作原理

#### 在 Windows (CMD.exe)

1. `: << 'CMDBLOCK'` - CMD 將 `:` 看作標籤（如 `:label`）並忽略 `<< 'CMDBLOCK'`
2. `@echo off` - 禁止命令回顯
3. bash.exe 命令運行帶有：
   - `-l`（登錄 shell）以獲得帶有 Unix 實用程序的適當 PATH
   - `cygpath -u` 將 Windows 路徑轉換為 Unix 格式（`C:\foo` → `/c/foo`）
4. `exit /b` - 退出批處理腳本，在 CMD 中停止
5. `CMDBLOCK` 之後的所有內容不被 CMD 到達

#### 在 Unix (bash/sh)

1. `: << 'CMDBLOCK'` - `:` 是無操作，`<< 'CMDBLOCK'` 開始一個 here-doc
2. 直到 `CMDBLOCK` 的所有內容都由 here-doc 消費（忽略）
3. `# Unix shell 從這裡運行` - 評論
4. 腳本直接以 Unix 路徑運行

## 文件結構

```
hooks/
├── hooks.json           # 指向 .cmd 包裝器
├── session-start.cmd    # 多語言包裝器（跨平台進入點）
└── session-start.sh     # 實際鉤子邏輯（bash 腳本）
```

### hooks.json

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/session-start.cmd\""
          }
        ]
      }
    ]
  }
}
```

注意：路徑必須被引用，因為 `${CLAUDE_PLUGIN_ROOT}` 可能在 Windows 上包含空格（例如 `C:\Program Files\...`）。

## 要求

### Windows
- **必須安裝 Git for Windows**（提供 `bash.exe` 和 `cygpath`）
- 默認安裝路徑：`C:\Program Files\Git\bin\bash.exe`
- 如果 Git 安裝在其他地方，包裝器需要修改

### Unix (macOS/Linux)
- 標準 bash 或 sh shell
- `.cmd` 文件必須有執行權限（`chmod +x`）

## 編寫跨平台鉤子腳本

你的實際鉤子邏輯進入 `.sh` 文件。為了確保它在 Windows 上通過 Git Bash 工作：

### 做：
- 盡可能使用純 bash 內置函數
- 使用 `$(command)` 而不是反引號
- 引用所有變數擴展：`"$VAR"`
- 使用 `printf` 或 here-docs 進行輸出

### 避免：
- 可能不在 PATH 中的外部命令（sed、awk、grep）
- 如果你必須使用它們，它們在 Git Bash 中可用，但確保 PATH 被設置（使用 `bash -l`）

### 示例：不使用 sed/awk 的 JSON 轉義

代替：
```bash
escaped=$(echo "$content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
```

使用純 bash：
```bash
escape_for_json() {
    local input="$1"
    local output=""
    local i char
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        case "$char" in
            $'\\') output+='\\' ;;
            '"') output+='\"' ;;
            $'\n') output+='\n' ;;
            $'\r') output+='\r' ;;
            $'\t') output+='\t' ;;
            *) output+="$char" ;;
        esac
    done
    printf '%s' "$output"
}
```

## 可重用包裝器模式

對於具有多個鉤子的插件，你可以創建一個通用包裝器，將腳本名稱作為參數：

### run-hook.cmd
```cmd
: << 'CMDBLOCK'
@echo off
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME=%~1"
"C:\Program Files\Git\bin\bash.exe" -l -c "cd \"$(cygpath -u \"%SCRIPT_DIR%\")\" && \"./%SCRIPT_NAME%\""
exit /b
CMDBLOCK

# Unix shell 從這裡運行
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
"${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
```

### 使用可重用包裝器的 hooks.json
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" validate-bash.sh"
          }
        ]
      }
    ]
  }
}
```

## 故障排除

### "bash is not recognized"
CMD 找不到 bash。包裝器使用完整路徑 `C:\Program Files\Git\bin\bash.exe`。如果 Git 安裝在其他地方，請更新路徑。

### "cygpath: command not found" 或 "dirname: command not found"
Bash 沒有作為登錄 shell 運行。確保使用 `-l` 標誌。

### 路徑中有奇怪的 `\/`
`${CLAUDE_PLUGIN_ROOT}` 擴展到以反斜杠結尾的 Windows 路徑，然後 `/hooks/...` 被附加。使用 `cygpath` 轉換整個路徑。

### 腳本在文本編輯器中打開而不是運行
hooks.json 直接指向 `.sh` 文件。改為指向 `.cmd` 包裝器。

### 在終端中工作但不作為鉤子
Claude Code 可能以不同的方式運行鉤子。通過模擬鉤子環境進行測試：
```powershell
$env:CLAUDE_PLUGIN_ROOT = "C:\path\to\plugin"
cmd /c "C:\path\to\plugin\hooks\session-start.cmd"
```

## 相關問題

- [anthropics/claude-code#9758](https://github.com/anthropics/claude-code/issues/9758) - .sh 腳本在 Windows 上在編輯器中打開
- [anthropics/claude-code#3417](https://github.com/anthropics/claude-code/issues/3417) - 鉤子在 Windows 上不工作
- [anthropics/claude-code#6023](https://github.com/anthropics/claude-code/issues/6023) - 找不到 CLAUDE_PROJECT_DIR
