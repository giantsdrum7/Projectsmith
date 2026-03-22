# E2E Testing with Playwright

This scaffold adds a minimal, opt-in Playwright browser-testing layer for
{{ project_name }}. Tests live in `apps/web/e2e/` and are intentionally
isolated from the Python toolchain.

---

## What this is for

These tests verify user-visible behaviour in a running web app. They complement
unit and contract tests by exercising the full browser → app → response path.

Day-1 scope is intentionally small: one smoke test, Chromium only. Expand as
the web app matures.

---

## Prerequisites

- Node 20+ (use `nvm use` if you have nvm; the repo pins `20` in `.nvmrc`)
- A running web app accessible at a known URL

---

## First-time setup

```powershell
# Windows
pwsh scripts/e2e-install.ps1

# Unix / macOS
bash scripts/e2e-install.sh
```

This runs `npm install` in `apps/web/e2e/` and downloads the Chromium browser
binary. It does not affect the Python virtual environment.

---

## Running tests

### Without a running app (safe default)

```powershell
pwsh scripts/e2e-test.ps1
```

When `BASE_URL` is unset, the smoke test skips gracefully with a clear message.
No failures. No noise for repos that don't yet have a deployed web app.

### Against a local dev server

```powershell
# Windows
pwsh scripts/e2e-test.ps1 -BaseUrl http://localhost:3000

# Unix / macOS
bash scripts/e2e-test.sh http://localhost:3000
```

### Against a staging or preview environment

```powershell
pwsh scripts/e2e-test.ps1 -BaseUrl https://staging.example.com
```

---

## How BASE_URL works

`BASE_URL` is the origin the tests navigate to. It maps to Playwright's
`baseURL` config option, so `page.goto("/")` resolves to `BASE_URL + "/"`.

The smoke test explicitly checks `process.env.BASE_URL` at runtime and calls
`test.skip()` when it is absent. This prevents the suite from erroring in CI
environments where no web app is running yet.

---

## Interactive exploration

```powershell
pwsh scripts/e2e-ui.ps1 -BaseUrl http://localhost:3000
```

Opens Playwright's interactive Test UI for stepping through tests, inspecting
actions, and debugging locators.

---

## Viewing the last HTML report

```powershell
pwsh scripts/e2e-report.ps1
```

---

## Adding tests

Write new `*.spec.ts` files in `apps/web/e2e/tests/`. Follow Playwright's
guidance on preferring accessible, user-facing locators:

- `page.getByRole(...)` — roles (button, link, heading, etc.)
- `page.getByLabel(...)` — form labels
- `page.getByText(...)` — visible text
- `page.getByTestId(...)` — `data-testid` attributes (last resort)

Avoid CSS class selectors and brittle XPath wherever possible. Tests should
reflect what a user sees and does, not implementation details.

---

## CI usage

The `e2e.yml` workflow is `workflow_dispatch` only. Trigger it manually from
GitHub Actions once the web app has a deployed environment:

1. Open the Actions tab in GitHub.
2. Select "E2E Tests (Playwright)".
3. Click "Run workflow" and supply the `base_url` input.

Change the trigger to `push` or `pull_request` once you have a stable preview
environment to test against.

---

## Keeping this minimal

This scaffold intentionally omits:

- Page Object Models (add when the app is complex enough to warrant them)
- Auth/session fixtures (add when login flows are stable)
- Firefox / WebKit matrix (add when cross-browser coverage is a requirement)
- Visual snapshot testing (add when visual regression is a priority)
- Custom reporter stack

Add these when the project is ready for them, not before.
