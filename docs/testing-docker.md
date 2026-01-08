# Docker Fallback for Browser Testing

This runbook covers how to run Playwright tests using Docker when Nix-native execution isn't sufficient (Firefox, WebKit) or when you need a fully isolated testing environment.

## When to Use Docker

Use the Docker fallback when:
- Testing Firefox or WebKit browsers (known Nix packaging issues)
- You need 100% browser compatibility
- Running in CI without NixOS
- Troubleshooting Nix-native issues

## Prerequisites

- Docker installed and running
- NixOS: `virtualisation.docker.enable = true;` in configuration.nix

## Quick Start

### Run All Tests in Docker

```bash
./scripts/playwright-docker.sh test
```

### Run Specific Browser

```bash
./scripts/playwright-docker.sh test --project=firefox
./scripts/playwright-docker.sh test --project=webkit
./scripts/playwright-docker.sh test --project=chromium
```

### Interactive Shell

```bash
./scripts/playwright-docker.sh shell
```

## Scripts Reference

### playwright-docker.sh

Runs Playwright tests inside a Docker container.

```bash
# Run all tests
./scripts/playwright-docker.sh test

# Run with specific options
./scripts/playwright-docker.sh test --project=firefox --headed

# Open interactive shell
./scripts/playwright-docker.sh shell

# Run arbitrary command
./scripts/playwright-docker.sh run npx playwright show-report

# Pull latest image
./scripts/playwright-docker.sh pull

# Check version
./scripts/playwright-docker.sh version
```

### playwright-server-docker.sh

Runs a Playwright Server in Docker for remote browser connections. Tests run on host, browsers run in container.

```bash
# Start the server
./scripts/playwright-server-docker.sh start

# Check status
./scripts/playwright-server-docker.sh status

# View logs
./scripts/playwright-server-docker.sh logs

# Stop the server
./scripts/playwright-server-docker.sh stop

# Use custom port
./scripts/playwright-server-docker.sh start --port 4000
```

## Playwright Server Mode

Server mode separates test execution (host) from browser execution (container). This is useful for:
- Debugging tests while browsers run in Docker
- Sharing a browser instance across multiple test runs
- Faster iteration during development

### Usage

```bash
# Terminal 1: Start the server
./scripts/playwright-server-docker.sh start

# Terminal 2: Run tests connecting to server
PW_TEST_CONNECT_WS_ENDPOINT=ws://127.0.0.1:3000/ npx playwright test

# Or export the variable
export PW_TEST_CONNECT_WS_ENDPOINT=ws://127.0.0.1:3000/
npx playwright test

# When done
./scripts/playwright-server-docker.sh stop
```

## Accessing Host Services

When tests need to access services running on your host machine (e.g., a local dev server):

### Problem

`localhost` inside Docker refers to the container, not your host.

### Solution

Use `host.docker.internal` or `hostmachine`:

```javascript
// Instead of this:
await page.goto('http://localhost:3000');

// Use this:
await page.goto('http://host.docker.internal:3000');
// or
await page.goto('http://hostmachine:3000');
```

The scripts automatically add `--add-host=hostmachine:host-gateway` to Docker.

## Docker Image Versions

The scripts use Microsoft's official Playwright Docker images:

```
mcr.microsoft.com/playwright:v1.57.0-noble
```

### Image Tag Format

```
mcr.microsoft.com/playwright:<version>-<ubuntu-codename>
```

| Ubuntu Version | Codename |
|----------------|----------|
| 24.04 LTS | noble |
| 22.04 LTS | jammy |

### Changing the Version

```bash
# Use environment variable
PLAYWRIGHT_VERSION=v1.57.0 ./scripts/playwright-docker.sh test

# Or for Playwright Server
PLAYWRIGHT_VERSION=v1.57.0 ./scripts/playwright-server-docker.sh start
```

## Docker Flags Explained

The scripts use these important Docker flags:

| Flag | Purpose |
|------|---------|
| `--ipc=host` | Required for Chromium - prevents memory issues |
| `--init` | Proper signal handling, prevents zombie processes |
| `-v $(pwd):/work` | Mounts current directory as /work in container |
| `--add-host=hostmachine:host-gateway` | Allows accessing host services |

## CI Integration

### GitHub Actions

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Playwright tests
        run: |
          docker run --rm --ipc=host --init \
            -v ${{ github.workspace }}:/work \
            -w /work \
            mcr.microsoft.com/playwright:v1.57.0-noble \
            npx playwright test
```

### GitLab CI

```yaml
test:
  image: mcr.microsoft.com/playwright:v1.57.0-noble
  script:
    - npx playwright test
```

## Troubleshooting

### Docker Not Installed

```
Error: Docker is not installed

Docker is required for the Playwright fallback.
Install Docker by adding to configuration.nix:
  virtualisation.docker.enable = true;
```

**Solution**: Add Docker to your NixOS configuration and rebuild.

### Docker Daemon Not Running

```
Error: Docker daemon is not running
Start with: sudo systemctl start docker
```

**Solution**: Start the Docker service:
```bash
sudo systemctl start docker
```

### Permission Denied

If you see permission errors:

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER

# Log out and back in, or:
newgrp docker
```

### Image Pull Fails

```bash
# Manually pull the image
./scripts/playwright-docker.sh pull

# Or specify a different registry/version
PLAYWRIGHT_VERSION=v1.50.0 ./scripts/playwright-docker.sh pull
```

### Container Memory Issues

If tests crash with OOM errors:

```bash
# Run with memory limit
docker run --rm --ipc=host --init --memory=4g \
  -v $(pwd):/work -w /work \
  mcr.microsoft.com/playwright:v1.57.0-noble \
  npx playwright test
```

## Related Documentation

- [Nix-Native Testing](./testing-nixos.md) - For Chromium testing without Docker
- [MCP Integration](./mcp-playwright.md) - For Claude Code browser automation
- [Selenium Testing](./selenium.md) - For Selenium WebDriver usage
