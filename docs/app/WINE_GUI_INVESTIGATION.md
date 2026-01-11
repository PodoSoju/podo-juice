# Wine GUI Display Investigation

**Date**: 2026-01-08
**Status**: 🔴 In Progress - GUI windows not visible
**Branch**: `feature/improve-installer-detection`

## Problem Summary

Wine processes execute successfully but GUI windows remain invisible when launched from Soju.app.

### Symptoms
- ✅ Wine processes start successfully
- ✅ Wine binaries execute
- ✅ No error messages
- ❌ GUI windows not visible on screen
- ❌ Windows remain `visible: false` in System Events

### Test Results

| Test Case | Result | Notes |
|-----------|--------|-------|
| Terminal execution | ✅ Works | GUI appears normally |
| Whisky execution | ✅ Works | GUI appears normally |
| Soju execution | ❌ Fails | Processes run but GUI invisible |
| `winecfg` from Soju | ❌ Fails | Configuration window not visible |

---

## Investigation Timeline

### Phase 1: Path & Sandbox Issues ✅ RESOLVED
**Problem**: PodoSoju Wine binary not accessible
**Solution**:
- Removed sandbox (`com.apple.security.app-sandbox`)
- Fixed containerized path to real path
- Wine now accessible and executable

**Commits**:
- `7ebe01f` - Remove sandbox for Wine compatibility
- `55fc95a` - Add Wine prefix initialization

### Phase 2: Wine Prefix Initialization ✅ RESOLVED
**Problem**: `wineboot --init` blocked indefinitely
**Solution**:
- Changed from stream-based output capture to polling
- Check `drive_c` directory creation with timeout
- Follow Whisky's detached execution pattern

**Commits**:
- `55fc95a` - Add wineboot with polling

### Phase 3: Process Output Blocking ✅ RESOLVED
**Problem**: `for await` loop waiting for output from `wine start`
**Solution**:
- Use empty loop `{ }` pattern from Whisky
- Don't wait for stdout/stderr from background process
- Process completes quickly without blocking UI

**Commits**:
- `bd91121` - Use empty loop pattern

### Phase 4: Pipe Blocking GUI 🟡 PARTIALLY RESOLVED
**Problem**: stdout/stderr pipes prevent GUI windows from appearing
**Solution**:
- Added `captureOutput` parameter to `runWine()`
- Set `process.standardOutput = nil` for GUI programs
- Matches wineboot execution pattern

**Commits**:
- `46a2988` - Add captureOutput parameter

**Result**: Still not working - requires further investigation

---

## Current Status

### What Works ✅
1. **Wine Execution**
   ```bash
   Process: /Users/max/Library/Application Support/com.soju.app/Libraries/PodoSoju/bin/wine
   Args: start /unix /Users/max/Downloads/NetFile_Setup.exe
   Status: Running (PID visible in ps aux)
   ```

2. **Environment Setup**
   ```bash
   WINEPREFIX: /Users/max/Library/Containers/com.soju.app/Workspaces/[UUID]
   WINEDEBUG: warn+all (for installers)
   TMPDIR: Container-specific temp directory
   ```

3. **Process Visibility**
   ```bash
   $ ps aux | grep NetFile
   max  78366  Z:\Users\max\Downloads\NetFile_Setup.exe   # Running
   ```

### What Doesn't Work ❌
1. **GUI Window Display**
   ```bash
   $ osascript -e 'tell application "System Events" to get {name, visible} of every process whose name contains "wine"'
   # Result: wine, false
   # All Wine processes report visible: false
   ```

2. **Window Enumeration**
   ```bash
   $ osascript -e 'tell application "System Events" to get name of every window of every process'
   # No Wine windows found
   ```

---

## Key Differences: Terminal vs Soju

### Terminal Execution (Works ✅)
```bash
WINEPREFIX="..." \
~/Library/Application Support/com.soju.app/Libraries/PodoSoju/bin/wine \
start /unix ~/Downloads/NetFile_Setup.exe
```
- Parent process: Terminal or shell
- stdin/stdout/stderr: Terminal or file
- Result: GUI appears

### Soju Execution (Fails ❌)
```swift
let process = Process()
process.executableURL = wineBinary
process.arguments = ["start", "/unix", path]
process.standardOutput = nil  // Disabled
process.standardError = nil   // Disabled
try process.run()
```
- Parent process: Soju.app
- stdin/stdout/stderr: nil (not captured)
- Result: GUI invisible

### Whisky Execution (Works ✅)
```swift
Task.detached(priority: .userInitiated) {
    try await Wine.runProgram(at: url, args: args, bottle: bottle)
}
```
- Parent process: Whisky.app
- Execution context: Detached task
- Result: GUI appears

---

## Hypotheses

