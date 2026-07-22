<!-- ls-pipeline:begin (由 ls-pipeline 安装器维护；勿手改本区块内标记) -->
# AI 开发流水线（ls-pipeline）

本项目采用**半自动 AI 循环开发流水线**。任何"写代码实现需求/特性/修复"的任务，**MUST** 走此流程，不得跳阶段、不得越人工门、不得替用户拍板。

> 本区块是跨工具入口（AGENTS.md 标准，Codex / opencode / Trae / Qoder / Grok 等均读取）。完整规约与命令定义在 `.ai/ls-pipeline/`；工具链命令在项目根的 `ls-pipeline.config.md`。

## 五阶段与三道人工门

```
⏸ 需求澄清   → clarify   （问清需求 + 拆分多 spec + 建 <type>/YYYYMMDD-<name> 分支）
⏸ spec 设计  → spec      （openspec propose 生成 proposal/design/tasks + delta spec，validate --strict）
┌─ 外环（自动，反复至绿）──────────────────────┐
│  编码⇄单测 → code   （内环：逐 task TDD，config 的 build/unit-test 绿）│
│  集成测试  → itest  （集成/E2E；失败回喂 code；连续 3 轮无进展升级人工）│
└──────────────────────────────────────────────┘
⏸ 归档       → archive   （openspec 同步主 spec + 移 changes/archive/）
```

**三道人工门（MUST 真正停下等确认）**：① 需求澄清确认　② spec 审批　③ 归档确认。

## 如何执行命令

用户输入 `/ls:clarify`、`/ls:spec`、`/ls:code`、`/ls:itest`、`/ls:archive`、`/ls:status`、`/ls:dev`（或口头请求"开始做某特性"）时：
**读取 `.ai/ls-pipeline/commands/ls/<命令名>.md` 并严格按其步骤执行**（`/ls:dev` 是总控，串联五阶段）。这些命令会委托 `.ai/ls-pipeline/commands/opsx/*.md`（openspec spec/编码/归档流程）。

> 若你的工具原生支持斜杠命令目录（如 Claude Code、opencode），安装器可能已把命令装进原生目录，可直接 `/...` 调用；否则按上面的"读文件并执行"方式驱动，效果一致。

## 硬性规则（MUST，摘自 `.ai/ls-pipeline/rules/common/ls-pipeline.md`）

1. 从 clarify 起步，不得跳到 spec（澄清阶段负责问清 + 多 spec 拆分）。
2. 大需求拆成多个**可独立上线**的 spec，拆分方案**须人工审**。
3. 每个 spec 独立走完整流水线；后一个 spec 在其依赖的前一个归档后才细化 tasks。
4. 依赖关系显式标注（顺序 vs 并行），不得误标。
5. 评审/待优化发现项**显式落进 spec**（design.md 落实追踪表），不留无归属 backlog。
6. 每道人工门必须真正停下；歧义/阻塞/需回改 spec/安全敏感/连续 3 轮无进展 → 升级人工。
7. 只动三类东西：spec artifacts + 产品代码 + tasks 勾选。
8. 复用既有命令与 openspec，不另起炉灶。
9. **构建/测试命令一律取自项目根的 `ls-pipeline.config.md`**，不假设具体工具（mvn/npm/pytest…）。

## 关键约定

- 分支：`<type>/YYYYMMDD-<功能名>`，`type` ∈ {feat, bug, docs, opt}；`bug/` 分支提交信息仍用 `fix:`。
- 承重技术设 spike 卡点：不过不进编码。
- 规约基座：`.ai/ls-pipeline/rules/common/`（ls-pipeline / development-workflow / testing / git-workflow / code-review / security / coding-style）。
- 前置：`openspec` CLI（`npm i -g openspec` + 项目根 `openspec init`）。

完整指南见 `.ai/ls-pipeline/docs/ai-dev-pipeline.md`（若安装器复制了 docs）或本模板仓库。
<!-- ls-pipeline:end -->
