# Install Gitea Tea CLI

[![CI](https://github.com/LiquidLogicLabs/git-action-install-gitea-tea/workflows/CI/badge.svg)](https://github.com/LiquidLogicLabs/git-action-install-gitea-tea/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A GitHub Action that installs and configures the [tea](https://gitea.com/gitea/tea) CLI tool for Gitea.

## Description

This action downloads and installs the `tea` (Gitea CLI) binary, making it available in your workflow's PATH. It also optionally configures authentication to your Gitea instance.

## Features

- Installs the latest version of `tea` CLI or a specific version
- Supports Linux amd64 and arm64 architectures
- Automatically configures authentication using tokens
- Uses intelligent token resolution (input → GITEA_TOKEN → GITHUB_TOKEN)
- Provides outputs for binary path and installed version
- Uses current repository context for default values

## Usage

### Basic Usage

```yaml
- name: Install tea CLI
  uses: LiquidLogicLabs/git-action-install-gitea-tea@v1
```

### With Custom Version

```yaml
- name: Install tea CLI
  uses: LiquidLogicLabs/git-action-install-gitea-tea@v1
  with:
    version: '0.9.0'
```

### With Authentication

```yaml
- name: Install and configure tea CLI
  uses: LiquidLogicLabs/git-action-install-gitea-tea@v1
  with:
    token: ${{ secrets.GITEA_TOKEN }}
    repo: 'https://gitea.example.com'
```

### Using Environment Variables

```yaml
- name: Install tea CLI
  uses: LiquidLogicLabs/git-action-install-gitea-tea@v1
  env:
    GITEA_TOKEN: ${{ secrets.GITEA_TOKEN }}
```

### Complete Example

```yaml
name: Example Workflow

on:
  push:
    branches: [main]

jobs:
  example:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install tea CLI
        id: install-tea
        uses: LiquidLogicLabs/git-action-install-gitea-tea@v1
        with:
          version: 'latest'
          token: ${{ secrets.GITEA_TOKEN }}
          repo: 'https://gitea.example.com'

      - name: Use tea CLI
        run: |
          echo "tea is installed at: ${{ steps.install-tea.outputs.binary-path }}"
          echo "tea version: ${{ steps.install-tea.outputs.version }}"
          tea --version
          tea login list
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `version` | Version of tea to install. Use `latest` to get the latest version, or specify a version like `0.9.0` or `v0.9.0` | No | `latest` |
| `username` | Gitea username for authentication | No | `${{ github.actor }}` |
| `token` | Gitea personal access token. If not provided, will use `GITEA_TOKEN` or `GITHUB_TOKEN` environment variables | No | (checks env vars) |
| `repo` | Gitea repository URL (e.g., `https://gitea.com` or `https://gitea.example.com`) | No | `${{ github.server_url }}/${{ github.repository_owner }}` |
| `skip-certificate-check` | Skip TLS certificate verification when downloading tea or calling APIs | No | `false` |
| `verbose` | Enable verbose debug logging. Also enabled when ACTIONS_STEP_DEBUG=true | No | `false` |

## Outputs

| Output | Description |
|--------|-------------|
| `success` | Indicates if the installation was successful (`true` or `false`) |
| `binary-path` | Path where the tea binary was installed (typically `/usr/local/bin/tea`) |
| `version` | Version of tea that was installed |

## Permissions

No special permissions are required. The action downloads the tea binary; typical workflows need `contents: read` for checkout.

## Token Resolution

The action uses the following priority order to resolve the authentication token:

1. `token` input parameter
2. `GITEA_TOKEN` environment variable
3. `GITHUB_TOKEN` environment variable (fallback)

This allows you to use the action without explicitly providing a token if you have one of these environment variables set.

## Default Values

The action intelligently uses GitHub context for defaults:

- **username**: Uses `${{ github.actor }}` (the workflow user)
- **repo**: Uses `${{ github.server_url }}/${{ github.repository_owner }}` (current repository's base URL)
- **token**: Checks environment variables as described above

## Platform Support

- **Linux**: amd64 and arm64 architectures
- **macOS**: Not currently supported
- **Windows**: Not currently supported

## Security

### Token Handling

- **Never hardcode tokens** in your workflow files
- Use GitHub Secrets to store sensitive tokens
- The action automatically masks tokens in logs using `::add-mask::`
- Tokens are passed securely through environment variables

### Best Practices

1. Store tokens in GitHub Secrets:
   ```yaml
   with:
     token: ${{ secrets.GITEA_TOKEN }}
   ```

2. Use environment variables for token resolution:
   ```yaml
   env:
     GITEA_TOKEN: ${{ secrets.GITEA_TOKEN }}
   ```

3. Limit token permissions to only what's needed
4. Use separate tokens for different environments

## Examples

### Install Latest Version

```yaml
- uses: LiquidLogicLabs/git-action-install-gitea-tea@v1
```

### Install Specific Version

```yaml
- uses: LiquidLogicLabs/git-action-install-gitea-tea@v1
  with:
    version: '0.9.0'
```

### Install with Custom Gitea Instance

```yaml
- uses: LiquidLogicLabs/git-action-install-gitea-tea@v1
  with:
    repo: 'https://gitea.example.com'
    token: ${{ secrets.GITEA_TOKEN }}
```

### Use Outputs

```yaml
- name: Install tea
  id: tea
  uses: LiquidLogicLabs/git-action-install-gitea-tea@v1

- name: Display info
  run: |
    echo "Binary: ${{ steps.tea.outputs.binary-path }}"
    echo "Version: ${{ steps.tea.outputs.version }}"
```

## Troubleshooting

### Installation Fails

- Ensure you're running on a Linux runner (ubuntu-latest, etc.)
- Check that the version exists: https://github.com/go-gitea/tea/releases
- Verify network connectivity to `dl.gitea.io`

### Authentication Fails

- Verify your token has the correct permissions
- Check that the repository URL is correct
- Ensure the token is not expired
- Check logs for specific error messages

### Binary Not Found

- The binary is installed to `/usr/local/bin/tea`
- Ensure `/usr/local/bin` is in your PATH (it should be by default)
- Check outputs: `${{ steps.install-tea.outputs.binary-path }}`

## License

MIT

## Credits

- [tea CLI](https://gitea.com/gitea/tea) - The Gitea CLI tool
- [Gitea](https://gitea.io/) - The Gitea project
