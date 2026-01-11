# Soju 앱 재설계: Whisky 패턴 기반 Grid-Based UI

## 목표
Whisky 앱의 UI 패턴을 참고하여 Soju를 중앙 정렬 그리드 기반 워크스페이스/바로가기 시스템으로 재설계

## 요구사항

### 1. 워크스페이스 선택 화면
- ✅ 중앙 정렬 그리드 레이아웃 (창 너비에 따라 자동 2-3열)
- ✅ 더블클릭으로 워크스페이스 진입
- ✅ 우측 하단에 + 버튼 (워크스페이스 생성)
- ✅ 드래그로 순서만 변경 (위치는 자동 정렬)

### 2. 워크스페이스 내부 (바로가기 화면)
- ✅ 중앙 정렬 그리드 레이아웃 (워크스페이스와 동일한 패턴)
- ✅ 바로가기 아이콘: 자동 정렬 (알파벳순 또는 사용자 지정 순서)
- ✅ 우측 하단에 + 버튼 (프로그램 추가)
- ✅ 드래그로 순서만 변경
- ✅ 파일 드롭하면 실행
- ✅ 더블클릭으로 프로그램 실행

## Whisky 분석 결과

### 주요 패턴 (적용 가능)

1. **중앙 정렬 그리드**:
   ```swift
   LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: .infinity))], alignment: .center)
   ```

2. **더블클릭 감지**:
   ```swift
   .onTapGesture(count: 2) { /* enter workspace */ }
   ```

3. **자동 정렬**: `Comparable` 구현 + `.sorted()`

4. **모달 시트**: `.sheet(isPresented:) { CreationView() }`

5. **아이템 크기**:
   - 90x90pt (10pt padding 포함 = 100pt)
   - GridItem minimum: 100pt

6. **애니메이션**: `.easeInOut(duration: 0.2)` (Whisky 표준)

7. **파일 선택**: `NSOpenPanel()` 사용

### Whisky와의 차이점

| 요소 | Whisky | Soju 요구사항 |
|-----|--------|-------------|
| 워크스페이스 선택 | Sidebar List | 중앙 그리드 |
| 진입 방식 | 단일 클릭 | 더블클릭 |
| 바로가기 배치 | 고정 그리드 | 고정 그리드 (동일) |
| 드래그 | 없음 | 순서 변경 |
| + 버튼 위치 | 그리드 내부 | 우측 하단 |
| 네비게이션 | NavigationSplitView (sidebar) | NavigationStack (modern) |
| SwiftUI | 혼합 (구식 포함) | 최신 패턴 |

**중요**: Whisky 코드는 패턴 참고용일 뿐, **Soju는 최신 SwiftUI 방법**을 사용합니다:
- ✅ NavigationStack (iOS 16+, macOS 13+)
- ✅ Modern animation API
- ✅ @Observable macro (가능하면)
- ✅ 더 깔끔한 아키텍처

## 현재 Soju 구현 분석

### 제거할 기능
- ❌ **자유 배치 시스템** (DesktopView.swift의 position 기반 레이아웃)
- ❌ UserDefaults 위치 저장 (loadSavedPosition, handleIconPositionChanged)
- ❌ 단일 클릭 진입
- ❌ DesktopIconView의 드래그 제스처 (자유 이동)

### 유지할 기능
- ✅ Workspace/Program 모델 구조
- ✅ WorkspaceManager 싱글톤
- ✅ Wine 통합 (PodoSojuManager)
- ✅ 로깅 시스템
- ✅ 프로그램 실행 로직 (Program.run())

### 수정할 기능
- 🔄 ContentView: 그리드 레이아웃 + 더블클릭 + + 버튼
- 🔄 DesktopView → ShortcutsView: 그리드 기반 바로가기 뷰
- 🔄 DesktopIcon → Shortcut: 위치 정보 제거
- 🔄 WorkspaceSettings: programOrder 추가

## 구현 계획

### Phase 0: 로깅 시스템 강화 (우선 구현)

