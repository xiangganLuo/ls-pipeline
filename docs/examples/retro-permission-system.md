# 实战复盘：用 `/ls:*` 做工具权限体系（真实案例）

> 这是流水线在 **pig-agent** 项目上的首轮实战——用它做出的第一个真实特性（对标 Claude Code 的工具权限体系），既交付了功能，也**验证了流水线本身**。保留在此作为一次完整走位的参考（含真实踩坑），而非通用指南。栈相关细节（Maven/anthropic）请自行映射到你的项目。

## 逐阶段走位

| 阶段 | 结果 |
|------|------|
| **需求澄清** | 定下：四模式全量对标、`plan`=真只读 agent、仅全局配置、非交互渠道兜底 |
| **建分支** | `feat/permission-system`（从 origin/main fresh 拉出） |
| **spec** | `/opsx:propose` → proposal/design/tasks + `tool-permissions` delta spec，`validate --strict` 通过 |
| **Spike（卡点）** | 承重问题：hook 能否否决工具调用？用一次真机小实验（真实模型）实证了可行策略——hook 在工具执行前把待执行调用改写为只读 deny 哨兵 → 真实工具未执行、模型收到拒绝后继续。承重解除 |
| **内环逐组** | Task2 config → Task3 core（分类器/策略/解析/hook）→ Task4 cli（`/permission` 命令 + 接线）。每组 TDD + 构建验证 + commit |
| **外环 itest** | 集成测试（真实 hook + 真实模型）：**plan 否决可变工具 / bypass 放行** |
| **设计枢轴（Task5）** | 发现 REPL 与渠道共享同一 agent → 给渠道单独 agent，渠道用受限模式且 ASK fail-closed |
| **文档 + 全量验证（Task6）** | 更新架构文档 + README 权限章节；全量测试无回归 |
| **归档** | 人工确认门（本轮用户选择先做完后续子任务再归档） |

## 关键决策

- **架构 A（Hook 统一门）** 胜出：单点拦截，**内置 + 外部（MCP）工具统一覆盖**。否决 B（逐工具装饰器，覆盖不了动态工具）、C（回合级，做不了逐工具审批）。
- **改写调用指向 deny 哨兵**（spike 定），优于中断式 `error`（不优雅）。
- **判定核心抽成纯函数**：分类/策略/解析与框架解耦，confirmer/writer 注入 → 无需真实 agent 即可单测。
- **渠道专用 agent**：解决共享 agent 无法区分回合来源的约束；副作用（渠道对话与 REPL 分离）反而更合理。
- **组合而非重复**：既有安全门保持不变，权限层不重复弹窗。

## 教训 / 踩坑（沉淀给下一轮）

- **多模块构建要带依赖安装参数**：如 `mvn -pl <m>` 必须带 `-am`，否则同级模块未装 → 假失败（本轮中招一次）。
- **测试筛选器的空匹配**：显式 `-Dtest=X` 命中不到的上游模块，加 `-Dsurefire.failIfNoSpecifiedTests=false`，否则报错中断。
- **PowerShell 把 native stderr 染红**：git/构建工具的正常 stderr 会被包成 `NativeCommandError`，**以 `Tests run:` / `BUILD SUCCESS` 行和退出码为准**。
- **`git add` 要覆盖测试目录**：本轮某组只 add 了实现，漏了测试文件（编译通过但未入库），切分支时才暴露 → 补提交。逐组提交时显式列全实现+测试。
- **分支职责单一**：工具链改动与功能改动分开、各自建 PR；跨分支重复归档会在合入 main 时冲突。
- **承重先 spike**：把最不确定的框架语义用一次真机小实验证掉，再放心铺开——比读源码/文档猜快且确定。

## 数字

- 7 个 commit，6 组任务；单测 config + core + cli 全绿；集成测试覆盖 spike + plan 否决 / bypass 放行。
- openspec change：7 Requirement / 若干 Scenario，`validate --strict` 通过。

> 这几条踩坑已泛化进 `docs/ai-dev-pipeline.md` 的「工具链踩坑」附录，并建议写入你项目的 `ls-pipeline.config.md` 备注段。
