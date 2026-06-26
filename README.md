<div align="center">
  <img src="windows/runner/resources/app_icon.ico" width="64" height="64" alt="Karnama Logo">
  <h1 align="center">کارنما</h1>
  <p align="center">⏱  Time tracker for Jira — Windows desktop app built with Flutter</p>
  <p align="center">
    <b>زمانت رو ثبت کن. با Jira همگام‌سازی کن. بهره‌وریت رو ببین.</b>
  </p>
  <br>
</div>

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎯 **Timer-based tracking** | Start/stop timer with Jira issue selection |
| ⏸ **Pause/Resume** | Pause timer anytime, resume later |
| 🔄 **Change issue mid-timer** | Switch Jira task without stopping |
| 🤝 **Jira integration** | Bearer Token auth, auto-sync worklogs |
| 📊 **Weekly stats** | Bar chart showing 7-day activity, top task, daily comparison |
| 📋 **History** | Date-filtered logs with JSON export |
| 🌙 **Dark mode** | Full dark theme with system tray support |
| 🖥️ **System tray** | Blinking tray icon, context menu, minimize to tray |
| 🔌 **Offline-first** | JSON file storage, no database required |
| 🇮🇷 **Persian UI** | Full RTL Persian interface with Vazir font |

## 📸 Screenshots

<!-- Add screenshots here once available -->

## 🚀 Getting Started

### Prerequisites

- Windows 10 or later (64-bit)
- Flutter 3.38+ / Dart 3.10+ (for development)
- A Jira Server or Data Center instance (optional — app works offline too)

### Installation

**From release build:**

```bash
# Navigate to release directory
cd build\windows\x64\runner\Release

# Run the executable
.\karnama.exe
```

**From source:**

```bash
# Clone the repository
git clone <repo-url>
cd karnama

# Get dependencies (offline mode — pub.dev may be blocked)
flutter pub get --offline

# Build for Windows
flutter build windows --release

# Run
.\build\windows\x64\runner\Release\karnama.exe
```

## 🔧 Jira Configuration

1. Go to **Settings** tab
2. Enter your Jira Server URL (e.g., `https://jira.company.com`)
3. Choose auth type:
   - **Bearer Token** (recommended): Generate a PAT from Jira → Profile → Personal Access Tokens
   - **Basic Auth**: Username + password
4. Click **Test Connection** to verify
5. Click **Save**

The app uses the following JQL for issue search:
```
text ~ "query" OR key = "query" ORDER BY updatedDate DESC
```

Worklogs are posted via:
```
POST /rest/api/2/issue/{issueKey}/worklog
```

## 🎮 Usage

### Dashboard
- **Start Timer**: Tap the big play button — search and select a Jira issue, or start without one
- **Quick Resume**: One-click restart of your last tracked issue
- **Change Issue**: Tap the issue chip above the timer while running
- **Pause/Resume**: Freeze timer without losing progress
- **Weekly Chart**: View your last 7 days at a glance

### System Tray
- **Left-click**: Restore window
- **Right-click**:
  - Start/Stop timer
  - Pause/Resume (dynamic label based on state)
  - Open window
  - Settings
  - Exit
- **Blinking icon**: Indicates timer is actively running
- **Paused icon**: Solid icon when timer is paused
- **Tooltip**: Shows elapsed time and active issue key

### Keyboard Shortcuts
> Coming in a future release

## 🏗 Project Structure

```
karnama/
├── lib/
│   ├── app.dart                  # App entry, theme, navigation
│   ├── main.dart                 # Main entry point
│   ├── l10n/
│   │   └── strings_fa.dart       # Persian strings
│   ├── models/
│   │   ├── jira_config.dart      # Jira connection model
│   │   ├── jira_issue.dart       # Jira issue model
│   │   ├── jira_project.dart     # Jira project model
│   │   └── work_log.dart         # Work log model
│   ├── providers/
│   │   ├── settings_provider.dart
│   │   ├── timer_provider.dart
│   │   └── worklog_provider.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart # Main timer + stats
│   │   ├── history_screen.dart   # Log history with filters
│   │   ├── log_screen.dart       # Manual/auto log entry
│   │   └── settings_screen.dart  # Jira config + dark mode
│   ├── services/
│   │   ├── database_service.dart # JSON file storage
│   │   ├── jira_service.dart     # Jira REST API client
│   │   ├── timer_service.dart    # Timer logic
│   │   └── window_title_service.dart  # MethodChannel bridge
│   └── widgets/
│       ├── custom_title_bar.dart
│       ├── issue_selector.dart
│       ├── log_card.dart
│       ├── persian_utils.dart
│       ├── simple_bar_chart.dart
│       └── timer_widget.dart
├── windows/
│   └── runner/
│       ├── flutter_window.cpp    # MethodChannel handlers
│       ├── main.cpp              # Window creation
│       ├── resource.h
│       ├── Runner.rc
│       ├── tray_handler.cpp      # System tray C++ impl
│       └── tray_handler.h
├── .gitignore
└── README.md
```

## ⚙️ Technical Details

### Architecture
- **State Management**: Provider pattern
- **Storage**: JSON files in `Documents\karnama\`
- **Window Integration**: `MethodChannel` between Dart and C++
- **System Tray**: Pure Win32 API (`Shell_NotifyIcon`) — no third-party packages
- **Idle Detection**: `GetLastInputInfo()` via Windows API
- **Font**: Vazirmatn v33.003 for Persian typography
- **Build**: Flutter 3.38.8, Dart 3.10.7

### Key Design Decisions
- **No pub.dev packages beyond cached**: `provider`, `path_provider`, `shared_preferences`
- **Own tray implementation**: Dart FFI was crashing, so C++ `tray_handler` was built
- **JSON over SQLite**: `sqflite` not available in offline cache
- **Bearer Token over Basic Auth**: Jira Server 9.4+ with Basic Auth disabled
- **UTF-8 body encoding**: Persian characters require `utf8.encode()` + `request.add()`

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Jira connection fails | Check your Bearer token expiry, verify server URL |
| Persian text encoding | Settings appends `request.add(utf8.encode(body))` — ensure not using `request.write()` |
| App won't start after update | Delete `%USERPROFILE%\Documents\karnama\` and retry |
| pub.dev 403 errors | Use `flutter pub get --offline` |
| Tray icon not showing | Restart Windows Explorer, or app may need admin |

## 📝 License

[MIT](LICENSE)

## 🙏 Acknowledgements

- [Flutter](https://flutter.dev) — Cross-platform framework
- [Vazirmatn](https://github.com/rastikerdar/vazirmatn) — Persian font by Saber Rastikerdar
- [Jira REST API](https://developer.atlassian.com/server/jira/platform/rest-apis/) — Worklog integration

---

<div align="center">
  <sub>ساخته شده با ❤️ برای تیم‌های ایرانی</sub>
</div>
