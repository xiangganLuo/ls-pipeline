# 编码客户端注册表（clients registry）

ls-pipeline 与具体 AI 编码客户端解耦。**规约/命令/技能是客户端无关的 Markdown**（`assets/.claude/` 下的中性内容），安装器按下表把它们放到各客户端期望的位置。安装时用 `-Client` 选择（缺省交互选择）。

> **这是单一事实来源。** 新增一个客户端 = 在此表加一行 + 在 `install.ps1`/`install.sh` 的客户端映射表加一个分支（见文末「如何扩展」）。

## 两种安装 profile

- **native（原生）**：装进客户端专属目录，`/...` 斜杠命令原生可用。目前仅 Claude Code 全原生。
- **agents-md（通用）**：写项目根 `AGENTS.md`（跨工具事实标准，各家都读）+ 中性 bundle `.ai/ls-pipeline/{commands,rules,skills}`。`/ls:*` 由 AGENTS.md 指引"读命令文件并执行"驱动，**功能等价**，只是不一定是原生斜杠命令。部分客户端另有原生目录，安装器会额外补装（bonus）。

所有 profile 都把工具链配置放**项目根 `ls-pipeline.config.md`**。

## 客户端映射

| 客户端 | profile | 入口文件 | 原生命令目录（bonus） | 原生规则目录（bonus） | 技能 | 验证状态 |
|--------|---------|----------|----------------------|----------------------|------|----------|
| `claude` (Claude Code) | native | `CLAUDE.md` 指针 | `.claude/commands/{ls,opsx}`（保留子目录=命名空间） | `.claude/rules/common` | `.claude/skills/openspec-*` | 已验证（源项目在用） |
| `opencode` | agents-md | `AGENTS.md` | `.opencode/command/`（扁平化 `ls-*.md`/`opsx-*.md`） | — | — | 官方文档一致，未跑测 |
| `trae` (Trae IDE) | agents-md | `AGENTS.md` | —（Trae 无命令目录，走 AGENTS.md 指引） | `.trae/rules/`（额外复制规约） | — | 官方文档一致，未跑测 |
| `codex` (OpenAI Codex) | agents-md | `AGENTS.md` | —（prompts 在用户主目录且已弃用，改用 skills；本器走 AGENTS.md 驱动） | — | 可选（Codex skills，未自动装） | 尽力而为 |
| `grok` (xAI Grok / grok-cli) | agents-md | `AGENTS.md` | —（走 AGENTS.md 指引；grok 也读 SKILL.md） | — | 可选（bundle 内 skills 可手动接入 grok skills 目录） | 尽力而为 |
| `qoder` (Qoder) | agents-md | `AGENTS.md` | —（IDE 走 AGENTS.md；Qoder CLI 命令目录未确认） | — | — | 尽力而为 |

**说明 / 诚实边界**
- `claude` 是唯一已在源项目（pig-agent）实跑验证的全原生集成。
- `opencode` 的 `.opencode/command/` 与 `trae` 的 `.trae/rules/` 依官方文档，路径正确但本仓库未做端到端跑测。
- `codex` / `grok` / `qoder` 均以 **AGENTS.md 通用 profile** 落地——这几家都原生读取项目根 `AGENTS.md`，因此流水线可用；它们各自的"原生斜杠命令目录"要么不存在、要么已弃用、要么未公开确认，故本器不臆造路径，留作后续按需补装。
- `grok` 与 `codex` 支持 `SKILL.md` 子目录技能；bundle 里带了 `skills/openspec-*`，如需接成原生技能，把它们拷进对应工具的项目级 skills 目录即可（路径以该工具当时文档为准）。

## 各客户端约定出处（供后续核对/更新）

- Claude Code：`.claude/commands`（子目录=命名空间）、`.claude/skills/*/SKILL.md`、`CLAUDE.md`/`.claude/rules`。
- OpenAI Codex：`AGENTS.md`（根，向下合并，32KiB 上限）；自定义 prompts 在 `~/.codex/prompts`（用户级，已弃用，被 skills 取代）。
- opencode：命令 `.opencode/command/<name>.md`（也支持 `opencode.json` 的 `command`）；规则 `AGENTS.md`（优先于 CLAUDE.md）+ `opencode.json` 的 `instructions`。
- Trae IDE：规则 `.trae/rules/*.md`（`#rulename` 引用）；兼容 `AGENTS.md` + `CLAUDE.md`。
- Qoder：原生读 `AGENTS.md`（IDE 内另有 rules 设置）；Qoder CLI 支持 `.md` 自定义命令 + subagents。
- Grok（grok-cli / grok-build）：层级 `AGENTS.md`（Codex 风格合并）+ `SKILL.md` 技能；兼容 `CLAUDE.md`。

## 如何扩展（新增一个客户端）

1. 在上表加一行：入口文件、原生命令/规则目录（没有就留 `—` 走 agents-md）、技能支持、验证状态。
2. 在 `install.ps1` 的 `$Clients` 哈希表 与 `install.sh` 的 `client_map` case 里，加一个同名条目，填 `profile` 与可选的 `nativeCommandsDir` / `nativeRulesDir`。
3. agents-md profile 的客户端**通常无需改脚本**（默认路径即通用 bundle + AGENTS.md）；只有需要"原生 bonus 目录"时才加分支。
4. 更新 `README.md` 的客户端清单。
