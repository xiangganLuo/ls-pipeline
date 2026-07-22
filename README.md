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

## 里面有什么（逐文件职责）

顶层结构：

```
ls-pipeline/
├── README.md            # 本文件：是什么 / 安装 / 用法 / 结构
├── LICENSE              # MIT 许可
├── install.ps1          # 安装器（Windows/PowerShell，UTF-8 BOM）
├── install.sh           # 安装器（macOS/Linux/bash，LF 行尾）
├── .gitattributes       # 强制 .sh=LF、.ps1=CRLF，避免跨平台行尾坏 shebang
├── .gitignore
├── assets/.claude/      # ① 客户端无关的“中性内容”——真正被装进你项目的资产
├── templates/           # ② 安装时 seed/写入的模板（配置 + 入口文件）
├── clients/             # ③ 客户端适配注册表
└── docs/                # ④ 指南 / 配置参考 / 样例 / 实战复盘
```

### ① `assets/.claude/` —— 被安装的资产（流水线本体）

> 用 Claude 的目录布局承载，但内容**与客户端无关**（其它客户端安装时会被转放到 `.ai/ls-pipeline/` bundle）。

**`commands/ls/` —— 7 个流水线命令（你平时用的 `/ls:*`）**

| 文件 | 命令 | 阶段 | 职责 |
|------|------|------|------|
| `clarify.md` | `/ls:clarify` | ① 需求澄清 ⏸人工 | 问清需求、把大需求拆成多个可独立上线的 spec（人工审拆分）、建 `<type>/YYYYMMDD-<name>` 分支 |
| `spec.md` | `/ls:spec` | ② spec 设计 ⏸人工 | 委托 `/opsx:propose` 生成 proposal/design/tasks + delta spec，`openspec validate --strict`，承重点设 spike 卡点 |
| `code.md` | `/ls:code` | ③ 编码⇄单测 **内环** | 逐 task TDD（RED→GREEN→重构）→ 跑 config 的 `unit-test` → 勾选；组后跑 `build`。快、离线 |
| `itest.md` | `/ls:itest` | ④ 集成测试 **外环** | 跑 config 的 `integration-test`；失败回喂 `/ls:code`；连续 3 轮无进展升级人工；`none` 则跳过 |
| `archive.md` | `/ls:archive` | ⑤ 归档 ⏸人工 | 委托 `/opsx:archive` 同步 delta→主 spec + 移到 `changes/archive/` |
| `status.md` | `/ls:status` | 只读 | 跨 澄清/设计/规格/任务 维度统计所有活跃 spec（多 spec 并行视图 + 卡点） |
| `dev.md` | `/ls:dev` | 总控 | 端到端串联五阶段，尊重三道人工门（半自动） |

**`commands/opsx/` —— 5 个 openspec 命令（被 `/ls:*` 委托的“干活层”，直接驱动 openspec CLI）**

| 文件 | 命令 | 职责 |
|------|------|------|
| `propose.md` | `/opsx:propose` | 新建 change 并一次性生成 proposal/design/tasks + delta spec |
| `apply.md` | `/opsx:apply` | 按 tasks 逐条实现并勾选 |
| `archive.md` | `/opsx:archive` | 归档完成的 change（完成度检查 + 同步 spec + 移动目录） |
| `sync.md` | `/opsx:sync` | 把 delta spec 智能合并进主 spec（增量 ADD/MODIFY/REMOVE/RENAME） |
| `explore.md` | `/opsx:explore` | 探索/思考模式（只想不写代码，可产 openspec artifact） |

**`skills/openspec-*/SKILL.md` —— 5 个 openspec 技能**：`propose`/`apply-change`/`archive-change`/`sync-specs`/`explore`。是 `/opsx:*` 背后的底层机制（Claude Code 通过 Skill 调用；其它客户端里 `opsx` 命令本身已自包含，技能作为参考随 bundle 附带）。

**`rules/common/` —— 7 条规约（流水线的“法律”）**

| 文件 | 职责 |
|------|------|
| `ls-pipeline.md` | **核心硬约束**：五阶段、三人工门、多 spec 拆分、9 条 MUST（唯一必须常驻的规约） |
| `development-workflow.md` | 阶段内做法：研究复用优先、TDD、代码评审 |
| `testing.md` | 测试要求：≥80% 覆盖、TDD 流程、AAA 结构（命令读 config 的 `unit-test`） |
| `git-workflow.md` | conventional-commit 提交信息 + PR 规范 |
| `code-review.md` | 评审触发时机、清单、严重级别 |
| `security.md` | 提交前安全自检清单、密钥管理 |
| `coding-style.md` | 不可变、KISS/DRY/YAGNI、小文件小函数 |

### ② `templates/` —— 安装时写入你项目的模板

| 文件 | 装到哪 | 职责 |
|------|--------|------|
| `ls-pipeline.config.md` | 你项目**根目录** | ★ **栈相关的唯一落点**：填 `build`/`unit-test`/`integration-test`/`coverage`/`shell` 等真实命令。命令读它、不硬编码工具 |
| `AGENTS.md` | 你项目根（非 claude 客户端） | 跨工具入口标准（codex/grok/opencode/trae/qoder 都读）：内嵌流水线规则 + 指引“读命令文件并执行” |
| `CLAUDE.md` | 你项目根（claude） | Claude 入口指针：指向 `.claude/rules` 与 `/ls:*` 命令 |

> 入口文件用 `<!-- ls-pipeline:begin/end -->` 标记块**幂等写入**，重装只更新标记块，保留你 AGENTS.md/CLAUDE.md 的其余内容。

### ③ `clients/registry.md` —— 客户端注册表

单一事实来源：每个客户端（claude/codex/opencode/trae/qoder/grok）装到哪些目录、用哪种 profile、验证状态、以及**如何新增一个客户端**。安装器的映射表镜像自它。

### ④ `docs/` —— 文档

| 文件 | 职责 |
|------|------|
| `ai-dev-pipeline.md` | 通用化使用指南 + 工具链踩坑附录 |
| `config-reference.md` | `ls-pipeline.config.md` 每个字段的详解 + `none` 的效果 |
| `examples/config.java-maven.md` | 填好的样例：Java / Maven 多模块（源自 pig-agent） |
| `examples/config.node-ts.md` | 填好的样例：Node / TypeScript |
| `examples/config.python.md` | 填好的样例：Python |
| `examples/retro-permission-system.md` | 真实案例复盘：用本流水线做“工具权限体系”的完整走位 + 踩坑 |

### 装到你项目后长什么样

- **claude（原生）**：
  ```
  你的项目/
  ├── CLAUDE.md                 # 入口指针（标记块）
  ├── ls-pipeline.config.md     # 你要填的工具链配置
  └── .claude/
      ├── commands/ls/*.md      # /ls:* 命令
      ├── commands/opsx/*.md    # /opsx:* 命令
      ├── skills/openspec-*/    # openspec 技能
      └── rules/common/*.md     # 7 条规约
  ```
- **其它客户端（agents-md 通用）**：
  ```
  你的项目/
  ├── AGENTS.md                 # 跨工具入口（标记块）
  ├── ls-pipeline.config.md     # 你要填的工具链配置
  ├── .ai/ls-pipeline/          # 中性 bundle：commands / rules / skills / docs
  └── （opencode 额外）.opencode/command/ls-*.md   （trae 额外）.trae/rules/*.md
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
