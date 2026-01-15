# 為 Codex 安裝 Superpowers

快速設置以在 Codex 中啟用 superpowers 技能。

## 安裝

1. **複製 superpowers 存儲庫**:
   ```bash
   mkdir -p ~/.codex/superpowers
   cd ~/.codex/superpowers
   git clone https://github.com/obra/superpowers.git .
   ```

2. **創建個人技能目錄**:
   ```bash
   mkdir -p ~/.codex/skills
   ```

3. **更新 ~/.codex/AGENTS.md** 以包括此 superpowers 部分：
   ```markdown
   ## Superpowers 系統

   <EXTREMELY_IMPORTANT>
   您有 superpowers。Superpowers 教導您新的技能和功能。立即運行：`~/.codex/superpowers/.codex/superpowers-codex bootstrap` 並按照它返回的說明操作。
   </EXTREMELY_IMPORTANT>
   ```

## 驗證

測試安裝：
```bash
~/.codex/superpowers/.codex/superpowers-codex bootstrap
```

您應該看到技能列表和引導程序說明。系統現在已準備好使用。