# AutoHotkey v1.1 to v2 Migration Plan

## Context

This repo contains ~170 AHK v1.1 files (~26K lines): a main script with shared libraries/classes, 30+ program-specific hotkey scripts, and 40+ standalone utilities. The dependency chain flows bottom-up: base classes -> external libs -> static config -> libs -> classes -> program utils -> hotkey scripts -> entry points. Migration must follow this order since everything `#Include`s `common.ahk`.

Your `admin/ahk2.todo` documents the v1->v2 language changes comprehensively. This plan focuses on *execution order* and *architectural decisions* rather than re-listing those changes.

---

## Phase 0: Setup

- Create a `v2-migration` git branch
- Install AHK v2 alongside v1 (both can coexist)
- **Retire these scripts** (delete or move to an `archive/` folder — don't spend time converting them):
  - `source/program/internetExplorer.ahk` + `source/common/program/internetExplorer.ahk`
  - `source/program/epicStudio.ahk` + `source/common/program/epicStudio.ahk`
  - `source/program/hyperspace.ahk` + `source/common/program/hyperspace.ahk`
  - `source/common/program/mBuilder.ahk`
  - `source/common/external/commandFunctions.ahk` (redundant in v2 — but still need a shim during migration, see Phase 1A)
  - `source/program/tortoise.ahk`
  - `source/program/visualStudio.ahk` + `source/common/program/visualStudio.ahk`
  - `source/program/wilma.ahk`
  - `source/standalone/updateNotepadPPSupport/` (entire subfolder)
  - `source/standalone/fixVDIDisplaySettings.ahk`
  - `source/standalone/generateHyperdriveEnvironments.ahk`
  - `source/standalone/pullAllRepos.ahk`
  - `source/standalone/transactionDump.ahk`
  - `source/standalone/transactionDumpAllCurrent.ahk`
  - `source/standalone/triggerOutlookQuickStep.ahk`
- **Update `#Include` references**: Remove retired scripts from `source/common/common.ahk` and `source/main.ahk`
- Create a minimal test script that includes `common.ahk` and exercises core operations (string methods, array methods, selector, toast) — this becomes the canary for each phase

**Effort: 1-2 days**

---

## Phase 1: Foundation — Base Classes (HIGHEST RISK)

Everything depends on these. Get them wrong and nothing else works.

### 1A. Handle `commandFunctions.ahk` callers

This file is retired (v2 commands ARE functions), but its wrapper signatures don't always match v2 builtins. Before deleting, audit all call sites that go through it:

- `WinGet(subCmd, ...)` must be split: `WinGetID()`, `WinGetMinMax()`, `WinGetStyle()`, etc. — every call site needs manual routing
- `SysGet(subCmd, ...)` similarly splits into `MonitorGet()`, `MonitorGetWorkArea()`, `MonitorGetCount()`, etc.
- `InputBox()` now returns `{Result, Value}` object
- `MsgBox` now returns button name string (no more `IfMsgBox`)

**Strategy**: Create a temporary v2 shim mapping old signatures to v2 builtins, then eliminate call sites incrementally. Delete the shim when all callers are updated.

### 1B. Rewrite `stringBase.ahk` (681 lines)

**v1**: `"".base.base := StringBase` (common.ahk:16)
**v2**: Define methods on `String.Prototype`

Key issues:
- `IfIs(this, "alpha")` etc. → `IsAlpha(this)`, `IsNumber(this)`, `IsDigit(this)`
- `.length()` method — v2 strings don't have a built-in `.Length`. Rather than defining a wrapper, replace all `str.length()` call sites with `StrLen(str)`.
- `ByRef` → `&` (3 occurrences)
- RegExMatch output mode changes (O mode now mandatory)

### 1C. Rewrite `arrayBase.ahk` (160 lines)

**v1**: Redefine `Array()` globally to set `params.base := ArrayBase`
**v2**: Define methods on `Array.Prototype`

Key issues:
- **`.length()` method conflicts with v2's built-in `Array.Length` property.** The original `.length()` method unified arrays, objects, and strings under one API. In v2 these diverge: Array has `.Length`, Map has `.Count`, and strings use `StrLen()`. **Replace each call site with the correct v2 built-in for its type.** No compatibility wrapper — use native idioms. This requires knowing the type at each call site, but the codebase is well-typed enough to determine this.
- `.clear()` uses `.minIndex()` which no longer exists → replace with `this.Length := 0`
- `.last()` calls `this.length()` → change to `this[this.Length]`
- `ByRef` → `&` (2 occurrences in `next()`/`previous()`)

### 1D. Rewrite `objectBase.ahk` (63 lines) — KEY ARCHITECTURAL DECISION

**v1**: `Object()` served as both plain object AND associative array. `{"A":1, "B":2}` iterates with `For key,value`.
**v2**: `Object` and `Map` are SEPARATE types. `{}` creates an Object (properties), `Map()` creates an associative container.

`ObjectBase` methods (`.contains()`, `.mergeFromObject()`, `.toKeysArray()`, `.toValuesArray()`) use `For key,value in this` — this is Map-style iteration.

**Decision needed**: ObjectBase should migrate to `Map.Prototype`, and all `{}` associative-array literals throughout the codebase must become `Map()` calls. This is a codebase-wide change that touches every file creating key-value pairs with `{}`.

### 1E. Update `dataLib.ahk`

- `DataLib.isArray()` checks `value.__Class = "ArrayBase"` → `value is Array`
- `DataLib.isObject()` checks `value.__Class = "ObjectBase"` → `value is Map`
- `convertPseudoArrayToArray()` / `rebaseVariadicAry()` — likely removable since pseudo-arrays are gone in v2
- `isNullOrEmpty()` — `.count()` becomes `.Length` for Arrays, `.Count` for Maps

### Phase 1 verification
Run the test harness under AHK v2: create strings (call `.contains()`, `.split()`, `.length()`), arrays (`.join()`, `.first()`, `.last()`), Maps (`.contains()`, `.mergeFromObject()`).

**Effort: 5-8 days**

---

## Phase 2: External Libraries

### 2A. Replace `VA.ahk` (915 lines)

A known v2 port exists in the AHK community. Drop it in and verify volume control works.

### 2B. Replace `HTTPRequest.ahk` (995 lines)

Only called from `phoneLib.ahk` (1 call site). Replace with a ~30-line wrapper around `ComObject("WinHttp.WinHttpRequest.5.1")` or find a v2 HTTP library.

**Effort: 3-5 days**

---

## Phase 3: Static Config & Infrastructure

Files: `common.ahk` header, `config.ahk`, `enums.ahk`, `titleMatchMode.ahk`, `scriptTrayInfo.ahk`, `commonHotkeys.ahk`, `debug.ahk`, `windowPositions.ahk`, `windowActions.ahk`, `tempSettings.ahk`

Key changes:
- `common.ahk`: Remove `#NoEnv`, `SendMode, Input`, base-class-override region. Change `#SingleInstance, Force` → `#SingleInstance`
- `scriptTrayInfo.ahk`: `Menu, Tray, ...` → `TraySetIcon()`, `A_IconTip`, Menu object
- `commonHotkeys.ahk` (267 lines, HIGH complexity): Label references in `Hotkey`/`SetTimer` → function references. `Suspend, Permit` → `#SuspendExempt`. `IsFunc()`/`IsLabel()` → direct references
- `tempSettings.ahk`: `A_DetectHiddenWindows` now returns `1`/`0` not `"On"`/`"Off"` — callers that compare against `"On"` need updating
- `config.ahk`: `IniRead()` now throws on missing keys — add default params or try/catch

**Effort: 3-4 days**

---

## Phase 4: Library Functions

17 library files (~4,500 lines). Mostly mechanical after Phases 1-3, with two exceptions:

**High-complexity:**
- `guiLib.ahk`: Remove `createDynamicGlobal()`/`getDynamicGlobal()` entirely — v2 GUI controls are objects, no global variables needed. `getLabelSizeForText()` needs rewrite around v2 Gui object. Defer full rewrite to Phase 5.
- `windowLib.ahk`: `WinGet()` sub-command splitting (10 calls), `WinGetTitle()`/`WinActivate` signature changes
- `monitorLib.ahk`: `SysGet()` sub-command splitting (7 calls)
- `clipboardLib.ahk`: `Clipboard` → `A_Clipboard` (34 occurrences across 9 files), `ClipboardAll` → `ClipboardAll()`, ErrorLevel → return values

**Mechanical (apply patterns from ahk2.todo):**
- `epicLib.ahk`, `stringLib.ahk`, `fileLib.ahk`, `microsoftLib.ahk`, `mouseLib.ahk`, `runLib.ahk`, `hotkeyLib.ahk`, `searchLib.ahk`, `selectLib.ahk`, `dateTimeLib.ahk`, `phoneLib.ahk`, `ahkCodeLib.ahk`

**Effort: 4-6 days**

---

## Phase 5: GUI Subsystem Rewrite (SECOND HIGHEST RISK)

6 files, 65+ `Gui,` commands — complete API rewrite required.

**Core pattern change:**
```
; v1
Gui, New, +HWNDguiId +AlwaysOnTop
Gui, Font, s12, Segoe UI
Gui, Add, Text, vMyLabel, Hello
Gui, Show, w300 h200
GuiControl, , MyLabel, Updated text

; v2
myGui := Gui("+AlwaysOnTop")
myGui.SetFont("s12", "Segoe UI")
labelCtrl := myGui.Add("Text", , "Hello")
myGui.Show("w300 h200")
labelCtrl.Text := "Updated text"
```

### Order (by dependency):
1. **`guiLib.ahk`** — Foundation. Gut and rebuild around v2 Gui objects.
2. **`toast.ahk`** (485 lines, 15 Gui commands) — Store `Gui` object + `GuiCtrl` objects directly instead of `guiId` HWND + `labelVarName` dynamic global. Eliminates need for `guiLib.createDynamicGlobal()`.
3. **`flexTable.ahk`** — Used by selectorGui. Convert `Gui, Add, Text` to `guiObj.Add("Text", ...)`.
4. **`selectorGui.ahk`** (413 lines, most complex) — `+Label` prefix → `.OnEvent()` calls. `g`-label pattern → `.OnEvent("Change", handler)`. `Gui, Submit` → `gui.Submit()` returning Map. `A_Gui`/`A_GuiControl` removed → parameters in event handlers.
5. **`textPopup.ahk`** — Same Gui object pattern as toast.
6. **`colorPicker.ahk`** (standalone) — Global GUI vars → object references. `PixelGetColor` now returns RGB not BGR.

**Effort: 6-10 days**

---

## Phase 6: Classes

27 class files (~4,500 lines). Mostly mechanical after foundations are solid.

- **ActionObject hierarchy** (9 files): `new` → direct call, `ByRef` → `&`, `MsgBox`/`IfMsgBox` → return value
- **Selector system** (selector.ahk, selectorChoice.ahk, tableList.ahk, tableListMod.ahk): `Loop, Parse` → `Loop Parse`, Map awareness for `For key,value`
- **Remaining classes**: visualWindow, textTable, debugTable, duration, epicRecord, formattedList, mousePosition, program, progressToast, relativeDate, relativeTime, windowInfo — all mechanical

**Effort: 3-5 days**

---

## Phase 7: Program Utilities

20+ files in `source/common/program/`. All follow the same pattern: static class methods using base-class methods on strings/arrays/Maps. Once Phases 1-6 are done, these are straightforward mechanical conversions.

Largest (after retirements): outlook.ahk (394 lines), mSnippets.ahk (356 lines), explorer.ahk (341 lines), chrome.ahk (304 lines).

**Effort: 3-4 days**

---

## Phase 8: Hotkey Scripts

### 8A. `main.ahk`
- `SetWorkingDir, %A_ScriptDir%` → `A_WorkingDir := A_ScriptDir`
- `DetectHiddenWindows, On` → `A_DetectHiddenWindows := true`
- `SetCapsLockState, AlwaysOff` → `SetCapsLockState("AlwaysOff")`
- All `Set*` commands → function calls
- `#Include` paths: v2 defaults to relative-to-current-file — verify `%A_ScriptDir%\general\` still works

### 8B. General hotkeys (9 files) + Program hotkeys (30 files)
- `#If expression` → `#HotIf expression` (137 occurrences across 37 files)
- Multi-line hotkeys with `return` → braces: `hotkey:: { ... }`
- Command syntax in hotkey bodies → function syntax

**Effort: 3-5 days**

---

## Phase 9: Standalone & Sub Scripts

### Sub scripts (2 files)
- `vimBindings.ahk`: `SetTimer` with label → function reference, `#If` → `#HotIf`
- `windowMoverSizer.ahk`: Mostly mechanical

### Standalone scripts (~35 active)
Each includes `<includeCommon>` so they inherit common changes. Priority:
1. Frequently used: `timer.ahk`, `runProgram.ahk`, `activateProgram.ahk`, `sendMediaKey.ahk`
2. Dev tools: `compileEpicStudioRegex.ahk`, `findProjectInSolutionsFolder.ahk`
3. GUI-based: `colorPicker.ahk` (done in Phase 5), `iconTester.ahk`
4. The rest

**Effort: 3-5 days**

---

## Phase 10: Integration & Polish

- **CoordMode audit**: v2 default changes from `"Window"` to `"Client"`. Audit all `MouseMove`, `MouseClick`, `PixelGetColor` usage in scripts that don't explicitly set CoordMode.
- **On/Off → 1/0 audit**: `A_DetectHiddenWindows` etc. now return integers. Check all comparisons.
- **`#Include` path resolution**: Verify `%A_LineFile%\..` and `%A_ScriptDir%\` patterns still work in v2.
- **Error handling**: Add `try/catch` around operations that now throw instead of setting ErrorLevel (file ops, ini ops, window functions).
- **Update `firstSetup.ahk`**: Installation script must produce valid v2 syntax.

**Effort: 2-3 days**

---

## What Can Be Automated

### Find-and-replace (scriptable):
- `#If` → `#HotIf` (simple)
- `new ClassName(` → `ClassName(` (simple)
- `ByRef param` → `&param` (simple — but callers also need `&` prefix)
- Remove `#NoEnv`, `SendMode, Input` lines
- `#SingleInstance, Force` → `#SingleInstance`
- `Clipboard` → `A_Clipboard` (careful to avoid `ClipboardAll`, `ClipboardLib`)
- `Loop, Parse` → `Loop Parse`
- `Loop, Files` → `Loop Files`

### Needs manual review:
- Command-to-function syntax (671 occurrences — each command has unique parameter mapping)
- `%var%` → direct references (context-dependent)
- `WinGet(subCmd)`/`SysGet(subCmd)` dispatch splitting
- `MsgBox` + `IfMsgBox` → return value capture
- `{}` associative arrays → `Map()` (every usage must be audited)

### Fully manual (architectural):
- Base class prototype system (Phase 1B-1D)
- GUI subsystem (Phase 5)
- `commonHotkeys.ahk` label/Suspend patterns
- Object → Map split decision and codebase-wide application

---

## Effort Summary

| Phase | Description | Risk | Est. Days |
|-------|-------------|------|-----------|
| 0 | Setup | Low | 1-2 |
| 1 | Base classes + commandFunctions | **Critical** | 5-8 |
| 2 | External libraries | Medium | 3-5 |
| 3 | Static config/infrastructure | Medium | 3-4 |
| 4 | Library functions | Medium | 4-6 |
| 5 | GUI subsystem | **High** | 6-10 |
| 6 | Classes | Low-Medium | 3-5 |
| 7 | Program utilities | Low | 3-4 |
| 8 | Hotkey scripts + main.ahk | Low | 3-5 |
| 9 | Standalone/sub scripts | Low | 3-5 |
| 10 | Integration/polish | Medium | 2-3 |
| **Total** | | | **36-57 days** |

---

## Verification Strategy

Test after each phase — don't wait until the end:
1. **After Phase 1**: Test harness exercises string/array/Map methods under v2
2. **After Phase 2**: Volume control and phone features work
3. **After Phase 3-4**: `common.ahk` loads without errors under v2
4. **After Phase 5**: Toast, Selector, TextPopup work as standalone tests
5. **After Phase 6-7**: Full `common.ahk` loads. Selector-based flows work end-to-end
6. **After Phase 8**: Full `main.ahk` loads. Test hotkeys per-script
7. **After Phase 9**: Each standalone script runs under v2

Each phase should be committed separately for easy rollback.

---

## Critical Files (in migration order)

1. `source/common/common.ahk` — Include hub + base class setup
2. `source/common/external/commandFunctions.ahk` — Drop/shim
3. `source/common/base/stringBase.ahk` — 681 lines, used on every string
4. `source/common/base/arrayBase.ahk` — 160 lines, used on every array
5. `source/common/base/objectBase.ahk` — 63 lines, drives Object→Map decision
6. `source/common/lib/dataLib.ahk` — Type-checking functions
7. `source/common/static/commonHotkeys.ahk` — Complex label/Suspend rewrite
8. `source/common/class/selectorGui.ahk` — Most complex GUI file
9. `source/common/class/toast.ahk` — Second most complex GUI, used everywhere
10. `source/common/lib/guiLib.ahk` — Dynamic globals must be eliminated
