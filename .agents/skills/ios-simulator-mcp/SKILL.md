---
name: ios-simulator-mcp
description: Interact with the iOS Simulator via accessibility tree inspection, UI automation (tap, type, swipe), element search, screenshot, and app launch/install. Use when verifying UI behavior at runtime, inspecting accessibility labels, or performing QA on the simulator. NOT for code changes — use Xcode MCP for that.
---

# iOS Simulator MCP

MCP server: `ios-simulator-mcp` (joshuayoes/ios-simulator-mcp)
Provides structured accessibility data and UI automation for the booted iOS Simulator.

## Prerequisites

- `idb-companion` installed: `brew install facebook/fb/idb-companion`
- `fb-idb` Python client installed: `pip3 install fb-idb` (may require `--break-system-packages` on Python 3.14+)
- Simulator booted and running

## Tools

### `ui_describe_all`
Returns the full accessibility tree of the current screen as JSON. Use to inspect what's on screen without vision.

### `ui_find_element`
Search the accessibility tree by label or unique ID. Returns matching elements with type, frame, and attributes.
- `search`: array of strings to match against `AXLabel` or `AXUniqueId`
- `type`: filter by element type (e.g. "Button", "StaticText")
- `matchMode`: "substring" (default) or "exact"
- `caseSensitive`: default false

### `ui_describe_point`
Returns the accessibility element at given x,y coordinates.

### `ui_tap`
Tap at x,y coordinates on the simulator screen.

### `ui_type`
Input text into the focused field.

### `ui_swipe`
Swipe from (x_start, y_start) to (x_end, y_end).

### `launch_app`
Launch an app by bundle identifier.

### `screenshot`
Take a screenshot and save to file.

### `ui_view`
Get a compressed screenshot as base64 image.

## Workflow

1. **Inspect screen**: `ui_describe_all` to see what's visible
2. **Find element**: `ui_find_element` with search terms to locate buttons, text fields, etc.
3. **Interact**: `ui_tap`, `ui_type`, `ui_swipe` to perform actions
4. **Verify**: `ui_describe_all` again to confirm state changed

## When to Use

- Verifying UI renders correctly after a code change
- Checking accessibility labels are set properly
- Performing quick QA on a feature
- Debugging why a UI element isn't appearing

## When NOT to Use

- Reading source code — use Xcode MCP
- Building or testing — use Xcode MCP or CLI
- Modifying files — use Xcode MCP or generic tools
