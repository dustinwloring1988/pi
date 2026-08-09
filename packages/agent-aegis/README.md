<p align="center">
  <strong>Aegis Security Agent</strong>
</p>
<p align="center">
  <a href="https://www.npmjs.com/package/@buckeyestudio/agent-aegis"><img alt="npm" src="https://img.shields.io/npm/v/@buckeyestudio/agent-aegis?style=flat-square" /></a>
</p>

---

Aegis is a security-focused terminal coding agent based on [pi](https://github.com/earendil-works/pi-mono). It provides read, bash, edit, and write tools with full session management, designed for penetration testing and security assessments.

Aegis runs in Docker containers with pre-installed security tools (Kali, Ubuntu, Debian) and connects to local Ollama models for offline operation.

## Quick Start

### Install globally

```bash
npm install -g @buckeyestudio/agent-aegis
```

### Run with Docker

```powershell
# Kali container with pentest toolkit
.\docker-run.ps1 -ContainerType kali

# Ubuntu container
.\docker-run.ps1 -ContainerType ubuntu

# Debian container
.\docker-run.ps1 -ContainerType debian

# With vulnerable target containers
.\docker-run.ps1 -ContainerType kali -VulnContainer redis
.\docker-run.ps1 -ContainerType kali -VulnContainer web
```

### Run directly

```bash
export ANTHROPIC_API_KEY=sk-ant-...
aegis
```

Or use your existing subscription:

```bash
aegis
/login  # Then select provider
```

## Docker Containers

Aegis ships with three container types:

| Container | Base | Tools |
|-----------|------|-------|
| `kali` | Kali Linux | nmap, sqlmap, nikto, metasploit, john, hashcat, hydra, aircrack-ng, impacket, pwntools |
| `ubuntu` | Ubuntu 24.04 | nmap, netcat, redis-tools, python3 |
| `debian` | Debian Bookworm | nmap, netcat, python3 |

All containers include Node.js 24.x and aegis installed globally.

### Vulnerable Target Containers

| Target | Description | Port |
|--------|-------------|------|
| `redis` | Redis 5.0.7 with CVE-2022-0543 | 6379 |
| `web` | Flask web application | 5000 |

## Configuration

Aegis stores configuration in `~/.aegis/agent/`:

| File | Purpose |
|------|---------|
| `models.json` | Provider and model configurations |
| `auth.json` | Authentication credentials |
| `settings.json` | User preferences |
| `extensions/` | Custom extensions |
| `skills/` | Custom skills |
| `prompts/` | Prompt templates |
| `themes/` | Custom themes |
| `sessions/` | Session history |

### Docker Configuration

The Docker entrypoint generates `models.json` automatically, connecting to your host Ollama instance:

```bash
# Default model
.\docker-run.ps1 -Model "qwen3.6:35b"

# Custom workspace
.\docker-run.ps1 -WorkspaceDir "C:\my-project" -Model "llama3.1:8b"
```

## CLI Reference

```bash
aegis [options] [@files...] [messages...]
```

### Modes

| Flag | Description |
|------|-------------|
| (default) | Interactive mode |
| `-p`, `--print` | Print response and exit |
| `--mode json` | Output all events as JSON lines |
| `--mode rpc` | RPC mode for process integration |

### Model Options

| Option | Description |
|--------|-------------|
| `--provider <name>` | Provider (anthropic, openai, google, etc.) |
| `--model <pattern>` | Model pattern or ID |
| `--api-key <key>` | API key (overrides env vars) |
| `--thinking <level>` | `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max` |

### Session Options

| Option | Description |
|--------|-------------|
| `-c`, `--continue` | Continue most recent session |
| `-r`, `--resume` | Browse and select session |
| `--session <path\|id>` | Use specific session file |
| `--no-session` | Ephemeral mode (don't save) |
| `--name <name>` | Set session display name |

### Examples

```bash
# Interactive with initial prompt
aegis "List all .ts files in src/"

# Non-interactive
aegis -p "Summarize this codebase"

# Different model
aegis --provider openai --model gpt-4o "Help me refactor"

# Read-only mode
aegis --tools read,grep,find,ls -p "Review the code"
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `AI_AGENT` | Set to `aegis` by the CLI entry point |
| `PI_CODING_AGENT` | Set to `true` by the CLI entry point |
| `AEGIS_CODING_AGENT_DIR` | Override config directory (default: `~/.aegis/agent`) |
| `PI_OFFLINE` | Disable startup network operations |
| `PI_SKIP_VERSION_CHECK` | Skip version update check |
| `PI_TELEMETRY` | Override install/update telemetry |

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Ctrl+C | Clear editor |
| Ctrl+C twice | Quit |
| Escape | Cancel/abort |
| Ctrl+L | Open model selector |
| Ctrl+O | Collapse/expand tool output |
| `/` | Trigger commands |

## Customization

### Extensions

TypeScript modules that extend aegis with custom tools, commands, and UI:

```typescript
export default function (aegis: ExtensionAPI) {
  aegis.registerTool({ name: "deploy", ... });
  aegis.registerCommand("stats", { ... });
}
```

Place in `~/.aegis/agent/extensions/` or `.aegis/extensions/`.

### Skills

On-demand capability packages:

```markdown
<!-- ~/.aegis/agent/skills/my-skill/SKILL.md -->
# My Skill
Use this skill when the user asks about X.
```

Place in `~/.aegis/agent/skills/` or `.aegis/skills/`.

### Themes

Built-in: `dark`, `light`. Hot-reload supported.

Place in `~/.aegis/agent/themes/` or `.aegis/themes/`.

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

MIT

## See Also

- [@earendil-works/pi-ai](https://www.npmjs.com/package/@earendil-works/pi-ai): Core LLM toolkit
- [@earendil-works/pi-agent-core](https://www.npmjs.com/package/@earendil-works/pi-agent-core): Agent framework
- [@earendil-works/pi-tui](https://www.npmjs.com/package/@earendil-works/pi-tui): Terminal UI components
