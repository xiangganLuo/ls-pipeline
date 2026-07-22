# ls-pipeline

一条**可移植、多客户端**的半自动 AI 循环开发流水线 `/ls:*`，可装进任意项目、适配主流 AI 编码客户端（Claude Code / Codex / Grok / opencode / Trae / Qoder …）。它把 **openspec（spec 驱动）+ 项目构建/测试 + 通用规约**串成标准流程：

```
需求澄清 → 特性分支 → spec 设计 → [编码⇄单测 内环] → 集成测试 外环 → openspec 归档
                                     └───────── 两层 loop engine ─────────┘
```

三道**人工门**（需求确认 / spec 审批 / 归档确认）把关，其余（编码内环、单测、集成测试、失败回环）自动推进。源自 pig-agent，已抽象为**两层解耦**：

- **流程规约**（`rules/common/ls-pipeline.md`）——与技术栈、与客户端都无关。
- **工具链配置**（项目根 `ls-pipeline.config.md`）——栈相关的唯一落点；命令读配置而非硬编码 `mvn`/`npm`/`pytest`。
- **客户端适配**（`clients/registry.md` + 安装器）——同一份中性 Markdown，装到各客户端期望的位置。

## 里面有什么

```
assets/.claude/          # 客户端无关的中性内容（用 Claude 布局承载）
├── commands/ls/         # 7 个流水线命令：clarify spec code itest archive status dev
├── commands/opsx/       # 5 个 openspec 命令（spec/编码/归档委托层）
├── skills/openspec-*/    # 5 个 openspec 技能
└── rules/common/        # 7 条规约：ls-pipeline / development-workflow / testing /
                         #           git-workflow / code-review / security / coding-style
templates/
├── ls-pipeline.config.md   # ★ per-project 工具链配置模板
├── AGENTS.md               # 跨工具入口（codex/grok/opencode/trae/qoder…）
└── CLAUDE.md               # Claude 入口指针
clients/registry.md      # 客户端注册表（映射 + 验证状态 + 如何扩展）
docs/                    # 指南 + 配置参考 + 3 个样例配置 + 实战复盘
install.ps1 / install.sh # 一键安装（选客户端）
```

## 支持的客户端

| 客户端 | 集成方式 | 斜杠命令 |
|--------|----------|----------|
| **claude** (Claude Code) | 原生 `.claude/{commands,skills,rules}` + `CLAUDE.md` | 原生 `/ls:clarify` … （已验证） |
| **opencode** | `AGENTS.md` + bundle + 原生 `.opencode/command/` | 原生 `/ls-clarify` …（扁平化） |
| **trae** (Trae IDE) | `AGENTS.md` + bundle + 规则装进 `.trae/rules/` | 走 AGENTS.md 指引 |
| **codex** (OpenAI Codex) | `AGENTS.md` + bundle | 走 AGENTS.md 指引 |
| **grok** (xAI Grok) | `AGENTS.md` + bundle（grok 亦读 SKILL.md） | 走 AGENTS.md 指引 |
| **qoder** (Qoder) | `AGENTS.md` + bundle | 走 AGENTS.md 指引 |

**两种安装 profile**：`claude` 走原生目录（斜杠命令原生可用）；其余走 **`AGENTS.md` 通用 profile**——写项目根 `AGENTS.md`（各家都读的跨工具标准，内嵌流水线规则 + 指引"读 `.ai/ls-pipeline/commands/*.md` 并执行"）+ 中性 bundle。功能等价，只是命令由 AGENTS.md 驱动而非一定是原生斜杠命令。详见 [`clients/registry.md`](clients/registry.md)（含各家约定出处与诚实边界）。

> 诚实说明：仅 `claude` 在源项目实跑验证；`opencode`/`trae` 的原生目录依官方文档但未端到端跑测；`codex`/`grok`/`qoder` 以 AGENTS.md 通用 profile 落地（这几家都原生读 `AGENTS.md`，流水线可用）。后续可按 `clients/registry.md` 的「如何扩展」补装原生目录。

## 前置

- 目标 **AI 编码客户端**（上表之一）。
- **openspec CLI**：`npm i -g openspec`，并在目标项目根 `openspec init`。
- 目标项目是一个 **git 仓库**。

## 安装

**脚本（推荐）** —— 安装时选客户端：

Windows / PowerShell：
```powershell
.\install.ps1 -Target C:\path\to\your-project -Client claude   # 指定客户端
.\install.ps1 -Target C:\path\to\your-project                  # 交互选择
.\install.ps1 -Target C:\path\to\your-project -Client opencode -Force
```

macOS / Linux / bash：
```bash
./install.sh /path/to/your-project --client claude   # 指定客户端
./install.sh /path/to/your-project                   # 交互选择
./install.sh /path/to/your-project --client trae --force
```

脚本会：按所选客户端把资产放到对应位置、幂等写入 `AGENTS.md`/`CLAUDE.md` 的 `ls-pipeline` 标记块（保留你其余内容）、seed 项目根 `ls-pipeline.config.md`（不覆盖已填）、检测 openspec、打印后续步骤。

**手动**：见 `clients/registry.md` 的映射表，把 `assets/.claude/` 内容与 `templates/` 入口按目标客户端约定放好即可。

## 用之前：填配置

编辑 `<你的项目>/ls-pipeline.config.md`（项目根），把 `build` / `unit-test` / `integration-test` / `coverage` / `shell` 等字段填成真实命令。字段含义见 [`docs/config-reference.md`](docs/config-reference.md)，样例见 [`docs/examples/`](docs/examples/)（Java-Maven / Node-TS / Python）。没有独立集成测试层就把 `integration-test` 填 `none`，外环自动短路。

## 开跑

```
/ls:dev <一句需求>       # 总控，端到端半自动（尊重三道人工门）
/ls:clarify <需求> → /ls:spec <name> → /ls:code <name> → /ls:itest <name> → /ls:archive <name>
/ls:status               # 随时看所有活跃 spec 的进度（只读）
```

- **claude**：直接输入 `/ls:...`。
- **opencode**：原生命令为 `/ls-...`（扁平化），或让 AI 按 `AGENTS.md` 执行 `/ls:...`。
- **codex/grok/trae/qoder**：让 AI 读 `AGENTS.md` 并执行——说「/ls:dev <需求>」或「按 ls-pipeline 开始做 <需求>」。

完整用法见 [`docs/ai-dev-pipeline.md`](docs/ai-dev-pipeline.md)；真实案例复盘见 [`docs/examples/retro-permission-system.md`](docs/examples/retro-permission-system.md)。

## 设计要点

- **复用而非重造**：`/ls:*` 只补胶水，spec/编码/归档委托 `/opsx:*` + openspec。
- **三层解耦**：流程规约（栈/客户端无关）× 工具链配置（栈相关）× 客户端适配（注册表）。
- **两层 loop + 三人工门**：内环快（离线单测），外环慢（集成/真模型），失败回环至绿，连续 3 轮无进展升级人工。
- **可扩展**：新增客户端 = `clients/registry.md` 加一行 + 安装器加一个映射分支。

## 许可

MIT
