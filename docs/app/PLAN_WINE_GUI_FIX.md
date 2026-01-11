# Fix Wine GUI Display - Exact Whisky Implementation

## Problem
Wine processes execute but GUI windows remain invisible. After line-by-line comparison with Whisky, found **3 critical differences**.

---

## Root Cause Analysis

### 🔴 CRITICAL Issue #1: Task.detached Blocking
**Current Code (Workspace.swift:178-221):**
```swift
try await Task.detached(priority: .userInitiated) { [workspace] in
    // ... wine execution ...
}.value  // ← THIS DEFEATS Task.detached!
```

**Problem**:
- `.value` access **blocks** the caller until Task completes
- Defeats the entire purpose of Task.detached
- GUI windows can't appear because execution context is blocked

**Whisky Implementation (Program+Extensions.swift:36-46):**
```swift
Task.detached(priority: .userInitiated) {
    do {
        try await Wine.runProgram(...)
    } catch {
        await MainActor.run {
            self.showRunError(message: error.localizedDescription)
        }
    }
}
// NO .value - fire and forget!
```

### 🔴 CRITICAL Issue #2: Output Pipes Disabled
**Current Code (PodoSojuManager.swift:200-204):**
```swift
if !captureOutput {
    process.standardOutput = nil  // ← WRONG!
    process.standardError = nil   // ← WRONG!
}
```

**Problem**:
- Wine on macOS may require pipes for proper GUI initialization
- Setting to `nil` breaks this expectation

**Whisky Implementation (Process+Extensions.swift:42-43 + 60-74):**
```swift
let pipe = Pipe()
let errorPipe = Pipe()
standardOutput = pipe
standardError = errorPipe

// Then uses non-blocking readabilityHandler:
pipe.fileHandleForReading.readabilityHandler = { pipe in
    guard let line = pipe.nextLine() else { return }
    continuation.yield(.message(line))
}
```

**Whisky ALWAYS creates pipes**, even for GUI programs.

### 🟡 Important Issue #3: No wineserver Cleanup
**Current Code**: No pre-execution cleanup

**Whisky Implementation (Wine.swift:103-104):**
```swift
// Kill any existing wineserver to avoid version mismatch
try? await runWineserver(["-k"], bottle: bottle)
```

---

## Implementation Plan

### Step 1: Remove `.value` Access (CRITICAL)
**File**: `SojuKit/Sources/SojuKit/Models/Workspace.swift:178-221`

**Change**:
```swift
// Before:
try await Task.detached(priority: .userInitiated) { [workspace] in
    // ...
}.value  // ← Remove this

// After:
Task.detached(priority: .userInitiated) { [workspace] in
    // ...
}
// No await, no try, no .value - fire and forget
```

**Impact**: Execution becomes truly asynchronous. GUI windows can appear.

---

### Step 2: Always Use Pipes (Even for GUI)
**File**: `SojuKit/Sources/SojuKit/Managers/PodoSojuManager.swift`

**Option A - Simple Fix**:
Remove the `captureOutput` parameter entirely. Always create pipes:
```swift
// Remove lines 200-204:
if !captureOutput {
    process.standardOutput = nil
    process.standardError = nil
}

// Pipes are already created by runStream, just use them
```

**Option B - Keep Parameter But Still Use Pipes**:
```swift
// Keep pipes but ignore output in the stream consumer
if !captureOutput {
    // Pipes still created by runStream, but we ignore the output
    // in the for await _ loop
}
```

**Recommendation**: Option A (simpler, matches Whisky)

**File to update**:
- `PodoSojuManager.swift:177-209` (remove captureOutput logic)
- `Workspace.swift:202-207` (remove captureOutput: false parameter)

---

### Step 3: Add wineserver Cleanup
**File**: `SojuKit/Sources/SojuKit/Managers/PodoSojuManager.swift`

**Add new function**:
```swift
/// Kill any existing wineserver (like Whisky does before running programs)
public func killWineserver(workspace: Workspace) async throws {
    try validate()

    let process = Process()
    process.executableURL = wineserverBinary
    process.arguments = ["-k"]
    process.currentDirectoryURL = workspace.url
    process.environment = constructEnvironment(for: workspace)
    process.standardOutput = nil
    process.standardError = nil

    try process.run()
    process.waitUntilExit()
}
```

**Call before Wine execution** in `Workspace.swift:180`:
```swift
Task.detached(priority: .userInitiated) { [workspace] in
    do {
        let podoSoju = PodoSojuManager.shared

        // Add this:
        try? await podoSoju.killWineserver(workspace: workspace)

        // ... rest of wine execution
    }
}
```

---

### Step 4: Error Handling Adjustment
**File**: `Workspace.swift:210-220`

**Current**:
```swift
} catch {
    Logger.sojuKit.critical("💥 Fatal error: \(error.localizedDescription)", category: category)
    await MainActor.run {
        self.isRunning = false
        self.exitCode = 1
    }
    throw error  // ← Remove this
}
```

**Change to Whisky pattern**:
```swift
} catch {
    Logger.sojuKit.critical("💥 Fatal error: \(error.localizedDescription)", category: category)
    await MainActor.run {
        self.isRunning = false
        self.exitCode = 1
        // Could add showError UI here if needed
    }
    // Don't re-throw - Task.detached handles error locally
}
```

---

## Files to Modify

1. **SojuKit/Sources/SojuKit/Models/Workspace.swift**
   - Line 178: Remove `try await`, remove `.value`
   - Line 180: Add `try? await podoSoju.killWineserver(workspace: workspace)`
   - Line 202-207: Remove `captureOutput: false` parameter
   - Line 218: Remove `throw error`

2. **SojuKit/Sources/SojuKit/Managers/PodoSojuManager.swift**
   - Line 177-209: Remove `captureOutput` parameter and logic
   - Add new `killWineserver()` function
   - Line 197-209: Always use pipes (remove nil assignment)

---

## Expected Outcome

After these changes:
1. ✅ Wine executes in truly detached context
2. ✅ Pipes maintained for macOS compatibility
3. ✅ Clean wineserver state before execution
4. ✅ GUI windows should appear

This matches Whisky's implementation **exactly**.

---

## Testing Plan

1. Clean workspace: `rm -rf ~/Library/Containers/com.soju.app/Workspaces/*`
2. Create new workspace
3. Run NetFile_Setup.exe
4. GUI should appear immediately

If still fails, investigate:
- NSRunningApplication activation
- Window server connection (lsof -c wine)
- Process hierarchy (pstree)

---

## Priority

**CRITICAL - ALL THREE STEPS REQUIRED**

Step 1 is most critical (.value blocking), but Steps 2 and 3 are also necessary for full Whisky parity.
