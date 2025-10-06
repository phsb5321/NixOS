# Secrets Integration with Chezmoi

This document explains how to use encrypted secrets in your dotfiles using chezmoi templates and sops-nix.

## Overview

Secrets are stored encrypted with sops-nix and exposed as environment variables that chezmoi templates can access. This keeps sensitive data like API tokens, passwords, and private keys secure.

## Prerequisites

1. sops-nix configured (see `modules/secrets/default.nix`)
2. Age key generated for encryption
3. Dotfiles secrets integration enabled:
   ```nix
   modules.dotfiles.secretsIntegration = true;
   ```

## Adding a Secret

### 1. Define Secret in sops-nix

In your host configuration or secrets module:

```nix
sops.secrets.github-token = {
  sopsFile = ./secrets.yaml;
  owner = config.users.users.notroot.name;
};
```

### 2. Expose Secret to Chezmoi

In `modules/dotfiles/default.nix`:

```nix
environment.sessionVariables = mkIf cfg.secretsIntegration {
  CHEZMOI_GITHUB_TOKEN = "/run/secrets/github-token";
};
```

### 3. Use Secret in Template

In your dotfile template (e.g., `dot_gitconfig.tmpl`):

```gitconfig
{{- if env "CHEZMOI_GITHUB_TOKEN" }}
# GitHub token configured
[github]
    token = {{ env "CHEZMOI_GITHUB_TOKEN" }}
{{- else }}
# GitHub token not configured
{{- end }}
```

## Example: NPM Token

See `dot_npmrc.tmpl` for a complete example of conditional secrets usage.

## Template Helpers

Chezmoi provides several functions for working with secrets:

- `{{ env "VAR" }}` - Read environment variable
- `{{ if env "VAR" }}...{{ end }}` - Conditional based on variable presence
- `{{ default "value" (env "VAR") }}` - Provide fallback value

## Security Best Practices

1. **Never commit unencrypted secrets** to git
2. **Use templates** (`.tmpl`) for files containing secrets
3. **Check before committing**: Run `dotfiles-check` to scan for leaked secrets
4. **Rotate secrets regularly**: Update encrypted values in sops files
5. **Limit secret exposure**: Only expose secrets needed by specific templates

## Validation

The `dotfiles-check` script automatically scans for potential secret leaks:

```bash
dotfiles-check
```

This checks for patterns like:
- `password`
- `secret`
- `api_key` / `api-key`
- `private_key` / `private-key`
- `token`

## Example Secrets Configuration

```nix
# modules/secrets/default.nix
{ config, pkgs, ... }:
{
  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/home/notroot/.config/sops/age/keys.txt";

  sops.secrets = {
    github-token = { owner = "notroot"; };
    npm-token = { owner = "notroot"; };
    aws-credentials = { owner = "notroot"; };
  };
}

# modules/dotfiles/default.nix
environment.sessionVariables = mkIf cfg.secretsIntegration {
  CHEZMOI_GITHUB_TOKEN = "/run/secrets/github-token";
  CHEZMOI_NPM_TOKEN = "/run/secrets/npm-token";
  CHEZMOI_AWS_CREDENTIALS = "/run/secrets/aws-credentials";
};
```

## Troubleshooting

### Secret not found in template

- Check that `secretsIntegration = true` in dotfiles config
- Verify secret exists: `ls -la /run/secrets/`
- Check environment variable: `echo $CHEZMOI_SECRET_NAME`
- Rebuild system to apply configuration changes

### Permission denied accessing secret

- Ensure secret owner matches your username
- Check file permissions: `ls -la /run/secrets/secret-name`
- Secret should be owned by your user or readable by your group

### Template not expanding secret

- Use `{{ env "VAR" }}` not `$VAR` (shell syntax)
- Verify template has `.tmpl` extension
- Test template rendering: `chezmoi cat ~/.config/file`

## Further Reading

- [sops-nix documentation](https://github.com/Mic92/sops-nix)
- [chezmoi templating guide](https://www.chezmoi.io/user-guide/templating/)
- [Age encryption](https://github.com/FiloSottile/age)
