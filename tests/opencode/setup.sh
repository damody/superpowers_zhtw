#!/usr/bin/env bash
# OpenCode 插件測試的設置腳本
# 創建具有正確插件安裝的隔離測試環境
set -euo pipefail

# 獲取倉庫根目錄(從 tests/opencode/ 上兩層)
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# 創建臨時主目錄以進行隔離
export TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"
export XDG_CONFIG_HOME="$TEST_HOME/.config"
export OPENCODE_CONFIG_DIR="$TEST_HOME/.config/opencode"

# 將插件安裝到測試位置
mkdir -p "$HOME/.config/opencode/superpowers"
cp -r "$REPO_ROOT/lib" "$HOME/.config/opencode/superpowers/"
cp -r "$REPO_ROOT/skills" "$HOME/.config/opencode/superpowers/"

# 複製插件目錄
mkdir -p "$HOME/.config/opencode/superpowers/.opencode/plugin"
cp "$REPO_ROOT/.opencode/plugin/superpowers.js" "$HOME/.config/opencode/superpowers/.opencode/plugin/"

# 通過符號鏈接註冊插件
mkdir -p "$HOME/.config/opencode/plugin"
ln -sf "$HOME/.config/opencode/superpowers/.opencode/plugin/superpowers.js" \
       "$HOME/.config/opencode/plugin/superpowers.js"

# 在不同位置創建測試技能以進行測試

# 個人測試技能
mkdir -p "$HOME/.config/opencode/skills/personal-test"
cat > "$HOME/.config/opencode/skills/personal-test/SKILL.md" <<'EOF'
---
name: personal-test
description: Test personal skill for verification
---
# Personal Test Skill

This is a personal skill used for testing.

PERSONAL_SKILL_MARKER_12345
EOF

# 為項目級技能測試創建項目目錄
mkdir -p "$TEST_HOME/test-project/.opencode/skills/project-test"
cat > "$TEST_HOME/test-project/.opencode/skills/project-test/SKILL.md" <<'EOF'
---
name: project-test
description: Test project skill for verification
---
# Project Test Skill

This is a project skill used for testing.

PROJECT_SKILL_MARKER_67890
EOF

echo "Setup complete: $TEST_HOME"
echo "Plugin installed to: $HOME/.config/opencode/superpowers/.opencode/plugin/superpowers.js"
echo "Plugin registered at: $HOME/.config/opencode/plugin/superpowers.js"
echo "Test project at: $TEST_HOME/test-project"

# 清理的輔助函數(從測試或陷阱調用)
cleanup_test_env() {
    if [ -n "${TEST_HOME:-}" ] && [ -d "$TEST_HOME" ]; then
        rm -rf "$TEST_HOME"
    fi
}

# 導出以在測試中使用
export -f cleanup_test_env
export REPO_ROOT
