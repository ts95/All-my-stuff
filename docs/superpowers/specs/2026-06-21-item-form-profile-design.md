# Item Form Sheet & Profile Detail View Design

## Overview

Replace the current inline editing experience in `ItemDetailView` with two distinct screens: a **read-only profile-style detail view** for browsing items, and a **full-height modal form sheet** for adding or editing items. Photo capture (camera + photolibrary) is accessible from both views with loading indicators during image processing.

## Navigation and Screen Architecture

### Views
| View | Purpose | Presentation |
|------|---------|-------------|
| `ItemProfileView` | Read-only item profile with hero photo, formatted fields, category/location chips | Split-view right column (iPad/Mac) or push navigation (iPhone) |
| `ItemFormSheet` | Full-height modal form for creating or editing an item | `.sheet(isPresented:)` from "+" button or Edit toolbar item |

### Navigation Flow
- `ItemListView` → taps item → `ItemProfileView` (detail column or push)
- `ItemListView` → taps "+" → presents `ItemFormSheet` (create mode)
- `ItemProfileView` → taps Edit toolbar button → presents `ItemFormSheet` (edit mode)

### Swipe Actions
- Swiping an item row in `ItemListView` still reveals a Delete action, but now triggers a confirmation alert dialog before deleting.

## Item Profile Detail View (`ItemProfileView`)

Read-only display with profile-style layout:

1. **Hero photo section** — full-width large rounded image at top of view; placeholder icon + "No photo" label when empty
2. **Tap-to-capture** — tapping the hero photo area triggers `.cameraLibrary` presentation (combined camera + photolibrary picker); selected image is resized via `AssetStorage`, stored as `item.photo`
3. **Name and notes** — displayed as large styled text, not editable fields
4. **Categories and locations** — shown as pill-style chips rather than inline pickers
5. **Prices** — formatted currency display (or "Not set" when empty)
6. **Date purchased** — formatted date display

### Toolbar Items
- Edit button → presents `ItemFormSheet` in edit mode with current item
- Delete button → triggers confirmation alert, then deletes from model context and dismisses view

## Item Form Sheet (`ItemFormSheet`)

Full-height `.sheet` presentation with all fields editable in a single scrollable Form:

1. **Photo section** — thumbnail preview of current photo; `.cameraLibrary` picker button for camera or photolibrary selection; remove photo destructive button
2. **Name** — text field (required, validation prevents save if empty)
3. **Notes** — text editor with minimum height
4. **Categories** — existing `ItemCategoryPickerView` (add/remove from selection)
5. **Locations** — existing `ItemLocationPickerView` (add/remove from selection)
6. **Prices** — purchase price and estimated value numeric fields
7. **Date purchased** — date picker

### Save/Cancel Pattern
- Form sheet has toolbar with Cancel (dismiss, discard changes for create mode) and Done (save context, dismiss)
- Edit mode: changes persist via `@Bindable` bindings to the existing Item instance; Done calls `context.save()`
- Create mode: a fresh `Item(name: "")` is inserted into the model context before the sheet presents. During editing, all fields populate via `@Bindable` bindings to this Item instance. Done calls `context.save()` and dismisses; Cancel deletes the unsaved item first, then dismisses.

## Photo Capture Flow

Photo access exists on both views with identical capture pipeline:

### From `ItemFormSheet` (while adding/editing)
- Taps camera or photolibrary button in photo section
- Image returns, resized via `AssetStorage.resizeImageData()`, stored as `item.photo`
- Thumbnail preview updates

### From `ItemProfileView` (while browsing)
- Taps hero photo area to trigger `.cameraLibrary` presentation
- Same resize and save pipeline; hero image updates in place with loading indicator during processing

### Image Processing
- All captured images routed through existing `AssetStorage.resizeImageData()` for compression before storage
- Loading indicator: dimmed overlay with `ProgressView` on the affected photo area during resize operation

## Changes to Existing Views

### `ItemListView`
- Replace inline `@State var newItem = Item()` creation pattern in `ContentView` with sheet presentation of `ItemFormSheet`
- Swipe-delete action triggers confirmation alert before `modelContext.delete(item)`
- "+" navigation bar button presents `ItemFormSheet` in create mode

### `ItemDetailView` (renamed to `ItemProfileView`)
- Convert from editable Form to read-only profile layout with styled display of all fields
- Remove inline category/location pickers (replaced by chips)
- Move photo capture to tap-to-capture on hero image
- Add Edit and Delete toolbar items

### Unchanged Views
- `ItemCategoryPickerView`, `ItemLocationPickerView` — reused as-is inside `ItemFormSheet`
- `AssetStorage` — reused for photo resize operations
- Models unchanged (`Item`, `ItemCategory`, `ItemLocation`, `PriceState`)

## Loading Indicators

All async operations show visual feedback to the user:

- **Photo capture** (any view): overlay with `ProgressView` spins during image download and resize, fades out on completion
- **Form save**: Done button shows loading state while context saves, reverts to normal on completion
- Future network or cloud operations would use same pattern

## Testing Strategy

1. **`ItemFormSheetTests`** — verify create flow inserts item with correct fields; verify edit flow mutates existing item; verify cancel discards changes (create mode)
2. **`ItemProfileViewTests`** — verify all fields display correctly in read-only mode; verify no mutable binding exposure to form elements
3. **Swipe-delete confirm test** — verify alert presents before delete, and that cancelling alert prevents deletion
4. **Photo capture integration test** — mock camera/photolibrary return value, verify image stored and resized

## Dependencies

- iOS 17+ for `.cameraLibrary` (already supported by current target of iOS 26.5)
- Existing `PhotosPickerItem` for photolibrary access retained as fallback
- No new external dependencies; uses only SwiftUI, SwiftData UIKit APIs
