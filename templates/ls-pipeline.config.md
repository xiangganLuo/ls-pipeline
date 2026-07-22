# ls-pipeline 项目配置

> 这是 `/ls:*` 流水线的**唯一工具链配置**。`/ls:code`、`/ls:itest` 等命令从这里读取构建/测试命令，不硬编码任何工具。
> 安装后请把每个 `<...>` 占位符替换成你项目的真实值；填不准的先留占位并在首次 `/ls:code` 前补齐。
> 字段含义见 `docs/config-reference.md`（本模板仓库内），可参考 `docs/examples/config.*.md` 的填好样例。

## 基本

- **language / stack**: `<例如 Java / Maven；TypeScript / Node；Python / Poetry>`
- **shell**: `<powershell | bash>`
- **module-layout**: `<单包 | 多模块 monorepo；以及“如何指定单个模块/包”的写法，例如 mvn -pl <module> -am / npm -w <pkg> / 无>`

## 构建（编译 / 类型检查）

- **build**: `<整个工程的编译或类型检查命令，例如：mvn -pl <cli-module> -am compile / npm run build / tsc --noEmit / cargo build>`

## 单元测试（`/ls:code` 内环）

- **unit-test（整体）**: `<跑一个模块/包全部单测的命令，例如：mvn -pl <module> -am test / npm test / pytest>`
- **single-test（单文件/单类模板）**: `<只跑一个测试文件/类的命令模板，例如：mvn -pl <module> -am test "-Dtest=<Class>" / npx vitest run <file> / pytest <path>::<Test>>`
- **full-test（组边界回归，可选）**: `<每组 task 完成后跑的回归命令，通常=受影响模块/包的整体单测；缺省回退 unit-test。例如：mvn -pl <module> -am test / pnpm test / pytest>`

## 覆盖率

- **coverage**: `<工具 + 阈值，例如：jacoco / ≥80%；nyc / ≥80%；coverage.py / ≥80%；或 none>`

## 集成 / 端到端测试（`/ls:itest` 外环）

- **integration-test**: `<跑集成/E2E 的命令 + 如何筛选这些用例；例如：mvn -pl <cli-module> -am test "-Dtest=*IT" "-Dsurefire.failIfNoSpecifiedTests=false" / npm run test:e2e / pytest -m integration；若本项目没有独立集成层则填 none>`
- **integration-prereqs**: `<跑集成测试的前置：API key / 在线服务 / 凭据文件，例如：ANTHROPIC_API_KEY 环境变量、~/.myapp/config.json；无则填 none>`

## 约定

- **branch-prefixes**: `feat / bug / docs / opt`（可改；`bug/` 分支提交信息仍用 `fix:`）
- **openspec**: `<yes | no>`（流水线的 spec/归档层依赖 openspec CLI；no 时需先 `npm i -g openspec` 并在项目根 `openspec init`）

## 备注 / 踩坑（可选）

> 记录本项目特有的构建/测试陷阱，避免每次踩。例如：
> - `<例如：mvn -pl <m> 必须带 -am，否则同级模块未安装报假 BUILD FAILURE>`
> - `<例如：PowerShell 5.1 会把 native 命令 stderr 染红，以退出码/测试报告为准>`
