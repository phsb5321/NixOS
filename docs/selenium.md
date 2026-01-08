# Selenium WebDriver Testing on NixOS

This runbook covers how to run Selenium WebDriver tests using the Nix-provided browser drivers. No runtime driver downloads are required.

## Overview

The testing toolchain provides pre-built WebDriver executables:

- **chromedriver** - For Chrome/Chromium automation
- **geckodriver** - For Firefox automation

These drivers are automatically added to your PATH when entering any development shell.

## Prerequisites

- Any development shell from this repository
- Selenium client library for your language

### Verify Prerequisites

```bash
# Enter any dev shell
nix-shell shells/Python.nix

# Check driver availability
chromedriver --version
geckodriver --version

# Full diagnostics
test-toolchain-diagnose
```

## Python Examples

### Basic Setup

```bash
# Enter Python shell
nix-shell shells/Python.nix

# Install Selenium
pip install selenium
```

### Chromium Example

```python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

# Configure headless Chromium
options = Options()
options.add_argument('--headless')
options.add_argument('--no-sandbox')
options.add_argument('--disable-dev-shm-usage')

# Create driver (uses chromedriver from PATH)
driver = webdriver.Chrome(options=options)

try:
    driver.get('https://example.com')
    print(f"Page title: {driver.title}")
finally:
    driver.quit()
```

### Firefox Example

```python
from selenium import webdriver
from selenium.webdriver.firefox.options import Options

# Configure headless Firefox
options = Options()
options.add_argument('--headless')

# Create driver (uses geckodriver from PATH)
driver = webdriver.Firefox(options=options)

try:
    driver.get('https://example.com')
    print(f"Page title: {driver.title}")
finally:
    driver.quit()
```

### Using pytest-selenium

```bash
# Install pytest-selenium
pip install pytest pytest-selenium

# Run tests with Chromium
pytest --driver Chrome --driver-path $(which chromedriver)

# Run tests with Firefox
pytest --driver Firefox --driver-path $(which geckodriver)
```

## JavaScript Examples

### Basic Setup

```bash
# Enter JavaScript shell
nix-shell shells/JavaScript.nix

# Install Selenium WebDriver
npm install selenium-webdriver
```

### Chromium Example

```javascript
const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

async function runTest() {
    // Configure headless Chrome
    const options = new chrome.Options();
    options.addArguments('--headless');
    options.addArguments('--no-sandbox');
    options.addArguments('--disable-dev-shm-usage');

    // Uses chromedriver from PATH
    const driver = await new Builder()
        .forBrowser('chrome')
        .setChromeOptions(options)
        .build();

    try {
        await driver.get('https://example.com');
        const title = await driver.getTitle();
        console.log(`Page title: ${title}`);
    } finally {
        await driver.quit();
    }
}

runTest();
```

### Firefox Example

```javascript
const { Builder } = require('selenium-webdriver');
const firefox = require('selenium-webdriver/firefox');

async function runTest() {
    // Configure headless Firefox
    const options = new firefox.Options();
    options.addArguments('--headless');

    // Uses geckodriver from PATH
    const driver = await new Builder()
        .forBrowser('firefox')
        .setFirefoxOptions(options)
        .build();

    try {
        await driver.get('https://example.com');
        const title = await driver.getTitle();
        console.log(`Page title: ${title}`);
    } finally {
        await driver.quit();
    }
}

runTest();
```

## Selenium Manager Conflict

Selenium 4.6+ includes "Selenium Manager" which auto-downloads drivers. On NixOS, this can conflict with Nix-provided drivers.

### Solution 1: PATH Takes Precedence (Default)

The Nix-provided drivers are added to PATH and take precedence over Selenium Manager. This usually works automatically.

### Solution 2: Explicit Driver Path

For explicit control, specify the driver path:

**Python:**

