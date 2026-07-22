# 样例配置：Python

> 复制到项目的 `ls-pipeline.config.md` 后按需微调（包管理器、测试标记）。

## 基本

- **language / stack**: Python 3.12 / Poetry（uv/pip 同理）
- **shell**: bash
- **module-layout**: 单包（src 布局）；子包用 `pytest <path>` 定位

## 构建（编译 / 类型检查）

- **build**: `poetry run mypy src`（Python 无编译步；用类型检查/静态检查兜底，也可加 `ruff check`）

## 单元测试

- **unit-test（整体）**: `poetry run pytest`
- **single-test（单文件/单例模板）**: `poetry run pytest <path>::<TestClass>::<test_fn>`

## 覆盖率

- **coverage**: coverage.py（pytest-cov）/ ≥80% —— `poetry run pytest --cov=src --cov-fail-under=80`

## 集成测试

- **integration-test**: `poetry run pytest -m integration`（用 `@pytest.mark.integration` 标记；单测跑时用 `-m "not integration"` 排除）
- **integration-prereqs**: 相关 API key 环境变量 / 测试数据库 / docker 依赖已起；无独立集成层则填 none

## 约定

- **branch-prefixes**: feat / bug / docs / opt
- **openspec**: yes

## 备注 / 踩坑

> - 用 pytest marker 区分单测/集成，内环 `-m "not integration"` 保持快、离线。
> - `--cov-fail-under=80` 让覆盖率成为硬门，与 `coverage` 字段一致。
> - 虚拟环境隔离：命令统一用 `poetry run`（或 `uv run`），别依赖已 `activate` 的环境（子进程可能不继承）。
