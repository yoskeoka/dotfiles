---
name: google-workspace
description: "Read and write Google Workspace content (Docs, Sheets, Slides, Calendar, Gmail, Chat) via Gemini CLI. Use this skill whenever the user asks to read, summarize, edit, or create Google Docs, Sheets, Slides, Calendar events, Gmail messages, or Google Chat messages. Also triggers when the user provides a Google Docs/Sheets/Slides URL (docs.google.com, sheets.google.com, slides.google.com), mentions 'Google Doc', 'Google Sheet', 'Google Slide', 'Google Calendar', 'Gmail', 'Google Chat', or asks to interact with any Google Workspace service. Even if the user just pastes a Google Workspace URL without explicit instructions, activate this skill to read and process the content."
version: "0.1.0"
---

# Google Workspace via Gemini CLI

This skill enables Claude Code to read and write Google Workspace content by delegating to Gemini CLI with the google-workspace extension.

## Prerequisites

The following must be installed and configured on the user's machine before this skill can work:

1. **Gemini CLI** (v0.30+): `brew install gemini-cli` or `npm install -g @google/gemini-cli`
2. **Google Workspace Extension**: Install from [github.com/gemini-cli-extensions/workspace](https://github.com/gemini-cli-extensions/workspace) (usage guide: [gemini-cli-extensions.github.io/workspace](https://gemini-cli-extensions.github.io/workspace/))
3. **OAuth authentication**: The user must have run `gemini` interactively at least once to complete Google OAuth login

## Command Pattern

All interactions go through a single pattern:

```bash
gemini -p "<prompt>" -e google-workspace -y -m gemini-3.1-flash-lite-preview
```

Always use `dangerouslyDisableSandbox: true` on the Bash call because Gemini CLI cannot run inside the Claude Code sandbox.

### Required Flags

| Flag | Purpose | Why it matters |
|------|---------|----------------|
| `-p "<prompt>"` | Non-interactive (headless) mode | Without this, gemini enters interactive mode and hangs |
| `-e google-workspace` | Enable the Google Workspace extension | Extensions are NOT auto-loaded in `-p` mode; without it, tool calls fail |
| `-y` | Auto-approve all tool calls (YOLO mode) | Without it, gemini waits for interactive approval and hangs |
| `-m <model>` | Specify the model | Without it, defaults to Pro which may be rate-limited and hang |

### Available Models (as of writing)

| Model | Notes |
|-------|-------|
| `gemini-3.1-flash-lite-preview` | **Recommended default.** Lightweight, generous quota, sufficient for most read/write tasks |
| `gemini-2.5-flash-lite` | Stable lite alternative |
| `gemini-2.5-flash` | Higher quality, but strict rate limits — use when quality matters |
| `gemini-3-flash-preview` | Preview, higher capability but tighter quota |

Use `gemini-3.1-flash-lite-preview` by default. Switch to `gemini-2.5-flash` only when the user explicitly requests higher quality or the task requires complex reasoning.

## Supported Services and Tools

The google-workspace extension provides MCP tools for these services:

### Google Docs
- **Read**: `docs.getText` — Retrieves full text content by document ID
- **Write**: `docs.updateText` — Updates document content
- Document ID is extracted from URLs like `docs.google.com/document/d/{ID}/edit`

### Google Sheets
- **Read**: `sheets.getValues` — Reads cell ranges
- **Write**: `sheets.updateValues` — Updates cell ranges
- Spreadsheet ID from `sheets.google.com/spreadsheets/d/{ID}/edit`

### Google Slides
- **Read**: `slides.getText` — Retrieves text from all slides
- Presentation ID from `slides.google.com/presentation/d/{ID}/edit`

### Google Calendar
- **Read**: `calendar.listEvents` — Lists upcoming events
- **Write**: `calendar.createEvent` — Creates new events

### Gmail
- **Read**: `gmail.listMessages`, `gmail.getMessage` — List and read emails
- **Write**: `gmail.sendMessage` — Send emails

### Google Chat
- **Read**: `chat.listMessages` — List messages in a space
- **Write**: `chat.createMessage` — Send messages to a space

## Crafting the Prompt

The prompt passed to `-p` should be clear and specific about what Gemini should do. Gemini will activate the appropriate skill and call the MCP tools automatically.

### Reading Content

For reading, instruct Gemini to use the appropriate tool and specify the output format you need:

```bash
# Read a Google Doc - full content
gemini -p "Use docs.getText to read document ID {ID}. Return the full raw text from all tabs. Do not summarize." \
  -e google-workspace -y -m gemini-3.1-flash-lite-preview

# Read a Google Doc - summary only
gemini -p "Read Google Doc ID {ID} and provide a brief summary of each section." \
  -e google-workspace -y -m gemini-3.1-flash-lite-preview

# Read a specific sheet range
gemini -p "Use sheets.getValues to read range 'Sheet1!A1:D10' from spreadsheet ID {ID}." \
  -e google-workspace -y -m gemini-3.1-flash-lite-preview
```

### Writing Content

For writing, be explicit about what content to write and where:

```bash
# Append text to a Google Doc
gemini -p "Use docs.updateText to append the following text to document ID {ID}: ..." \
  -e google-workspace -y -m gemini-3.1-flash-lite-preview

# Update sheet cells
gemini -p "Use sheets.updateValues to write values to range 'Sheet1!A1:B3' in spreadsheet ID {ID}. Values: ..." \
  -e google-workspace -y -m gemini-3.1-flash-lite-preview
```

### Extracting Document IDs from URLs

When the user provides a Google Workspace URL, extract the document ID before constructing the gemini command:

| Service | URL pattern | ID location |
|---------|-------------|-------------|
| Docs | `docs.google.com/document/d/{ID}/edit` | Between `/d/` and `/edit` |
| Sheets | `docs.google.com/spreadsheets/d/{ID}/edit` | Between `/d/` and `/edit` |
| Slides | `docs.google.com/presentation/d/{ID}/edit` | Between `/d/` and `/edit` |

## Handling Output

Gemini's stdout contains the response. For large documents, the output may be saved to a persisted file by Claude Code. Key considerations:

- **Large output**: If you only need a summary, ask Gemini to summarize rather than returning full text. This saves context window space.
- **Structured data**: Ask Gemini to format output as JSON or markdown tables when you need to process it further.
- **Multi-tab documents**: Google Docs can have multiple tabs. Specify whether you want all tabs or a specific one.

## Error Handling

| Symptom | Cause | Fix |
|---------|-------|-----|
| Hangs with no output | Sandbox blocking network | Ensure `dangerouslyDisableSandbox: true` is set |
| "exhausted your capacity" + hang | Model rate limit, no fallback | Switch to `-m gemini-3.1-flash-lite-preview` or another available model |
| "activate_skill not found" | Missing `-e google-workspace` flag | Add `-e google-workspace` to the command |
| Hangs after "YOLO mode is enabled" | Model rate limit with long reset time | Try a different model (`gemini-2.5-flash-lite`, `gemini-3-flash-preview`) |
| Authentication error | OAuth token expired | User needs to run `gemini` interactively to re-authenticate |

## Important Notes

- **Always use `dangerouslyDisableSandbox: true`** on every gemini Bash call. Gemini CLI requires unrestricted network access for Google API authentication and communication.
- **Set reasonable timeouts**: Google Doc reads typically complete in 30-60 seconds. Set Bash timeout to 120000ms (2 min) for most operations.
- **Respect the user's quota**: Avoid unnecessary repeated calls. Cache/reuse content within the conversation when possible.
- **Write operations are real**: When writing to Google Workspace, changes take effect immediately. Confirm with the user before performing write operations.
