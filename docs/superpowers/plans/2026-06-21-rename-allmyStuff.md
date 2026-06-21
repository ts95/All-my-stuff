# Rename Project to AllMyStuff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the project from "All my stuff" to "AllMyStuff" — updating directory names, file names, Xcode project file, source code identifiers, and documentation.

**Architecture:** Straightforward find-and-replace across filesystem paths, Xcode `.pbxproj`, Swift source files, and documentation. No behavioral changes — purely a naming refactor.

**Tech Stack:** Xcode MCP tools for project file edits, `git mv` for directory/file renames.

## Global Constraints

- Bundle identifier remains `com.tonisucic.All-my-stuff` (unchanged — this is an Apple ID tied identifier)
- iCloud container identifier remains `iCloud.com.tonisucic.All-my-stuff` (unchanged)
- Do NOT touch the `swift-dependencies/` SPM package directory
- All changes must result in a clean build with no compiler errors
- Commit after each logical group of changes

---

### Task 1: Rename source directories on filesystem

**Files:**
- Rename: `All my stuff/` → `AllMyStuff/`
- Rename: `All my stuffTests/` → `AllMyStuffTests/`
- Rename: `All my stuffUITests/` → `AllMyStuffUITests/`

**Interfaces:**
- Consumes: nothing (initial task)
- Produces: renamed directories for Task 2 to update in Xcode project

- [ ] **Step 1: Rename the main source directory**

```bash
git mv "All my stuff" "AllMyStuff"
```

- [ ] **Step 2: Rename the unit test directory**

```bash
git mv "All my stuffTests" "AllMyStuffTests"
```

- [ ] **Step 3: Rename the UI test directory**

```bash
git mv "All my stuffUITests" "AllMyStuffUITests"
```

- [ ] **Step 4: Verify all directories are renamed**

```bash
ls -la
```
Expected: `AllMyStuff/`, `AllMyStuffTests/`, `AllMyStuffUITests/` present; no `All my stuff*` directories remain.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: rename source directories to PascalCase"
```

---

### Task 2: Rename Swift source files

**Files:**
- Rename: `AllMyStuff/All_my_stuffApp.swift` → `AllMyStuff/AllMyStuffApp.swift`
- Rename: `AllMyStuff/All my stuff.entitlements` → `AllMyStuff/AllMyStuff.entitlements`
- Rename: `AllMyStuffTests/All_my_stuffTests.swift` → `AllMyStuffTests/AllMyStuffTests.swift`
- Rename: `AllMyStuffUITests/All_my_stuffUITests.swift` → `AllMyStuffUITests/AllMyStuffUITests.swift`
- Rename: `AllMyStuffUITests/All_my_stuffUITestsLaunchTests.swift` → `AllMyStuffUITests/AllMyStuffUITestsLaunchTests.swift`

**Interfaces:**
- Consumes: renamed directories from Task 1
- Produces: renamed files for Task 3 to update in Xcode project

- [ ] **Step 1: Rename App entry point file**

```bash
git mv "AllMyStuff/All_my_stuffApp.swift" "AllMyStuff/AllMyStuffApp.swift"
```

- [ ] **Step 2: Rename entitlements file**

```bash
git mv "AllMyStuff/All my stuff.entitlements" "AllMyStuff/AllMyStuff.entitlements"
```

- [ ] **Step 3: Rename unit test file**

```bash
git mv "AllMyStuffTests/All_my_stuffTests.swift" "AllMyStuffTests/AllMyStuffTests.swift"
```

- [ ] **Step 4: Rename UI test files**

```bash
git mv "AllMyStuffUITests/All_my_stuffUITests.swift" "AllMyStuffUITests/AllMyStuffUITests.swift"
git mv "AllMyStuffUITests/All_my_stuffUITestsLaunchTests.swift" "AllMyStuffUITests/AllMyStuffUITestsLaunchTests.swift"
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: rename Swift source files to PascalCase"
```

---

### Task 3: Update Swift source code identifiers

**Files:**
- Modify: `AllMyStuff/AllMyStuffApp.swift` — struct name `All_my_stuffApp` → `AllMyStuffApp`
- Modify: `AllMyStuff/Models/ItemCategory.swift` — header comment `//  All my stuff` → `//  AllMyStuff`
- Modify: `AllMyStuff/Models/ItemLocation.swift` — header comment `//  All my stuff` → `//  AllMyStuff`
- Modify: `AllMyStuffTests/AllMyStuffTests.swift` — struct name and `@testable import`
- Modify: `AllMyStuffTests/Integration/ItemCRUDTests.swift` — `@testable import`
- Modify: `AllMyStuffTests/Integration/ItemFormSheetModelTests.swift` — `@testable import`
- Modify: `AllMyStuffTests/Integration/ItemProfileTests.swift` — `@testable import`
- Modify: `AllMyStuffTests/Models/DataModelTests.swift` — `@testable import` and header comment
- Modify: `AllMyStuffTests/Services/StoreTests.swift` — `@testable import`
- Modify: `AllMyStuffTests/Views/ProfileViewSmokeTests.swift` — `@testable import`
- Modify: `AllMyStuffUITests/AllMyStuffUITests.swift` — class name and header comment
- Modify: `AllMyStuffUITests/AllMyStuffUITestsLaunchTests.swift` — class name and header comment