```python
from selenium import webdriver
from selenium.webdriver.chrome.service import Service

# Use explicit path to Nix-provided chromedriver
service = Service(executable_path='/run/current-system/sw/bin/chromedriver')
driver = webdriver.Chrome(service=service)
```

**JavaScript:**

```javascript
const chrome = require('selenium-webdriver/chrome');

const service = new chrome.ServiceBuilder()
    .setPath('/run/current-system/sw/bin/chromedriver')
    .build();

const driver = await new Builder()
    .forBrowser('chrome')
    .setChromeService(service)
    .build();
```

### Solution 3: Disable Selenium Manager

Set environment variable to disable auto-download:

```bash
export SE_MANAGER_PATH=/bin/true  # No-op
```

## Headless vs Headed Mode

### Headless (Recommended)

Headless mode works best on NixOS and in CI environments:

```python
options.add_argument('--headless')
```

### Headed Mode (Visual Debugging)

For visual debugging, omit the `--headless` flag. Requires a display server (Wayland or X11).

```python
# No --headless argument = browser window opens
options = Options()
driver = webdriver.Chrome(options=options)
```

## Common Chrome Options for NixOS

These options help with common NixOS-specific issues:

```python
options = Options()

# Required for running in containers/sandboxed environments
options.add_argument('--no-sandbox')

# Overcomes limited /dev/shm in Docker
options.add_argument('--disable-dev-shm-usage')

# Headless mode
options.add_argument('--headless')

# Disable GPU (useful in VMs without GPU passthrough)
options.add_argument('--disable-gpu')

# Set window size for consistent screenshots
options.add_argument('--window-size=1920,1080')
```

## Selenium Grid (Experimental)

Playwright can connect to Selenium Grid for remote browser execution:

```bash
SELENIUM_REMOTE_URL=http://<selenium-hub-ip>:4444 npx playwright test
```

### Limitations

- Only supports Chrome/Edge (not Firefox/WebKit via Grid)
- Experimental feature in Playwright
- Uses Chrome DevTools Protocol over Selenium's WebDriver

### Running Selenium Grid Locally

```bash
# Pull and run Selenium standalone Chrome
docker run -d -p 4444:4444 -p 7900:7900 --shm-size="2g" \
    selenium/standalone-chrome:latest

# Connect tests to Grid
export SELENIUM_REMOTE_URL=http://localhost:4444
python my_selenium_tests.py
```

## Troubleshooting

### "chromedriver: command not found"

1. Ensure you're in a devShell: `nix-shell shells/Python.nix`
2. Run diagnostics: `test-toolchain-diagnose`
3. Check PATH includes Nix store paths

### "Chrome not reachable" or "Session not created"

1. Use `--no-sandbox` flag with Chrome options
2. Check if Chromium is installed: `which chromium`
3. Try headless mode if display issues

### Version Mismatch Errors

ChromeDriver version must match Chrome version. The testing toolchain ensures compatible versions from nixpkgs.

If you see version mismatch errors:
1. Update nixpkgs to get aligned versions
2. Use `nix flake update` to refresh inputs

### "geckodriver unexpectedly exited"

1. Ensure Firefox is installed and in PATH
2. Check geckodriver logs with `--log trace` flag
3. Try headless mode

### Tests Timeout

1. Increase implicit/explicit waits
2. Check network connectivity
3. Use `--disable-gpu` flag in VMs

## CI Integration

### GitHub Actions

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: cachix/install-nix-action@v22
      - run: |
          nix-shell shells/Python.nix --run "
            pip install selenium pytest
            pytest tests/selenium/
          "
```

### GitLab CI

```yaml
test:
  image: nixos/nix
  script:
    - nix-shell shells/Python.nix --run "pip install selenium && python test_selenium.py"
```

## Related Documentation

- [Nix-Native Testing](./testing-nixos.md) - Playwright usage
- [Docker Fallback](./testing-docker.md) - Containerized testing
- [MCP Integration](./mcp-playwright.md) - AI-assisted browser automation
