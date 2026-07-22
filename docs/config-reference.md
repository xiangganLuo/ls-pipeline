# 配置字段参考（`ls-pipeline.config.md`）

流水线与技术栈解耦的关键：所有构建/测试命令集中在这一份 per-project 配置里，`/ls:*` 命令读取字段而非硬编码工具。下面逐字段说明。

| 字段 | 谁在用 | 说明 | 填 `none` 的效果 |
|------|--------|------|------------------|
| `language / stack` | 全部 | 主语言/栈，帮助 agent 选测试框架、命名约定 | — |
| `shell` | code / itest / clarify | `powershell` 或 `bash`，决定命令语法（引号、`&&` vs `;`） | — |
| `module-layout` | code / clarify | 单包还是多模块 monorepo，以及"如何指定单个模块/包"的写法 | — |
| `build` | code | 编译/类型检查整个工程的命令；每组 task 后跑 | — |
| `unit-test`（整体） | code | 跑一个模块/包全部单测 | — |
| `single-test`（模板） | code | 只跑一个测试文件/类，加速 TDD 内环 | 缺省则退回整体 `unit-test` |
| `full-test` | code | **组边界回归**：每组 task 完成后跑的整模块/包单测（P0，防跨 task 回归） | 缺省回退 `unit-test` |
| `coverage` | code / testing 规约 | 覆盖率工具 + 阈值 | 降级为"单测全绿 + 关键分支有测试"硬门，覆盖率作建议 |
| `integration-test` | itest / dev | 跑集成/E2E 的命令 + 如何筛选这些用例 | **itest 阶段整段跳过**，内环绿即视为通过，直接 `/ls:archive` |
| `integration-prereqs` | itest | 集成测试前置（API key / 在线服务 / 凭据） | itest 不做前置检查 |
| `branch-prefixes` | clarify | 分支前缀集合 | 默认 `feat/bug/docs/opt` |
| `openspec` | spec / archive / status | 项目是否已装 openspec 脚手架 | `no` → 先装 CLI 并 `openspec init` |

## 设计原则

- **命令正文永远不假设具体工具**。看到 `/ls:code` 里写 `<unit-test>`，就是"去 config 取 `unit-test` 字段的命令来跑"。
- **`none` 是一等公民**。没有集成测试层的项目（纯库、纯离线工具）填 `integration-test: none`，外环自动短路，不会卡在"找不到 *IT"。
- **shell 语法差异**由 `shell` 字段兜住：PowerShell 下 `-D`/含特殊字符的参数要加引号、链式用 `;`；bash 用 `&&`。
- **踩坑备注**写进 config 末尾的「备注 / 踩坑」段，让每次跑流水线的 agent 都能读到项目特有陷阱（如 Maven 的 `-am`、surefire 的 `failIfNoSpecifiedTests`、PowerShell stderr 染红）。

## 与规约的关系

- `rules/common/ls-pipeline.md` 是流程硬约束（阶段/人工门/拆分），**与栈无关**。
- 本配置是**栈相关**的落点。两者配合：规约说"跑单测"，配置说"用这条命令跑单测"。