**Interfaces:**
- Consumes: renamed files from Task 2
- Produces: updated Swift identifiers for Task 4 (Xcode project)

- [ ] **Step 1: Update App entry point struct name**

In `AllMyStuff/AllMyStuffApp.swift`, replace:
```swift
struct All_my_stuffApp: App {
```
with:
```swift
struct AllMyStuffApp: App {
```

Also update the header comment from `//  All_my_stuffApp.swift` to `//  AllMyStuffApp.swift` and `//  All my stuff` to `//  AllMyStuff`.

- [ ] **Step 2: Update model file header comments**

In `AllMyStuff/Models/ItemCategory.swift` and `AllMyStuff/Models/ItemLocation.swift`, replace:
```
//  All my stuff
```
with:
```
//  AllMyStuff
```

- [ ] **Step 3: Update unit test file**

In `AllMyStuffTests/AllMyStuffTests.swift`:
- Replace `@testable import All_my_stuff` with `@testable import AllMyStuff`
- Replace `struct All_my_stuffTests` with `struct AllMyStuffTests`
- Update header comment from `//  All my stuffTests` to `//  AllMyStuffTests`

- [ ] **Step 4: Update all @testable import statements**

In each of these files, replace `@testable import All_my_stuff` with `@testable import AllMyStuff`:
- `AllMyStuffTests/Integration/ItemCRUDTests.swift`
- `AllMyStuffTests/Integration/ItemFormSheetModelTests.swift`
- `AllMyStuffTests/Integration/ItemProfileTests.swift`
- `AllMyStuffTests/Models/DataModelTests.swift`
- `AllMyStuffTests/Services/StoreTests.swift`
- `AllMyStuffTests/Views/ProfileViewSmokeTests.swift`

- [ ] **Step 5: Update UI test class names**

In `AllMyStuffUITests/AllMyStuffUITests.swift`:
- Replace `final class All_my_stuffUITests` with `final class AllMyStuffUITests`
- Update header comment from `//  All my stuffUITests` to `//  AllMyStuffUITests`

In `AllMyStuffUITests/AllMyStuffUITestsLaunchTests.swift`:
- Replace `final class All_my_stuffUITestsLaunchTests` with `final class AllMyStuffUITestsLaunchTests`
- Update header comment from `//  All my stuffUITests` to `//  AllMyStuffUITests`

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: update Swift identifiers from snake_case to PascalCase"
```

---

### Task 4: Update Xcode project file (project.pbxproj)

**Files:**
- Modify: `AllMyStuff.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: all filesystem and source changes from Tasks 1-3
- Produces: updated Xcode project referencing new names

This is the most complex task. The `.pbxproj` file contains 51 references to "All my stuff" that need updating. Use the Xcode MCP `xcode_XcodeUpdate` tool for all edits.

- [ ] **Step 1: Update CODE_SIGN_ENTITLEMENTS path**

Replace both occurrences of:
```
CODE_SIGN_ENTITLEMENTS = "All my stuff/All my stuff.entitlements"
```
with:
```
CODE_SIGN_ENTITLEMENTS = "AllMyStuff/AllMyStuff.entitlements"
```

- [ ] **Step 2: Update TEST_HOST path**

Replace both occurrences of:
```
TEST_HOST = "$(BUILT_PRODUCTS_DIR)/All my stuff.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/All my stuff"
```
with:
```
TEST_HOST = "$(BUILT_PRODUCTS_DIR)/AllMyStuff.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/AllMyStuff"
```

- [ ] **Step 3: Update TEST_TARGET_NAME**

