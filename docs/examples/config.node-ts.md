# 样例配置：Node / TypeScript

> 复制到项目的 `ls-pipeline.config.md` 后按需微调（包管理器、E2E 框架）。单包与 monorepo 两种写法都给了。

## 基本

- **language / stack**: TypeScript / Node（pnpm）
- **shell**: bash
- **module-layout**: 单包（monorepo 用 workspace：指定单包 `pnpm -F <pkg>` 或 `npm -w <pkg>`）

## 构建（编译 / 类型检查）

- **build**: `pnpm build`（或纯类型检查：`pnpm tsc --noEmit`）

## 单元测试

- **unit-test（整体）**: `pnpm test`（Vitest / Jest）
- **single-test（单文件模板）**: `pnpm vitest run <file>`（Jest：`pnpm jest <file>`）

## 覆盖率

- **coverage**: vitest --coverage（v8）/ ≥80%（或 nyc / ≥80%）

## 集成测试

- **integration-test**: `pnpm test:e2e`（Playwright / Cypress；或按 tag：`pnpm vitest run -t integration`）
- **integration-prereqs**: 本地服务已起（`pnpm dev` 或 docker compose up）、`.env.test` 内的 API key 已配；无独立 E2E 层则填 none

## 约定

- **branch-prefixes**: feat / bug / docs / opt
- **openspec**: yes

## 备注 / 踩坑

> - monorepo 里 `-F`/`-w` 指定包，别在根跑全量拖慢内环。
> - Playwright 首次需 `pnpm playwright install`（浏览器二进制），列进 integration-prereqs。
> - 纯库项目通常 `integration-test: none`，内环绿即通过。
