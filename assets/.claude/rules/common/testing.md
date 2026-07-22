# Testing Requirements

## Minimum Test Coverage: 80%

The threshold (and the coverage tool) come from `ls-pipeline.config.md` (`coverage`). If it is `none`, treat "unit tests all green + key branches covered" as the hard gate and coverage as advisory.

Test Types (as applicable to the stack):
1. **Unit Tests** - Individual functions, utilities, components (the `/ls:code` inner loop).
2. **Integration Tests** - API endpoints, database operations, external services.
3. **E2E / real-model Tests** - Critical user flows or live-model behavior (the `/ls:itest` outer loop; `integration-test` in config).

## Test-Driven Development

MANDATORY workflow (the `/ls:code` inner loop):
1. Write test first (RED)
2. Run test - it should FAIL
3. Write minimal implementation (GREEN)
4. Run test - it should PASS
5. Refactor (IMPROVE)
6. Verify coverage against the project threshold

Run tests with the `unit-test` command from `ls-pipeline.config.md` — do not assume a specific tool (`mvn`/`npm`/`pytest`/`cargo`/…).

## Troubleshooting Test Failures

1. Use a TDD subagent if available.
2. Check test isolation.
3. Verify mocks are correct.
4. Fix implementation, not tests (unless the tests are wrong).

## Test Structure (AAA Pattern)

Prefer Arrange-Act-Assert structure. Example (language-neutral):

```
test("calculates cosine similarity correctly") {
  // Arrange
  vector1 = [1, 0, 0]
  vector2 = [0, 1, 0]

  // Act
  similarity = cosineSimilarity(vector1, vector2)

  // Assert
  expect(similarity).toBe(0)
}
```

### Test Naming

Use descriptive names that explain the behavior under test, and that your framework's default test collector will pick up:

```
"returns empty array when no records match query"
"throws error when API key is missing"
"falls back to substring search when cache is unavailable"
```
