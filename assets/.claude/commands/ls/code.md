---
name: "LS: Code"
description: 编码⇄单测内环——逐 task TDD 自动推进直到收敛（AI 开发流水线第 3 步 · loop engine）
category: Workflow
tags: [workflow, ls-pipeline, code, tdd, loop-engine]
---

编码⇄单测**内环**（loop engine）。`/ls:*` 流水线第 3 步（**自动阶段**）。复用 `/opsx:apply` 的 task 驱动语义，叠加 TDD 循环与构建校验。

> **本命令的所有构建/测试命令都从 `ls-pipeline.config.md` 读取**（位置见 AGENTS.md/CLAUDE.md 指引，通常在项目根），而不是硬编码某个工具。开工前先读该配置，取出这些字段：`shell`、`build`（编译/类型检查）、`unit-test`（跑单测：整体命令 + 单测试文件/类模板）、`full-test`（组边界回归命令，可选，缺省回退 `unit-test`）、`coverage`（覆盖率工具+阈值，或 `none`）、`module-layout`（如何指定单个模块/包）。下文用 `<build>`/`<unit-test>`/`<single-test>`/`<full-test>`/`<coverage>` 代指配置里的对应命令。若 config 缺失，停下提示用户先按模板创建。

**前置**：spec 已就绪并经人工批准（`/ls:spec`）。**Input**: 变更名（缺省从对话/分支推断）。

**Steps**

1. **载入变更上下文**
   - `openspec status --change "<name>" --json` 取 schema、`changeRoot`、tasks 位置。
   - `openspec instructions apply --change "<name>" --json` 取 `contextFiles` 与任务清单；读全 proposal/design/tasks/spec。
   - 若含 **Spike 卡点**且未完成：先做 spike，结论写回 `design.md`；spike 不过则停下报告，不进后续编码。

2. **确认覆盖率门（读 config，不探测）**
   - 读 config 的 `coverage` 字段：
     - 有覆盖率工具（如 jacoco/nyc/coverage.py）→ 覆盖率 ≥ 阈值（默认 80%，见 `testing.md`）为硬门。
     - `coverage: none` → 降级为「单测全绿 + 关键分支有测试」硬门，覆盖率作建议。

3. **内环：逐 task 跑 TDD**（这是 loop engine 的内环，快、离线、不碰真模型/外部服务）

   对每个未完成 task（`- [ ]`）：
   - **RED**：先写/补单测（按项目测试框架与命名约定，AAA 结构，命名须被默认测试收集器识别）。
   - **GREEN**：写最小实现让其通过。遵循 `coding-style.md`（不可变、函数<50 行、文件<800 行）。
   - **跑单测**：执行 config 的 `<single-test>`（针对本 task 的测试文件/类）或 `<unit-test>`（整模块/包）。
     - 命令按 config 的 `shell` 语法书写；PowerShell 下 `-D`/带特殊字符的参数须加引号。
   - **REFACTOR**：绿了再清理，保持测试绿。
   - 通过后把该 task `- [ ]` → `- [x]`。
   - 失败：修实现（非改测试，除非测试本身错）；同一 task 连续 3 次修不好 → 停下报告。

4. **每组 task 后：回归 → 构建 → 逐组提交**（P0）
   - **回归**（防止新 task 悄悄打破旧 task，别只跑本组新测试）：跑 config 的 `<full-test>`（缺省回退 `<unit-test>`，即受影响模块/包的整体单测）。有失败先修再继续。
   - **构建**：执行 config 的 `<build>`（编译/类型检查整个工程），成功才继续。
   - **逐组提交**（green 后立即，杜绝"漏提交测试文件 / 半成品跨分支"）：`git add <本组涉及的目录（须同时覆盖实现文件与测试文件）>` → 按 conventional-commit 提交（`feat:`/`fix:`…）。命令按 config 的 `shell` 语法书写；提交前自查 `git status` 无遗漏测试文件。

5. **内环退出条件**
   - 全部 task `- [x]`，且 `<build>` 通过，且相关模块/包的 `<unit-test>` 全绿（+ 覆盖率门）。
   - 达成 → 提示进入 `/ls:itest`（外环集成测试）。

**自动 / 暂停策略（半自动）**
- 默认**自动逐 task 推进**，不逐个问用户。
- 仅在这些情况停下：task 语义不清、实现暴露 design 缺陷需回改 spec、错误/阻塞、连续无进展、涉及安全敏感改动（触发 `security.md` 检查）。

**Output（每轮）**
```
## 编码内环：<name>
本轮完成: [x] task A / [x] task B ...
进度: N/M
单测: <module/包> 绿 ✓ | 构建: 成功 ✓ | 覆盖率: <x% 或 n/a>
下一步: 剩余 K 个 task / 或 全部完成 → /ls:itest
```

**Guardrails**
- 测试先行；改实现不改测试（除非测试错）。
- 集成/端到端测试**不**在此跑（慢、可能需真模型/外部服务，归 `/ls:itest` 外环）。
- 每完成一个 task 立即勾选 tasks.md。
- **每组绿后立即提交**，`git add` 须覆盖实现与测试两侧（P0，防漏测试文件）。
- **组边界跑整模块回归**（`<full-test>`）而非只新测试，早暴露跨 task 回归（P0）。
- 触碰 auth/输入/文件/外部调用时按 `security.md` 自检。
- 构建/测试命令一律取自 `ls-pipeline.config.md`，不在命令正文里假设具体工具。
