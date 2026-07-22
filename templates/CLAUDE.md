<!-- ls-pipeline:begin (由 ls-pipeline 安装器维护；勿手改本区块内标记) -->
# AI 开发流水线（ls-pipeline）

本项目采用**半自动 AI 循环开发流水线** `/ls:*`。任何"写代码实现需求/特性/修复"的任务，**MUST** 走此流程——见 `.claude/rules/common/ls-pipeline.md`（澄清→spec→[code⇄itest]→归档，三道人工门不得越过）。

- 命令：`/ls:clarify` `/ls:spec` `/ls:code` `/ls:itest` `/ls:archive` `/ls:status` `/ls:dev`（定义在 `.claude/commands/ls/`，委托 `.claude/commands/opsx/*` + `openspec-*` 技能）。
- 工具链命令：项目根的 `ls-pipeline.config.md`（`build`/`unit-test`/`integration-test`/`coverage`/`shell`…）。命令读配置，不硬编码工具。
- 规约基座：`.claude/rules/common/`（ls-pipeline / development-workflow / testing / git-workflow / code-review / security / coding-style）。
- 前置：`openspec` CLI（`npm i -g openspec` + 项目根 `openspec init`）。

完整指南见 ls-pipeline 模板仓库的 `docs/ai-dev-pipeline.md`。
<!-- ls-pipeline:end -->