### H1: Process Visibility Inheritance ⚠️ LIKELY
**Theory**: Child processes inherit visibility from parent app
**Evidence**:
- Terminal is visible → Wine visible
- Whisky is visible → Wine visible
- Soju is visible BUT Wine is not

**Possible Causes**:
1. Process activation policy
2. NSRunningApplication registration
3. Window server connection

### H2: Task Execution Context 🤔 POSSIBLE
**Theory**: Task.detached creates independent execution context
**Evidence**:
- Whisky uses `Task.detached(priority: .userInitiated)`
- Soju uses `await` in UI context
- Different thread may affect window server access

**Next Step**: Try Task.detached in Soju

### H3: LSUIElement or App Type 🤔 UNLIKELY
**Theory**: App bundle configuration affects child visibility
**Evidence**:
- Both Whisky and Soju have LSUIElement: NOT SET
- Both are regular .app bundles
- No relevant differences in Info.plist

**Conclusion**: Probably not the issue

### H4: Wine Mac Driver Issue 🤔 UNLIKELY
**Theory**: Wine Mac driver not initializing properly
**Evidence**:
- Terminal execution works (same Wine binary)
- `drive_c` structure is complete
- Registry files exist

**Conclusion**: Driver is working, but visibility is blocked

---

## Code References

### PodoSojuManager.swift:178-209
```swift
public func runWine(
    args: [String],
    workspace: Workspace,
    additionalEnv: [String: String] = [:],
    captureOutput: Bool = true  // NEW: Control output capture
) throws -> AsyncStream<ProcessOutput> {
    // ...
    if !captureOutput {
        process.standardOutput = nil
        process.standardError = nil
        Logger.sojuKit.info("🎨 GUI mode: output capture disabled")
    }
    // ...
}
```

### Workspace.swift:196-201
```swift
for await _ in try podoSoju.runWine(
    args: wineArgs,
    workspace: workspace,
    additionalEnv: additionalEnv,
    captureOutput: false  // Disable for GUI
) { }
```

### Whisky Pattern (WhiskyKit/Wine.swift:110-114)
```swift
for await _ in try Self.runWineProcess(
    name: url.lastPathComponent,
    args: ["start", "/unix", url.path] + args,
    bottle: bottle
) { }  // Empty loop, just wait for completion
```

---

## Next Steps

### Priority 1: Task Execution Context
- [ ] Modify Workspace.swift to use `Task.detached`
- [ ] Test if detached execution makes Wine visible
- [ ] Compare thread IDs and process hierarchy

### Priority 2: NSRunningApplication
- [ ] Investigate NSRunningApplication.activate()
- [ ] Check if explicit activation needed
- [ ] Test NSWorkspace.shared.launchApplication()

### Priority 3: Process Hierarchy Investigation
- [ ] Use `pstree` to compare process trees
- [ ] Check parent-child relationship differences
- [ ] Investigate window server connections with `lsof`

### Priority 4: Wine Debug Output
- [ ] Enable full Wine debug: `WINEDEBUG=+all`
- [ ] Check Mac driver initialization logs
- [ ] Look for visibility-related errors

---

## References

### Whisky Source Code
- `Wine.swift:100-115` - runProgram implementation
- `Program+Extensions.swift:32-47` - runInWine with Task.detached
- No special activation or visibility handling

### Apple Documentation
- [Process](https://developer.apple.com/documentation/foundation/process)
- [NSRunningApplication](https://developer.apple.com/documentation/appkit/nsrunningapplication)
- [Window Server](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/OSX_Technology_Overview/CoreServicesLayer/CoreServicesLayer.html)

### Related Issues
- macOS sandbox prevents `/tmp` access → RESOLVED
- Wine prefix initialization hangs → RESOLVED
- Process output blocking → RESOLVED
- GUI window visibility → IN PROGRESS

---

## Environment

### System
- macOS: Darwin 24.6.0
- Soju: Debug build from Xcode
- PodoSoju: Wine 9.x (from Whisky)

### Paths
```
PodoSoju Root: ~/Library/Application Support/com.soju.app/Libraries/PodoSoju
Wine Binary: .../PodoSoju/bin/wine
Workspace: ~/Library/Containers/com.soju.app/Workspaces/[UUID]
```

### Process Tree (Expected)
```
Soju.app (PID 12345)
  └─ wine (PID 12346)
      └─ wineserver (PID 12347)
          └─ NetFile_Setup.exe (PID 12348)  ← GUI should be visible here
```

---

## Conclusion

We've successfully resolved path, sandbox, and blocking issues. Wine executes perfectly, but GUI windows remain invisible. The most likely cause is process visibility inheritance or execution context. The next step is to implement Whisky's `Task.detached` pattern and investigate NSRunningApplication activation.

**Bottom Line**: We're 90% there - Wine works, just need to make it visible! 🎯