**목적**: 앱 실행 추적, 디버깅, 문제 진단을 위한 강력한 로깅 시스템 구축

#### 요구사항
1. **명확한 로그 파일 위치**
2. **상세한 로그 수집** - 모든 주요 이벤트 기록
3. **설정 기반 로그 레벨** - 플래그로 활성화/비활성화
4. **앱 실행 추적** - 왜 멈추는지 명확히 파악

#### 구현 내용

**1. Logger 확장** (`Logger+SojuKit.swift`)

현재 구현:
```swift
public static let logFileURL: URL = {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let logsDir = appSupport.appendingPathComponent("Soju").appendingPathComponent("Logs")
    // ...
    return logsDir.appendingPathComponent("soju.log")
}()

public func logWithFile(_ message: String, level: OSLogType = .default, file: String = #file) {
    // Console + file logging
}
```

**개선**:
```swift
// 1. 로그 레벨 enum 추가
public enum LogLevel: String, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

// 2. 설정 기반 로그 필터
public class LogConfig: ObservableObject {
    @Published var enableFileLogging: Bool = true
    @Published var enableConsoleLogging: Bool = true
    @Published var minimumLogLevel: LogLevel = .info

    public static let shared = LogConfig()

    // UserDefaults 연동
    init() {
        self.enableFileLogging = UserDefaults.standard.bool(forKey: "log.enableFile")
        self.enableConsoleLogging = UserDefaults.standard.bool(forKey: "log.enableConsole")
        if let levelRaw = UserDefaults.standard.string(forKey: "log.minimumLevel"),
           let level = LogLevel(rawValue: levelRaw) {
            self.minimumLogLevel = level
        }
    }

    func save() {
        UserDefaults.standard.set(enableFileLogging, forKey: "log.enableFile")
        UserDefaults.standard.set(enableConsoleLogging, forKey: "log.enableConsole")
        UserDefaults.standard.set(minimumLogLevel.rawValue, forKey: "log.minimumLevel")
    }
}

// 3. 향상된 로깅 메서드
extension Logger {
    public func log(
        _ message: String,
        level: LogLevel = .info,
        category: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let config = LogConfig.shared

        // 레벨 필터링
        guard level.osLogType.rawValue >= config.minimumLogLevel.osLogType.rawValue else {
            return
        }

        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let categoryPrefix = category.map { "[\($0)] " } ?? ""

        let logMessage = "[\(level.rawValue)] \(timestamp) \(fileName):\(line) \(function) - \(categoryPrefix)\(message)"

        // Console 로깅
        if config.enableConsoleLogging {
            self.log(level: level.osLogType, "\(logMessage)")
        }

        // 파일 로깅
        if config.enableFileLogging {
            Task {
                await writeToLogFile(logMessage)
            }
        }
    }

    private func writeToLogFile(_ message: String) async {
        let logFile = Self.logFileURL
        let logLine = message + "\n"

        guard let data = logLine.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                defer { try? fileHandle.close() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
            }
        } else {
            try? data.write(to: logFile, options: .atomic)
        }
    }
}

// 4. 편의 메서드
extension Logger {
    public func debug(_ message: String, category: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    public func info(_ message: String, category: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    public func warning(_ message: String, category: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    public func error(_ message: String, category: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }

    public func critical(_ message: String, category: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }
}
```

**2. 프로그램 실행 추적 강화** (`Program.swift`)

