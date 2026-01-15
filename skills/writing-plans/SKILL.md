---
name: writing-plans
description: 當您有多步驟任務的規格或需求時使用，在接觸代碼之前
---

# 撰寫計劃

## 概述

撰寫全面的實作計劃，假設工程師對我們的代碼庫零了解且品味可疑。記錄他們需要知道的一切：每個任務要接觸哪些文件、代碼、測試、他們可能需要檢查的文檔、如何測試。將整個計劃分解為小任務。DRY。YAGNI。TDD。頻繁提交。

假設他們是熟練的開發者，但對我們的工具集或問題領域幾乎一無所知。假設他們對良好的測試設計不太了解。

**開始時宣告：** 「我正在使用 writing-plans 技能創建實作計劃。」

**背景：** 這應該在專用的工作樹中運行（由 brainstorming 技能創建）。

**保存計劃到：** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## 小任務粒度

**每個步驟是一個動作（2-5 分鐘）：**
- 「撰寫失敗的測試」 - 步驟
- 「運行它以確保失敗」 - 步驟
- 「實作使測試通過的最小化代碼」 - 步驟
- 「運行測試並確保通過」 - 步驟
- 「提交」 - 步驟

## 計劃文檔標題

**每個計劃必須以此標題開始：**

```markdown
# [功能名稱] 實作計劃

> **給 Claude：** 必需的子技能：使用 superpowers:executing-plans 逐個任務實作此計劃。

**目標：** [一句話描述要構建什麼]

**架構：** [2-3 句話關於方法]

**技術棧：** [關鍵技術/庫]

---
```

## 任務結構

```markdown
### 任務 N：[組件名稱]

**文件：**
- 創建：`exact/path/to/file.py`
- 修改：`exact/path/to/existing.py:123-145`
- 測試：`tests/exact/path/to/test.py`

**步驟 1：撰寫失敗的測試**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**步驟 2：運行測試以驗證其失敗**

運行：`pytest tests/path/test.py::test_name -v`
預期：FAIL 並顯示 "function not defined"

**步驟 3：撰寫最小化實作**

```python
def function(input):
    return expected
```

**步驟 4：運行測試以驗證其通過**

運行：`pytest tests/path/test.py::test_name -v`
預期：PASS

**步驟 5：提交**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
```

## 記住
- 總是使用確切的文件路徑
- 計劃中包含完整代碼（不是「添加驗證」）
- 具有預期輸出的確切命令
- 使用 @ 語法引用相關技能
- DRY、YAGNI、TDD、頻繁提交

## 執行交接

保存計劃後，提供執行選擇：

**「計劃完成並保存到 `docs/plans/<filename>.md`。兩個執行選項：**

**1. 子代理驅動（此會話）** - 我為每個任務派遣新的子代理，任務之間審查，快速迭代

**2. 並行會話（分開）** - 使用 executing-plans 打開新會話，帶檢查點的分批執行

**選擇哪種方法？」**

**如果選擇子代理驅動：**
- **必需的子技能：** 使用 superpowers:subagent-driven-development
- 留在此會話中
- 每個任務新的子代理 + 代碼審查

**如果選擇並行會話：**
- 引導他們在工作樹中打開新會話
- **必需的子技能：** 新會話使用 superpowers:executing-plans
