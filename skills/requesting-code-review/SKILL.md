---
name: requesting-code-review
description: 完成任務、實作主要功能或在合併前使用，以驗證工作是否滿足需求
---

# 請求代碼審查

派遣 superpowers:code-reviewer 子代理在問題級聯之前捕獲它們。

**核心原則：** 早審查，常審查。

## 何時請求審查

**強制性：**
- 子代理驅動開發中每個任務後
- 完成主要功能後
- 合併到 main 之前

**可選但有價值：**
- 遇到困難時（新視角）
- 重構之前（基線檢查）
- 修復複雜 bug 後

## 如何請求

**1. 獲取 git SHA：**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # 或 origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. 派遣 code-reviewer 子代理：**

使用帶 superpowers:code-reviewer 類型的 Task 工具，填寫 `code-reviewer.md` 的模板

**占位符：**
- `{WHAT_WAS_IMPLEMENTED}` - 您剛構建的內容
- `{PLAN_OR_REQUIREMENTS}` - 它應該做什麼
- `{BASE_SHA}` - 起始提交
- `{HEAD_SHA}` - 結束提交
- `{DESCRIPTION}` - 簡要摘要

**3. 根據反饋行動：**
- 立即修復關鍵問題
- 繼續前修復重要問題
- 記錄次要問題稍後處理
- 如果審查者錯了則回推（附理由）

## 範例

```
[剛完成任務 2：添加驗證函數]

您：讓我在繼續前請求代碼審查。

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[派遣 superpowers:code-reviewer 子代理]
  WHAT_WAS_IMPLEMENTED：對話索引的驗證和修復函數
  PLAN_OR_REQUIREMENTS：docs/plans/deployment-plan.md 中的任務 2
  BASE_SHA：a7981ec
  HEAD_SHA：3df7661
  DESCRIPTION：添加了 verifyIndex() 和 repairIndex()，包含 4 種問題類型

[子代理返回]：
  優點：乾淨的架構，真實的測試
  問題：
    重要：缺少進度指標
    次要：魔術數字（100）用於報告間隔
  評估：準備繼續

您：[修復進度指標]
[繼續任務 3]
```

## 與工作流程整合

**子代理驅動開發：**
- 每個任務後審查
- 在問題加劇前捕獲
- 移至下一個任務前修復

**執行計劃：**
- 每批（3 個任務）後審查
- 獲取反饋，應用，繼續

**臨時開發：**
- 合併前審查
- 遇到困難時審查

## 紅旗警示

**絕不：**
- 因為「很簡單」而跳過審查
- 忽略關鍵問題
- 在重要問題未修復時繼續
- 與有效的技術反饋爭論

**如果審查者錯了：**
- 用技術推理回推
- 展示證明其有效的代碼/測試
- 請求澄清

模板位於：requesting-code-review/code-reviewer.md
