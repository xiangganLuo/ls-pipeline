# Development Workflow

> This file extends [common/git-workflow.md](./git-workflow.md) with the full feature development process that happens before git operations.

> **强制流程入口**：实现任何需求/特性/修复，MUST 走 `/ls:*` 半自动流水线——见 [ls-pipeline.md](./ls-pipeline.md)（澄清→spec→[code⇄itest]→归档，三道人工门不得越过）。本文件描述的是流水线各阶段**内部**的做法（研究复用、TDD、评审）。

The Feature Implementation Workflow describes the development pipeline: research, planning, TDD, code review, and then committing to git.

## Feature Implementation Workflow

0. **Research & Reuse** _(mandatory before any new implementation)_
   - **Code search first:** Search existing repos/code (e.g. `gh search repos` / `gh search code`, or your org's code search) for existing implementations, templates, and patterns before writing anything new.
   - **Library docs second:** Use Context7 or primary vendor docs to confirm API behavior, package usage, and version-specific details before implementing.
   - **Broader web research only when the first two are insufficient.**
   - **Check package registries:** Search npm, PyPI, crates.io, Maven Central, and other registries before writing utility code. Prefer battle-tested libraries over hand-rolled solutions.
   - **Search for adaptable implementations:** Look for open-source projects that solve 80%+ of the problem and can be forked, ported, or wrapped.
   - Prefer adopting or porting a proven approach over writing net-new code when it meets the requirement.

1. **Plan First**
   - Use a planning subagent if one is available; otherwise plan inline.
   - Generate planning docs before coding as needed: PRD, architecture, system design, task list.
   - Identify dependencies and risks; break down into phases.
   - In the `/ls:*` pipeline this is `/ls:clarify` + `/ls:spec`.

2. **TDD Approach**
   - Use a TDD subagent if one is available.
   - Write tests first (RED) → implement to pass (GREEN) → refactor (IMPROVE).
   - Verify coverage against the project's threshold (default 80%, per [testing.md](./testing.md)).
   - In the pipeline this is the `/ls:code` inner loop.

3. **Code Review**
   - Use a code-review (and, for sensitive changes, a security-review) subagent immediately after writing code, if available.
   - Address CRITICAL and HIGH issues; fix MEDIUM when possible.
   - Per [ls-pipeline.md](./ls-pipeline.md) rule #5, every surviving finding must be tracked into a spec, not left as an unowned backlog item.

4. **Integration / E2E Verification**
   - Run the project's integration/E2E suite (the `/ls:itest` outer loop) when the change has behavior that unit tests can't cover.
   - Commands come from `ls-pipeline.config.md` (`integration-test`); `none` means skip.

5. **Commit & Push**
   - Detailed, conventional-commit messages. See [git-workflow.md](./git-workflow.md).

6. **Pre-Review Checks**
   - Verify automated checks (CI/CD) pass, resolve merge conflicts, keep branch up to date with target.
   - Only request review after these pass.
