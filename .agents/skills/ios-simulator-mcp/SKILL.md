---
name: ios-simulator-mcp
description: Interact with the iOS Simulator via accessibility tree inspection, UI automation (tap, type, swipe), element search, screenshot, and app launch/install. Use when verifying UI behavior at runtime, inspecting accessibility labels, or performing QA on the simulator. NOT for code changes — use Xcode MCP for that.
---

# iOS Simulator Automation

Powered by `idb` (Facebook IDB) + `idb_companion`. The MCP server (`ios-simulator-mcp`) wraps these same tools, but the CLI is more reliable when MCP is not loaded.

## Prerequisites

- `idb-companion` installed: `brew install facebook/fb/idb-companion`
- `fb-idb` Python client installed: `pip3 install fb-idb` (may require `--break-system-packages` on Python 3.14+)
- Simulator booted and running

## Setup Workflow (Every Session)

1. **Boot simulator**: `xcrun simctl boot <udid>`
2. **Open Simulator GUI**: `open -a Simulator` — this makes the device window visible so the user can observe what you're doing. Do this before launching the app.
3. **Start companion**: `idb_companion --udid <udid> &` — wait ~6s for it to bind port 10882
4. **Verify companion**: `lsof -i :10882 | grep LISTEN` should show `idb_companion`
5. **All subsequent commands** use `idb --companion localhost:10882 ui <command> ...`

If port 10882 is in use by a stale companion: `kill $(lsof -ti :10882)` and restart.

## Building and Launching App

```bash
# Build for simulator
xcodebuild -project "path/to/Project.xcodeproj" -scheme "Scheme" \
  -destination 'platform=iOS Simulator,id=<udid>' build

# Install (required after erase or fresh build)
xcrun simctl install <udid> "/path/to/DerivedData/.../Build/Products/Debug-iphonesimulator/App.app"

# Launch
xcrun simctl launch <udid> com.bundle.identifier
```

## Core Commands

### Get accessibility tree
```bash
idb --companion localhost:10882 ui describe-all
```
Returns JSON array of elements with `AXLabel`, `type`, `role`, `frame` (x, y, width, height).

Filter labeled elements:
```bash
idb --companion localhost:10882 ui describe-all | python3 -c "
import sys,json
data=json.load(sys.stdin)
[print(e.get('AXLabel') or '(no label)', e['type'], e['frame']) for e in data if e.get('AXLabel')]
"
```

### Tap at coordinates
```bash
idb --companion localhost:10882 ui tap <x> <y>
```
Positional args, not flags. Center of a button at frame `{x:16, y:200, width:370, height:52}` → tap `201 226`.

### Type text
```bash
idb --companion localhost:10882 ui text "Hello World"
```
Requires the text field to already be focused. Tap the field first, wait 2s, then type.

### Swipe
```bash
idb --companion localhost:10882 ui swipe <x_start> <y_start> <x_end> <y_end>
```
Positional args. Navigate back from a pushed view: `swipe 5 400 380 400` (swipe right from left edge).

### Find element
```bash
idb --companion localhost:10882 ui describe-all | python3 -c "
import sys,json
data=json.load(sys.stdin)
[print(e.get('AXLabel') or '(no label)', e['type'], e['frame']) for e in data if 'Delete' in (e.get('AXLabel') or '')]
"
```

### Screenshot
```bash
xcrun simctl io <udid> screenshot /tmp/screenshot.png
```

## Navigation Patterns

| Action | Command |
|--------|---------|
| Go back from pushed view | `swipe 5 400 380 400` (swipe right from left edge) |
| Tap nav bar back button | `tap 30 90` (top-left corner) |
| Tap + in nav bar | `tap 370 80` (top-right corner) |
| Tap toolbar button | `tap 360 820` (bottom-right) |

## Common Gotchas

- **Destructive actions** (`ToolbarItem(placement: .destructiveAction)`) do NOT appear in the accessibility tree. They are triggered by tapping the top-right nav bar area, which opens a confirmation dialog. The dialog's buttons _do_ appear in the tree.
- **Keyboard may not appear** after tapping a TextField. If `ui text` fails, try tapping the field again and waiting longer.
- **`idb_companion` binary name** varies by install: `idb_companion` (homebrew) not `idb-companion`.
- **Companion stays alive** after target goes offline — kill and restart if switching simulators.
- **Python 3.14 compatibility**: `fb-idb` 1.1.7 may need `/opt/homebrew/lib/python3.14/site-packages/idb/cli/main.py` line 353 patched — replace `asyncio.get_event_loop()` with `asyncio.new_event_loop()` + `asyncio.set_event_loop(loop)`.

## When to Use

- Verifying UI renders correctly after a code change
- Checking accessibility labels are set properly
- Performing quick QA on a feature
- Debugging why a UI element isn't appearing

## When NOT to Use

- Reading source code — use Xcode MCP
- Building or testing — use Xcode MCP or CLI
- Modifying files — use Xcode MCP or generic tools
