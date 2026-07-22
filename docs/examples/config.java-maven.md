# 样例配置：Java / Maven 多模块（源自 pig-agent）

> 复制到项目的 `ls-pipeline.config.md` 后按需微调（模块名、CLI 模块名）。

## 基本

- **language / stack**: Java 17 / Maven（多模块 monorepo）
- **shell**: powershell
- **module-layout**: 多模块 monorepo；指定单模块用 `mvn -pl <module> -am`（`-am` 必须带，否则同级依赖模块未安装会假失败）

## 构建（编译 / 类型检查）

- **build**: `mvn -pl <cli-module> -am compile`（用聚合下游最广的 CLI 模块带 `-am` 编译全工程）

## 单元测试

- **unit-test（整体）**: `mvn -pl <module> -am test`
- **single-test（单类模板）**: `mvn -pl <module> -am test "-Dtest=<TestClass>"`（PowerShell 下 `-D` 参数加引号）

## 覆盖率

- **coverage**: jacoco / ≥80%（`mvn verify` 触发 per-module 覆盖率门）

## 集成测试

- **integration-test**: `mvn -pl <cli-module> -am test "-Dtest=*IT" "-Dsurefire.failIfNoSpecifiedTests=false"`（`*IT` 默认被 surefire 排除，需显式指定；`failIfNoSpecifiedTests=false` 防止上游模块因无匹配用例中断）
- **integration-prereqs**: 真实模型可用——`ANTHROPIC_API_KEY` 等环境变量，或 `~/.pig-agent/workspace/models.json` 已配

## 约定

- **branch-prefixes**: feat / bug / docs / opt
- **openspec**: yes

## 备注 / 踩坑

> - `mvn -pl <m>` 必须带 `-am`，否则同级模块未装进本地仓库 → 假 BUILD FAILURE。
> - `-Dtest=X` 命中不到的上游模块：加 `-Dsurefire.failIfNoSpecifiedTests=false`。
> - PowerShell 5.1 把 native 命令 stderr 包成 `NativeCommandError` 染红，**以 `Tests run:` / `BUILD SUCCESS` 行和退出码为准**。
> - 逐组提交时 `git add <模块目录>` 要覆盖 `src/main` 与 `src/test`，别漏测试文件。
