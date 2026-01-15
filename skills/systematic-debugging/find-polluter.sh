#!/usr/bin/env bash
# 二分查找腳本以找到哪個測試創建了不需要的文件/狀態
# 用法: ./find-polluter.sh <file_or_dir_to_check> <test_pattern>
# 示例: ./find-polluter.sh '.git' 'src/**/*.test.ts'

set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 <file_to_check> <test_pattern>"
  echo "Example: $0 '.git' 'src/**/*.test.ts'"
  exit 1
fi

POLLUTION_CHECK="$1"
TEST_PATTERN="$2"

echo "🔍 正在搜索創建以下項目的測試: $POLLUTION_CHECK"
echo "Test pattern: $TEST_PATTERN"
echo ""

# 獲取測試文件列表
TEST_FILES=$(find . -path "$TEST_PATTERN" | sort)
TOTAL=$(echo "$TEST_FILES" | wc -l | tr -d ' ')

echo "找到 $TOTAL 個測試文件"
echo ""

COUNT=0
for TEST_FILE in $TEST_FILES; do
  COUNT=$((COUNT + 1))

  # 如果污染已經存在則跳過
  if [ -e "$POLLUTION_CHECK" ]; then
    echo "⚠️  在測試 $COUNT/$TOTAL 之前污染已存在"
    echo "   跳過: $TEST_FILE"
    continue
  fi

  echo "[$COUNT/$TOTAL] 正在測試: $TEST_FILE"

  # 運行測試
  npm test "$TEST_FILE" > /dev/null 2>&1 || true

  # 檢查污染是否出現
  if [ -e "$POLLUTION_CHECK" ]; then
    echo ""
    echo "🎯 找到污染源!"
    echo "   測試: $TEST_FILE"
    echo "   已創建: $POLLUTION_CHECK"
    echo ""
    echo "污染詳情:"
    ls -la "$POLLUTION_CHECK"
    echo ""
    echo "要調查:"
    echo "  npm test $TEST_FILE    # 只運行此測試"
    echo "  cat $TEST_FILE         # 查看測試代碼"
    exit 1
  fi
done

echo ""
echo "✅ 未找到污染源 - 所有測試都是乾��淨的!"
exit 0