Replace both occurrences of:
```
TEST_TARGET_NAME = "All my stuff"
```
with:
```
TEST_TARGET_NAME = "AllMyStuff"
```

- [ ] **Step 4: Update productName for main target**

Replace:
```
productName = "All my stuff";
```
with:
```
productName = "AllMyStuff";
```

- [ ] **Step 5: Update productName for test targets**

Replace:
```
productName = "All my stuffTests";
```
with:
```
productName = "AllMyStuffTests";
```

Replace:
```
productName = "All my stuffUITests";
```
with:
```
productName = "AllMyStuffUITests";
```

- [ ] **Step 6: Update product file references**

Replace:
```
path = "All my stuff.app"
```
with:
```
path = "AllMyStuff.app"
```

Replace:
```
path = "All my stuffTests.xctest"
```
with:
```
path = "AllMyStuffTests.xctest"
```

Replace:
```
path = "All my stuffUITests.xctest"
```
with:
```
path = "AllMyStuffUITests.xctest"
```

- [ ] **Step 7: Update group path references**

Replace:
```
path = "All my stuff";
```
with:
```
path = "AllMyStuff";
```

Replace:
```
path = "All my stuffTests";
```
with:
```
path = "AllMyStuffTests";
```

Replace:
```
path = "All my stuffUITests";
```
with:
```
path = "AllMyStuffUITests";
```

- [ ] **Step 8: Update target name references**

Replace:
```
name = "All my stuff";
```
with:
```
name = "AllMyStuff";
```

Replace:
```
name = "All my stuffTests";
```
with:
```
name = "AllMyStuffTests";
```

Replace:
```
name = "All my stuffUITests";
```
with:
```
name = "AllMyStuffUITests";
```

- [ ] **Step 9: Update remoteInfo references**

Replace both occurrences of:
```
remoteInfo = "All my stuff";
```
with:
```
remoteInfo = "AllMyStuff";
```

- [ ] **Step 10: Update all comment references in pbxproj**

All `/* All my stuff */` and `/* All my stuffTests */` and `/* All my stuffUITests */` comment strings throughout the file should be updated to their PascalCase equivalents. Also update all build configuration list comments like `/* Build configuration list for PBXNativeTarget "All my stuff" */`.

- [ ] **Step 11: Verify no remaining "All my stuff" references in pbxproj**

```bash
grep -c "All my stuff" "AllMyStuff.xcodeproj/project.pbxproj"
```
Expected: `0`

- [ ] **Step 12: Commit**

```bash
git add -A
git commit -m "refactor: update project.pbxproj references to PascalCase"
```

---

### Task 5: Rename Xcode project directory and Info.plist

**Files:**
- Rename: `All my stuff.xcodeproj/` → `AllMyStuff.xcodeproj/`
- Rename: `All-my-stuff-Info.plist` → `AllMyStuff-Info.plist`

**Interfaces:**
- Consumes: updated pbxproj from Task 4
- Produces: final filesystem structure

- [ ] **Step 1: Rename Xcode project directory**

```bash
git mv "All my stuff.xcodeproj" "AllMyStuff.xcodeproj"
```

- [ ] **Step 2: Rename Info.plist file**

```bash
git mv "All-my-stuff-Info.plist" "AllMyStuff-Info.plist"
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor: rename xcodeproj directory and Info.plist to PascalCase"
```

---

### Task 6: Update README.md

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: all renames complete
- Produces: updated documentation

- [ ] **Step 1: Update project structure tree in README**

Replace the project structure section to reflect new directory/file names:
- `All my stuff/` → `AllMyStuff/`
- `All_my_stuffTests/` → `AllMyStuffTests/`
- `All_my_stuffUITests/` → `AllMyStuffUITests/`
- `All_my_stuffApp.swift` → `AllMyStuffApp.swift`

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README project structure to PascalCase"
```

---

### Task 7: Build and verify

**Files:** None — verification only.

**Interfaces:**
- Consumes: all changes from Tasks 1-6
- Produces: verified working build

- [ ] **Step 1: Open Xcode project and build**

Use `xcode_XcodeListWindows` to confirm the project opens, then `xcode_BuildProject` on the active scheme.

Expected: Build succeeds with zero errors.

- [ ] **Step 2: Run tests**

Run the test suite to verify `@testable import AllMyStuff` resolves correctly in all test files.

Expected: All tests pass.

- [ ] **Step 3: Final git status check**

```bash
git status
```
Expected: Clean working tree (all changes committed).

- [ ] **Step 4: Push to remote**

```bash
git push
```
