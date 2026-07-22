---
name: "LS: Itest"
description: 集成测试外环——跑集成/端到端测试，失败回喂修复重跑（AI 开发流水线第 4 步 · loop engine 外环）
category: Workflow
tags: [workflow, ls-pipeline, integration-test, loop-engine]
---

集成测试**外环**（loop engine 外环）。`/ls:*` 流水线第 4 步（**自动阶段**）。跑集成/端到端测试（可能需真实模型或外部服务），失败则回喂 `/ls:code` 修复并重跑。

> **集成测试命令与前置从 `ls-pipeline.config.md` 读取**：`integration-test`（跑集成/E2E 的命令 + 如何筛选/标记这些测试，或 `none`）、`integration-prereqs`（前置条件：API key / 在线服务 / 凭据文件，或 `none`）、`shell`。下文用 `<itest>` 代指该命令。**若 `integration-test: none`** → 本变更无独立集成测试层，跳过本步、直接提示 `/ls:archive`。

**前置**：内环已收敛（`/ls:code` 单测+构建绿）。**Input**: 变更名（缺省从对话/分支推断）。

**Steps**

1. **确认有集成测试**
   - 该变更是否涉及需真实模型/外部服务验证的端到端行为（agent 流、工具执行、渠道、真实 API 等）？
   - config 的 `integration-test` 非 `none` 且本变更确有对应用例 → 跑；否则（纯离线变更 / `integration-test: none`）→ 跳过并说明，直接提示 `/ls:archive`。
   - 按 config 的 `integration-prereqs` 确认前置就绪（相关 API key/凭据/服务已配）；未就绪 → 停下告知，不空跑。

2. **跑集成测试**（命令取自 config 的 `<itest>`，按 `shell` 语法书写；`-D`/特殊字符参数在 PowerShell 下加引号）
   - 用日志过滤看结果（成功/失败/用例数）。
   - **注意 shell 干扰**：PowerShell 5.1 会把 native 命令（git/构建工具）的 stderr 包成 `NativeCommandError` 染红，**非真失败**——以测试报告的「用例数/BUILD 结果行」与进程退出码为准，别被红字误导。

3. **外环：失败回喂修复**（这是 loop engine 的外环）
   - 失败 → 归纳失败点（哪个用例、断言、栈）→ 回到 `/ls:code` 逻辑修实现/测试 → 重跑第 2 步。
   - **连续 3 轮无进展**（同类失败反复）→ 停下升级人工，报告已试方案（不空转烧 token）。

4. **外环退出**
   - 所有集成测试绿 → 提示 `/ls:archive`。

**Output**
```
## 集成测试外环：<name>
运行: <itest>
结果: <用例数 X, 失败 0, 错误 0> | BUILD/RUN 成功 ✓
（若失败）失败点: <用例/断言> → 回喂修复第 N 轮
全绿 → 运行 `/ls:archive <name>` 归档。
```

**Guardrails**
- 集成测试可能跑真模型/外部服务、耗资源，仅在内环绿后跑。
- 失败先修**产品代码**，别改测试掩盖问题（除非测试本身错）。
- 连续 3 轮无进展必须升级人工，禁止无限重跑。
- 不动 openspec 归档（那是 `/ls:archive`）。
- 集成测试命令一律取自 `ls-pipeline.config.md`，不在命令正文里假设具体工具。
