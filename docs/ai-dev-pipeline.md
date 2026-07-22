# AI 循环开发流水线 `/ls:*` —— 使用指南

一条**半自动 AI 循环开发流水线**：把 openspec（spec 驱动）、项目构建/测试、通用规约串成标准流程，用 `.claude/commands/ls/` 下的 `/ls:*` slash 命令驱动。核心原则：**复用而非重造**——`/ls:*` 只补缺失的胶水，spec/编码/归档三段直接委托 `/opsx:propose`、`/opsx:apply`、`/opsx:archive`（openspec 技能）。

> 本流水线源自 pig-agent 项目并已抽象为**与技术栈无关**的模板：所有构建/测试命令集中在每个项目一份的 `ls-pipeline.config.md`，命令读配置而非硬编码工具。安装见本仓库 `README.md`。真实案例复盘见 `docs/examples/retro-permission-system.md`。

```
需求澄清 → 特性分支(<type>/YYYYMMDD-功能名) → spec 设计 → [编码⇄单测 内环] → 集成测试 外环 → openspec 归档
```

## 七个命令

| 命令 | 阶段 | 人工门 | 职责 |
|------|------|--------|------|
| `/ls:clarify` | 需求澄清 + 拆分 + 建分支 | ⏸ 人工 | 问清需求；**大需求拆成多个可独立上线的 spec（人工审拆分）**；每个 spec 拉 `<type>/YYYYMMDD-<name>` 分支（可并行） |
| `/ls:spec` | spec 设计 | ⏸ 人工审批 | 委托 `/opsx:propose` 生成 proposal/design/tasks + delta spec，`openspec validate --strict` |
| `/ls:code` | 编码⇄单测（**内环**） | 自动 | 逐 task TDD：测试→实现→跑 `unit-test`→勾选；组后跑 `build`（命令取自 config） |
| `/ls:itest` | 集成测试（**外环**） | 自动 | 跑 `integration-test`；失败回喂 `/ls:code`；连续 3 轮无进展升级人工 |
| `/ls:archive` | openspec 归档 | ⏸ 人工确认 | 委托 `/opsx:archive`：同步主 spec + 移到 `changes/archive/` |
| `/ls:status` | 进度汇报 | 只读 | 跨 澄清/设计/规格/任务 维度统计所有活跃 spec（多 spec 并行视图 + 卡点） |
| `/ls:dev` | 总控 | 半自动 | 端到端串联五阶段，尊重上述人工门 |

**多 spec 并行**：需求很大时，`/ls:clarify` 把它拆成多个**可独立上线**的 spec（拆分方案人工审），每个 spec 各自 `<type>/YYYYMMDD-<name>` 分支，可并行开发（不同会话/worktree）；`/ls:status` 汇总所有活跃 spec 的进度与卡点。

## 两层 Loop Engine

- **内环（`/ls:code`，快、离线）**：每个 task → 写测试(RED) → 实现(GREEN) → 跑 config 的 `unit-test` → 重构。退出：本 task 单测绿；全部 task `[x]` 且 config 的 `build` 通过。
- **外环（`/ls:itest`，慢、可能需真模型/外部服务）**：任务集 → 内环 → 集成测试(`integration-test`) → 失败回喂内环修复 → 重跑。退出：集成测试全绿。连续 3 轮无进展 → 升级人工（fail-safe，不空转）。
- 若 config `integration-test: none`（纯库/纯离线工具）→ 外环短路，内环绿即通过。

## 半自动人工门

- **自动**：编码内环、单测、集成测试、失败回环。
- **必停（人工门）**：① 需求澄清确认 ② spec 审批 ③ 归档确认。
- **异常停下**：歧义、阻塞、需回改 spec、安全敏感改动、连续 3 轮无进展。

## 约定

- **分支命名**：**`<type>/YYYYMMDD-<功能名>`**（`YYYYMMDD`=建分支当天日期，`功能名` kebab-case），例如 `feat/20260715-plugin-collection`。`type` 前缀：`feat` / `bug` / `docs` / `opt`。注意 `bug/` 分支的**提交信息**仍用 conventional-commit 的 `fix:`。
- **承重技术设 spike 卡点**：spec 若依赖未验证的承重假设（如框架语义、外部 API 行为），把 `tasks.md` 第 1 组设为 Spike，不过不进编码。
- **规约基座**：`.claude/rules/common/{ls-pipeline,development-workflow,testing,git-workflow,code-review,security,coding-style}.md`（流程硬约束 / TDD / ≥80% 覆盖 / conventional commit / 评审门 / 编码风格）。
- **工具链配置**：`ls-pipeline.config.md`（栈相关，命令的来源）。

## 快速上手

```
/ls:dev 给某工具加一行调试日志        # 总控，端到端半自动
# 或分阶段手动：
/ls:clarify <需求>  →  /ls:spec <name>  →  /ls:code <name>  →  /ls:itest <name>  →  /ls:archive <name>
```

命令定义在 `.claude/commands/ls/`；机制同 `/opsx:*`（子目录 = 命名空间前缀）。

## 附录：工具链踩坑（把结论记进你的 config）

流水线本身与栈无关，但每个栈都有构建/测试陷阱。**把它们写进 `ls-pipeline.config.md` 的「备注 / 踩坑」段**，让每次跑流水线的 agent 都读得到。几类常见坑（源自实战）：

- **多模块构建的依赖安装**：如 Maven `mvn -pl <m>` 必须带 `-am`，否则同级模块未装 → 假失败。类比：pnpm/poetry 的 workspace 依赖。
- **测试筛选器的空匹配**：显式指定某类测试时，上游模块"无匹配用例"可能中断——如 Maven 加 `-Dsurefire.failIfNoSpecifiedTests=false`。
- **shell 把 native stderr 染红**：PowerShell 5.1 会把 git/构建工具的正常 stderr 包成 `NativeCommandError`，**以退出码/测试报告行为准**，别被红字误导。
- **提交别漏测试文件**：逐组提交时 `git add` 要覆盖实现与测试两侧。
- **承重先 spike**：把最不确定的框架语义/外部 API 行为用一次真机小实验证掉，再铺开实现——比读文档猜快且确定。