```swift
public func run(in workspace: Workspace) async throws {
    let executionId = UUID().uuidString
    Logger.sojuKit.info("🚀 Program execution started", category: "Program[\(executionId)]")
    Logger.sojuKit.debug("Program: \(self.name)", category: "Program[\(executionId)]")
    Logger.sojuKit.debug("URL: \(self.url.path)", category: "Program[\(executionId)]")
    Logger.sojuKit.debug("Workspace: \(workspace.settings.name)", category: "Program[\(executionId)]")

    guard !isRunning else {
        Logger.sojuKit.warning("⚠️ Program already running, ignoring request", category: "Program[\(executionId)]")
        return
    }

    await MainActor.run {
        self.isRunning = true
        self.exitCode = nil
        self.output = []
    }
    Logger.sojuKit.debug("✅ State updated: isRunning=true", category: "Program[\(executionId)]")

    do {
        let podoSoju = PodoSojuManager.shared
        Logger.sojuKit.debug("📦 PodoSojuManager acquired", category: "Program[\(executionId)]")

        let wineArgs = ["start", "/unix", self.url.path(percentEncoded: false)]
        Logger.sojuKit.debug("🍷 Wine args: \(wineArgs)", category: "Program[\(executionId)]")

        for await processOutput in try podoSoju.runWine(args: wineArgs, workspace: workspace) {
            switch processOutput {
            case .message(let message):
                Logger.sojuKit.debug("📤 Output: \(message)", category: "Program[\(executionId)]")
                await MainActor.run {
                    self.output.append(message)
                }
            case .error(let error):
                Logger.sojuKit.error("❌ Error: \(error)", category: "Program[\(executionId)]")
                await MainActor.run {
                    self.output.append("ERROR: \(error)")
                }
            case .terminated(let code):
                Logger.sojuKit.info("🏁 Terminated with code \(code)", category: "Program[\(executionId)]")
                await MainActor.run {
                    self.isRunning = false
                    self.exitCode = code
                }
                if code == 0 {
                    Logger.sojuKit.info("✅ Program completed successfully", category: "Program[\(executionId)]")
                } else {
                    Logger.sojuKit.error("⚠️ Program exited with error code \(code)", category: "Program[\(executionId)]")
                }
            case .started:
                Logger.sojuKit.info("▶️ Process started", category: "Program[\(executionId)]")
            }
        }
    } catch {
        Logger.sojuKit.critical("💥 Fatal error: \(error.localizedDescription)", category: "Program[\(executionId)]")
        Logger.sojuKit.debug("Error details: \(String(reflecting: error))", category: "Program[\(executionId)]")

        await MainActor.run {
            self.isRunning = false
            self.exitCode = 1
        }

        throw error
    }
}
```

**3. 워크스페이스 작업 추적** (`WorkspaceManager.swift`)

```swift
public func selectWorkspace(_ workspace: Workspace) {
    Logger.sojuKit.info("🎯 Selecting workspace: '\(workspace.settings.name)'", category: "WorkspaceManager")
    Logger.sojuKit.debug("Workspace URL: \(workspace.url.path)", category: "WorkspaceManager")

    currentWorkspace = workspace
    Logger.sojuKit.debug("✅ currentWorkspace updated", category: "WorkspaceManager")

    let env = workspace.wineEnvironment()
    Logger.sojuKit.debug("🌍 Wine environment variables:", category: "WorkspaceManager")
    for (key, value) in env {
        if key.starts(with: "WINE") || key == "WINEPREFIX" {
            Logger.sojuKit.debug("  \(key)=\(value)", category: "WorkspaceManager")
        }
    }

    Logger.sojuKit.info("🚀 Ready to launch programs in workspace", category: "WorkspaceManager")
}
```

**4. 설정 UI** (`SettingsView.swift` - 새로 생성)

```swift
struct LogSettingsView: View {
    @ObservedObject var logConfig = LogConfig.shared

    var body: some View {
        Form {
            Section("Logging") {
                Toggle("Enable File Logging", isOn: $logConfig.enableFileLogging)
                Toggle("Enable Console Logging", isOn: $logConfig.enableConsoleLogging)

                Picker("Minimum Log Level", selection: $logConfig.minimumLogLevel) {
                    ForEach([LogLevel.debug, .info, .warning, .error, .critical], id: \.self) { level in
                        Text(level.rawValue)
                    }
                }

                Button("Open Log File") {
                    NSWorkspace.shared.activateFileViewerSelecting([Logger.sojuKit.logFileURL])
                }

                Button("Clear Logs") {
                    try? FileManager.default.removeItem(at: Logger.sojuKit.logFileURL)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: logConfig.enableFileLogging) { _, _ in logConfig.save() }
        .onChange(of: logConfig.enableConsoleLogging) { _, _ in logConfig.save() }
        .onChange(of: logConfig.minimumLogLevel) { _, _ in logConfig.save() }
    }
}
```

