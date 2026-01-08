# Nix-Native Browser Testing on NixOS

This runbook covers how to run Playwright and Selenium browser tests using the Nix-provided browser toolchain. No runtime browser downloads are required.

## Prerequisites

- NixOS with flakes enabled
- Any development shell from this repository (JavaScript, Python, Golang, etc.)

## Quick Start

### 1. Enter a Development Shell

```bash
# JavaScript development
nix-shell shells/JavaScript.nix

# Or any other shell
nix-shell shells/Python.nix
nix-shell shells/Rust.nix
```

### 2. Verify the Toolchain

```bash
test-toolchain-diagnose
```

You should see all checks passing with `Status: READY`.

### 3. Run Playwright Tests

```bash
# Install Playwright (pin version to match Nix)
npm install @playwright/test@1.57.0

# Run tests with Chromium (Nix-native)
npx playwright test --project=chromium
```

## Environment Variables

The testing toolchain automatically exports these environment variables:

| Variable | Value | Purpose |
|----------|-------|---------|
| `PLAYWRIGHT_BROWSERS_PATH` | `/nix/store/...-playwright-browsers` | Points Playwright to Nix-provided browsers |
| `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS` | `true` | Skips FHS-style library path validation |
| `PUPPETEER_EXECUTABLE_PATH` | `/nix/store/.../chromium` | Provides Chromium path for Puppeteer |
| `PLAYWRIGHT_NODEJS_PATH` | `/nix/store/.../node` | Explicit Node.js path |

## Version Alignment (Critical)

The npm Playwright version **MUST match** the nixpkgs `playwright-driver` version.

### Finding the Correct Version

```bash
# Run diagnostics to see the Nix Playwright version
test-toolchain-diagnose

# Look for the version in the output:
# [Version Alignment]
#   [OK] Nix Playwright version: ~1.57.x (build 1200)
#        Hint: Pin npm @playwright/test to ~1.57.0
```

### Pinning in package.json

```json
{
  "devDependencies": {
    "@playwright/test": "1.57.0"
  }
}
```

### Version Mismatch Errors

If you see errors like:
```
browserType.launch: Executable doesn't exist at /path/to/chromium
```

This usually means a version mismatch. Solutions:

1. **Pin npm version** (recommended):
   ```bash
   npm install @playwright/test@1.57.0
   ```

2. **Use executablePath override** (escape hatch):
   ```javascript
   const browser = await chromium.launch({
     executablePath: process.env.PUPPETEER_EXECUTABLE_PATH
   });
   ```

## Supported Browsers

### Chromium (Fully Supported)

Chromium works natively on NixOS with full feature support.

```javascript
// playwright.config.js
export default {
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
};
```

### Firefox and WebKit (Docker Recommended)

Firefox and WebKit have known packaging issues on NixOS. For these browsers:

1. Use the Docker fallback: `./scripts/playwright-docker.sh test`
2. Or run in CI with full browser support

See [testing-docker.md](./testing-docker.md) for Docker fallback instructions.

## Headless vs Headed Mode

### Default: Headless

All tests run headless by default, which works in both local and CI environments.

### Headed Mode (Visual Debugging)

For visual debugging, use the `--headed` flag:

```bash
npx playwright test --headed
```

Or in code:

```javascript
const browser = await chromium.launch({ headless: false });
```

## Python with pytest-playwright

```bash
# Enter Python shell
nix-shell shells/Python.nix

# Install pytest-playwright (pin version)
pip install pytest-playwright

# Run tests
pytest --browser chromium
```

The environment variables are automatically available.

## Troubleshooting

### "Browser not found" Error

1. Run `test-toolchain-diagnose` to check configuration
2. Ensure `PLAYWRIGHT_BROWSERS_PATH` is set
3. Check version alignment (see above)

### "Missing dependency" Error

This usually means `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS` is not set. The testing toolchain sets this automatically, but if running outside a devShell:

```bash
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
```

### Tests Timeout on First Run

The first run may take longer as Nix store paths are resolved. Subsequent runs should be faster.

### Debug Mode

For detailed debugging:

```bash
DEBUG=pw:api npx playwright test
```

## CI Integration

For CI environments, the same environment variables apply:

```yaml
# GitHub Actions example
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: cachix/install-nix-action@v22
      - run: nix-shell shells/JavaScript.nix --run "npx playwright test --project=chromium"
```

## Related Documentation

- [Docker Fallback](./testing-docker.md) - For Firefox/WebKit testing
- [MCP Integration](./mcp-playwright.md) - For Claude Code browser automation
- [Selenium Testing](./selenium.md) - For Selenium WebDriver usage
