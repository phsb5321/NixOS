# MCP Playwright Integration

This runbook covers how to use the Playwright MCP (Model Context Protocol) server to enable AI assistants like Claude Code and OpenCode to automate browser interactions.

## Overview

The Playwright MCP server (`@playwright/mcp`) allows AI assistants to:
- Navigate to URLs and interact with web pages
- Click buttons, fill forms, and extract content
- Use the accessibility tree (no screenshots or vision models needed)
- Automate web testing and data extraction tasks

## Prerequisites

- Node.js 18+ (provided by the testing toolchain)
- A compatible MCP client (Claude Code, OpenCode, VS Code Copilot)
- Any development shell from this repository

### Verify Prerequisites

```bash
# Enter any dev shell
nix-shell shells/JavaScript.nix

# Verify Node.js version (must be 18+)
node --version  # Should show v22.x.x

# Full diagnostics
test-toolchain-diagnose
```

## Claude Code Setup

### Quick Setup

```bash
# Add Playwright MCP server to Claude Code
claude mcp add playwright npx @playwright/mcp@latest
```

### Manual Configuration

Add to your Claude Code MCP configuration:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

### With Headless Mode

For server environments or when you don't want a browser window:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--headless"]
    }
  }
}
```

## OpenCode Setup

For OpenCode, add the MCP configuration to `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "@playwright/mcp@latest"],
      "enabled": true
    }
  }
}
```

### With Headless Mode

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "@playwright/mcp@latest", "--headless"],
      "enabled": true
    }
  }
}
```

## VS Code Copilot Setup

Add to your VS Code settings or workspace configuration:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

## Available MCP Tools

Once configured, the AI assistant has access to these browser automation tools:

| Tool | Description |
|------|-------------|
| `browser_navigate` | Navigate to a URL |
| `browser_click` | Click on an element |
| `browser_type` | Type text into an input field |
| `browser_snapshot` | Capture accessibility tree snapshot |
| `browser_take_screenshot` | Take a visual screenshot |
| `browser_console_messages` | Get browser console output |
| `browser_network_requests` | List network requests |
| `browser_tabs` | Manage browser tabs |
| `browser_close` | Close the browser |

### Example Interactions

Ask the AI assistant:

```
Navigate to https://example.com and click the "Learn More" button
```

```
Fill out the contact form on the current page with test data
```

```
Take a screenshot of the current page and describe what you see
```

## NixOS-Specific Configuration

The testing toolchain automatically sets the required environment variables for Playwright. The MCP server inherits these when launched from a devShell:

- `PLAYWRIGHT_BROWSERS_PATH` - Points to Nix-provided browsers
- `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS` - Skips FHS validation

### Ensuring Environment Variables Are Passed

When using Claude Code or OpenCode, make sure to:

1. Launch the tool from within a devShell:
   ```bash
   nix-shell shells/JavaScript.nix
   claude  # or opencode
   ```

2. Or export variables in your shell profile before launching

## Docker MCP Option

For complete isolation or when Nix-native browsers have issues, run the MCP server in Docker:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "--init", "--pull=always",
        "mcr.microsoft.com/playwright/mcp"
      ]
    }
  }
}
```

### Docker with Host Network Access

If the MCP server needs to access services running on your host:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "--init", "--pull=always",
        "--add-host=host.docker.internal:host-gateway",
        "mcr.microsoft.com/playwright/mcp"
      ]
    }
  }
}
```

Then use `http://host.docker.internal:3000` instead of `http://localhost:3000` when navigating to local services.

## Troubleshooting

### "Browser not found" Error

1. Ensure you're in a devShell with the testing toolchain
2. Run `test-toolchain-diagnose` to verify configuration
3. Check that `PLAYWRIGHT_BROWSERS_PATH` is set

### MCP Server Fails to Start

1. Verify Node.js 18+: `node --version`
2. Try installing the package first: `npm install -g @playwright/mcp`
3. Check for network issues if using `npx`

### "Cannot connect to browser" in Docker Mode

1. Ensure Docker is running: `docker info`
2. Check for port conflicts on the host
3. Try with `--ipc=host` flag for Chromium memory issues

### Browser Opens But Commands Fail

1. Wait for the page to fully load before interacting
2. Use accessibility-friendly selectors (text content, roles)
3. Check the browser console for JavaScript errors

## Best Practices

1. **Start from devShell**: Always launch your AI tool from within a Nix devShell to inherit environment variables

2. **Use headless for automation**: Add `--headless` flag for unattended operations

3. **Pin MCP version for reproducibility**: Use `@playwright/mcp@0.0.54` instead of `@latest` in production

4. **Docker for isolation**: Use Docker mode when testing untrusted websites or for maximum reproducibility

## Related Documentation

- [Nix-Native Testing](./testing-nixos.md) - Direct Playwright usage
- [Docker Fallback](./testing-docker.md) - Full browser matrix testing
- [Selenium Testing](./selenium.md) - WebDriver-based testing