#### 로그 카테고리 정의

| 카테고리 | 설명 |
|---------|------|
| `WorkspaceManager` | 워크스페이스 선택, 생성, 삭제 |
| `Program[<id>]` | 특정 프로그램 실행 추적 |
| `PodoSoju` | Wine 실행 및 Wine 서버 통신 |
| `UI` | UI 이벤트 (클릭, 드래그, 모달 등) |
| `FileSystem` | 파일 작업 |
| `Network` | 네트워크 요청 (있다면) |

#### 로그 출력 예시

```
[INFO] 2026-01-08T22:45:12Z ContentView.swift:92 onSelect() - [UI] 🖱️ Workspace clicked: My Workspace
[INFO] 2026-01-08T22:45:12Z WorkspaceManager.swift:122 selectWorkspace(_:) - [WorkspaceManager] 🎯 Selecting workspace: 'My Workspace'
[DEBUG] 2026-01-08T22:45:12Z WorkspaceManager.swift:123 selectWorkspace(_:) - [WorkspaceManager] Workspace URL: /Users/max/Library/Containers/...
[DEBUG] 2026-01-08T22:45:12Z WorkspaceManager.swift:128 selectWorkspace(_:) - [WorkspaceManager] 🌍 Wine environment variables:
[DEBUG] 2026-01-08T22:45:12Z WorkspaceManager.swift:130 selectWorkspace(_:) - [WorkspaceManager]   WINEPREFIX=/Users/max/.../drive_c
[INFO] 2026-01-08T22:45:15Z Program.swift:147 run(in:) - [Program[abc-123]] 🚀 Program execution started
[DEBUG] 2026-01-08T22:45:15Z Program.swift:148 run(in:) - [Program[abc-123]] Program: notepad.exe
[DEBUG] 2026-01-08T22:45:15Z Program.swift:149 run(in:) - [Program[abc-123]] URL: /Users/max/.../notepad.exe
[INFO] 2026-01-08T22:45:15Z Program.swift:165 run(in:) - [Program[abc-123]] ▶️ Process started
[DEBUG] 2026-01-08T22:45:16Z Program.swift:159 run(in:) - [Program[abc-123]] 📤 Output: Wine: starting process...
[INFO] 2026-01-08T22:45:18Z Program.swift:172 run(in:) - [Program[abc-123]] 🏁 Terminated with code 0
[INFO] 2026-01-08T22:45:18Z Program.swift:178 run(in:) - [Program[abc-123]] ✅ Program completed successfully
```

---

### Phase 1: 데이터 모델 수정

**파일**:
- `SojuKit/Sources/SojuKit/Models/WorkspaceSettings.swift`
- `SojuKit/Sources/SojuKit/Models/DesktopIcon.swift` (또는 새로 Shortcut.swift 생성)

**변경사항**:
1. WorkspaceSettings에 `programOrder: [UUID] = []` 추가
2. DesktopIcon에서 `position: CGPoint` 제거 또는 Shortcut 모델 새로 생성
3. Comparable 구현 (이름순 정렬)

---

### Phase 2: 워크스페이스 선택 화면 개선

**파일**: `Soju/ContentView.swift`

**변경사항**:

1. **더블클릭으로 변경** (line 100):
   ```swift
   // Before:
   .onTapGesture { onSelect() }

   // After:
   .onTapGesture(count: 2) { onSelect() }
   ```

2. **+ 버튼 추가** (우측 하단):
   ```swift
   ZStack(alignment: .bottomTrailing) {
       workspaceSelectionView

       Button(action: { showCreateWorkspace = true }) {
           Image(systemName: "plus.circle.fill")
               .font(.system(size: 44))
               .foregroundColor(.accentColor)
       }
       .buttonStyle(.plain)
       .padding(20)
       .sheet(isPresented: $showCreateWorkspace) {
           WorkspaceCreationView()
       }
   }
   ```

3. **그리드 개선** (이미 LazyVGrid 사용 중):
   ```swift
   // 현재 adaptive(minimum: 200, maximum: 300)
   // Whisky 패턴 적용: adaptive(minimum: 100, maximum: .infinity)

   LazyVGrid(
       columns: [GridItem(.adaptive(minimum: 120, maximum: 200))],
       alignment: .center,
       spacing: 20
   )
   ```

---

### Phase 3: DesktopView → ShortcutsGridView 재구현

**새 파일**: `Soju/Views/Workspace/ShortcutsGridView.swift`

**구조**:
```swift
struct ShortcutsGridView: View {
    @ObservedObject var workspace: Workspace
    @State private var shortcuts: [Shortcut] = []
    @State private var showAddProgram = false

    private let gridLayout = [GridItem(.adaptive(minimum: 100, maximum: .infinity))]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 메인 그리드
            ScrollView {
                LazyVGrid(columns: gridLayout, alignment: .center, spacing: 20) {
                    ForEach(shortcuts) { shortcut in
                        ShortcutView(shortcut: shortcut, workspace: workspace)
                    }
                }
                .padding()
            }
            .background(desktopBackground)

            // + 버튼 (우측 하단)
            Button(action: { showAddProgram = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .padding(20)
            .sheet(isPresented: $showAddProgram) {
                AddProgramView(workspace: workspace)
            }
        }
        .onAppear { loadShortcuts() }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleFileDrop(providers)
        }
    }

    private func loadShortcuts() {
        // workspace.settings.pinnedPrograms 또는 programOrder 기반 정렬
        shortcuts = workspace.settings.pinnedPrograms
            .sorted { $0.name < $1.name }
            .map { Shortcut(from: $0) }
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        // 파일 드롭 처리 → 실행
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    // Execute file
                    let program = Program(name: url.lastPathComponent, url: url)
                    Task {
                        try await program.run(in: workspace)
                    }
                }
            }
        }
        return true
    }
}
```

---

### Phase 4: ShortcutView 컴포넌트

**새 파일**: `Soju/Views/Workspace/ShortcutView.swift`

**구조** (Whisky PinView 패턴):
```swift
struct ShortcutView: View {
    let shortcut: Shortcut
    let workspace: Workspace
    @State private var opening = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: shortcut.iconImage)
                .resizable()
                .frame(width: 45, height: 45)
                .scaleEffect(opening ? 2 : 1)
                .opacity(opening ? 0 : 1)

            Text(shortcut.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(width: 90, height: 90)
        .padding(10)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            runProgram()
        }
        .contextMenu {
            Button("Rename", systemImage: "pencil.line") { /* ... */ }
            Button("Remove", systemImage: "trash") { /* ... */ }
        }
    }

    private func runProgram() {
        withAnimation(.easeIn(duration: 0.25)) {
            opening = true
        } completion: {
            withAnimation(.easeOut(duration: 0.1)) {
                opening = false
            }
        }

        let program = Program(
            name: shortcut.name,
            url: shortcut.url
        )
        Task {
            try await program.run(in: workspace)
        }
    }
}
```

---

### Phase 5: 워크스페이스/프로그램 생성 모달

**새 파일**:
- `Soju/Views/Creation/WorkspaceCreationView.swift`
- `Soju/Views/Creation/AddProgramView.swift`

**패턴** (Whisky와 동일):
```swift
struct WorkspaceCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var icon = "desktopcomputer"
    @State private var windowsVersion: WinVersion = .win10

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)

                Picker("Icon", selection: $icon) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Label(icon, systemImage: icon)
                    }
                }

                Picker("Windows Version", selection: $windowsVersion) {
                    ForEach(WinVersion.allCases.reversed(), id: \.self) {
                        Text($0.pretty())
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Create Workspace")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Create") { createWorkspace() }
                        .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func createWorkspace() {
        Task {
            try await WorkspaceManager.shared.createWorkspace(
                name: name,
                icon: icon,
                windowsVersion: windowsVersion
            )
            dismiss()
        }
    }
}
```

---

### Phase 6: 드래그 순서 변경 (선택 사항)

SwiftUI에서 그리드 아이템 순서 변경은 복잡합니다. 두 가지 접근:

**Option 1: ForEach + onMove (iOS 16+)**
```swift
ForEach(shortcuts) { shortcut in
    ShortcutView(shortcut: shortcut)
}
.onMove { from, to in
    shortcuts.move(fromOffsets: from, toOffset: to)
    saveOrder()
}
```
→ 문제: LazyVGrid에서는 onMove 작동 안함

**Option 2: Drag & Drop API**
```swift
ShortcutView(...)
    .onDrag { NSItemProvider(object: shortcut.id.uuidString as NSString) }
    .onDrop(of: [.text], delegate: ShortcutDropDelegate(
        shortcut: shortcut,
        shortcuts: $shortcuts
    ))
```

**권장**: 일단 드래그 순서 변경은 나중에 구현 (우선순위 낮음)

---

## 구현 순서

### Step 1: 데이터 모델 정리
1. Shortcut 모델 생성 (position 없이)
2. WorkspaceSettings에 programOrder 추가
3. Comparable 구현

### Step 2: 워크스페이스 선택 화면
1. 더블클릭으로 변경
2. + 버튼 추가 (우측 하단)
3. WorkspaceCreationView 모달 구현

### Step 3: 바로가기 그리드 뷰
1. ShortcutsGridView 새로 생성
2. ShortcutView 컴포넌트 구현
3. + 버튼 및 AddProgramView 모달
4. 파일 드롭 처리

### Step 4: ContentView 통합
1. DesktopView → ShortcutsGridView 교체
2. 네비게이션 플로우 테스트

### Step 5: 정리
1. 사용하지 않는 DesktopView 코드 제거
2. DesktopIconView 제거 또는 아카이브
3. UserDefaults 위치 저장 코드 제거

---

## 핵심 파일 맵

### 새로 생성
- `Soju/Views/Workspace/ShortcutsGridView.swift` - 바로가기 그리드 메인 뷰
- `Soju/Views/Workspace/ShortcutView.swift` - 개별 바로가기 카드
- `Soju/Views/Creation/WorkspaceCreationView.swift` - 워크스페이스 생성 모달
- `Soju/Views/Creation/AddProgramView.swift` - 프로그램 추가 모달
- `SojuKit/Sources/SojuKit/Models/Shortcut.swift` - Shortcut 모델 (또는 DesktopIcon 수정)

### 수정
- `Soju/ContentView.swift` - 더블클릭, + 버튼 추가
- `SojuKit/Sources/SojuKit/Models/WorkspaceSettings.swift` - programOrder 추가

### 제거 대상 (나중에)
- `Soju/Views/Desktop/DesktopView.swift` - ShortcutsGridView로 대체
- `Soju/Views/Desktop/DesktopIconView.swift` - ShortcutView로 대체

---

## 검증 기준

### 워크스페이스 선택
- [ ] 그리드가 중앙 정렬됨
- [ ] 더블클릭으로 워크스페이스 진입
- [ ] 우측 하단에 + 버튼
- [ ] + 버튼 클릭 시 생성 모달 표시
- [ ] 생성 후 자동으로 그리드에 추가

### 바로가기 화면
- [ ] 바로가기가 그리드로 정렬
- [ ] 더블클릭으로 프로그램 실행
- [ ] 우측 하단에 + 버튼
- [ ] 파일 드롭으로 실행
- [ ] 실행 애니메이션 (scale + fade)

---

## 참고: Whisky 코드 위치

- 그리드 레이아웃: `Whisky/Views/Bottle/BottleView.swift:35-48`
- 더블클릭: `Whisky/Views/Bottle/Pins/PinView.swift:86`
- 모달 생성: `Whisky/Views/Bottle/BottleCreationView.swift`
- 아이템 뷰: `Whisky/Views/Bottle/Pins/PinView.swift`
- + 버튼: `Whisky/Views/Bottle/Pins/PinAddView.swift`
