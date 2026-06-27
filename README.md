<div align="center">
  <img src="assets/images/karnama-logo.png" width="200" alt="Karnama Logo">
  <h1 align="center">کارنما</h1>
  <p align="center">⏱  Time tracker for Jira — Cross-platform desktop app built with Flutter</p>
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

| Requirement | Windows | Linux |
|-------------|---------|-------|
| **OS** | Windows 10+ (64-bit) | Ubuntu 20.04+, Debian 11+, or similar |
| **Flutter** | 3.38+ | 3.38+ |
| **Dart** | 3.10+ | 3.10+ |
| **CMake** | Included with Flutter | 3.13+ |
| **Ninja** | Included with Flutter | 1.10+ |
| **Jira** | Optional (app works offline) | Optional (app works offline) |

> **Note:** If `pub.dev` is blocked in your region, see the [Proxy / Mirror Setup](#proxy--mirror-setup) section.

## 🏗 Building from Source

### Clone the Repository

```bash
git clone <repo-url>
cd karnama
```

---

### Windows

#### Install Flutter (if not installed)

1. Download Flutter SDK from [flutter.dev](https://flutter.dev)
2. Extract and add to `PATH`
3. Run:
   ```bash
   flutter doctor
   ```

#### Build

```bash
# Get dependencies
flutter pub get

# Build release
flutter build windows

# Run
.\build\windows\x64\runner\Release\karnama.exe
```

The build output will be in `build\windows\x64\runner\Release\`.

---

### Linux

#### Install System Dependencies

**Ubuntu / Debian:**

```bash
sudo apt update
sudo apt install -y \
  cmake ninja-build pkg-config clang \
  libgtk-3-dev libayatana-appindicator3-dev \
  libxss-dev liblzma-dev libstdc++-12-dev
```

**Fedora:**

```bash
sudo dnf install -y \
  cmake ninja-build pkgconf gcc-c++ \
  gtk3-devel libayatana-appindicator-gtk3-devel \
  libXScrnSaver-devel libstdc++-devel
```

**Arch Linux:**

```bash
sudo pacman -S \
  cmake ninja pkgconf gcc \
  gtk3 libayatana-appindicator \
  libxss
```

#### Install Flutter (if not installed)

```bash
# Clone Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$HOME/flutter/bin:$PATH"

# Or download a release archive (if git clone is slow)
curl -L -o /tmp/flutter.tar.xz \
  "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz"
tar xf /tmp/flutter.tar.xz -C ~
export PATH="$HOME/flutter/bin:$PATH"
```

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/flutter/bin:$HOME/flutter/bin/cache/dart-sdk/bin:$PATH"
```

#### Build

```bash
# Get dependencies
flutter pub get

# Build release
flutter build linux

# Run
./build/linux/x64/release/bundle/karnama
```

The build output will be in `build/linux/x64/release/bundle/`.

---

### Proxy / Mirror Setup

If `pub.dev` or Flutter artifacts are blocked in your region (e.g., Iran, China), set these environment variables before running any Flutter command:

```bash
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
```

Add them to `~/.bashrc` / `~/.zshrc` to persist.

Then run:

```bash
flutter pub get
flutter build linux   # or: flutter build windows
```

---

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
  - Exit
- **Blinking icon**: Indicates timer is actively running
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
│       ├── flutter_window.cpp    # MethodChannel handlers (Windows)
│       ├── main.cpp              # Win32 window creation
│       ├── tray_handler.cpp      # System tray — Win32 Shell_NotifyIcon
│       └── tray_handler.h
├── linux/
│   ├── CMakeLists.txt            # Linux build configuration
│   ├── flutter/
│   │   └── CMakeLists.txt        # Flutter managed build rules
│   └── runner/
│       ├── main.cc               # GTK application entry
│       ├── my_application.cc     # GTK window + MethodChannel handlers
│       ├── my_application.h
│       └── CMakeLists.txt        # Runner build rules
├── assets/
│   ├── fonts/                    # Vazir Persian font
│   └── images/                   # App icons and images
├── pubspec.yaml
└── README.md
```

## ⚙️ Technical Details

### Architecture
- **State Management**: Provider pattern
- **Storage**: JSON files in `Documents/karnama/` (Windows) or `~/.local/share/karnama/` (Linux)
- **Window Integration**: `MethodChannel` between Dart and native code
- **Font**: Vazirmatn for Persian typography

### Platform-Specific Details

| Component | Windows | Linux |
|-----------|---------|-------|
| **Window API** | Win32 (`CreateWindowEx`, `HWND`) | GTK3 (`GtkApplication`, `FlView`) |
| **System Tray** | Win32 `Shell_NotifyIcon` | Ayatana AppIndicator3 |
| **Idle Detection** | `GetLastInputInfo()` | X11 Screen Saver Extension |
| **Window Drag** | `PostMessageW(WM_NCLBUTTONDOWN)` | `gdk_device_get_position` loop |
| **Build System** | CMake + MSVC | CMake + Ninja + Clang |

### Key Design Decisions
- **No pub.dev packages beyond cached**: `provider`, `path_provider`, `shared_preferences`
- **Own tray implementation**: Platform-native C/C++ tray handler per OS
- **JSON over SQLite**: `sqflite` not available in offline cache
- **Bearer Token over Basic Auth**: Jira Server 9.4+ with Basic Auth disabled
- **UTF-8 body encoding**: Persian characters require `utf8.encode()` + `request.add()`

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Jira connection fails | Check your Bearer token expiry, verify server URL |
| Persian text encoding | Ensure using `request.add(utf8.encode(body))`, not `request.write()` |
| App won't start after update | Delete `Documents/karnama/` (Windows) or `~/.local/share/karnama/` (Linux) and retry |
| pub.dev 403 errors | Set `PUB_HOSTED_URL="https://pub.flutter-io.cn"` (see [Proxy / Mirror Setup](#proxy--mirror-setup)) |
| Tray icon not showing (Windows) | Restart Windows Explorer, or run as admin |
| Tray icon not showing (Linux) | Ensure `libayatana-appindicator3` is installed and your DE supports StatusNotifierItem |
| `cmake` not found | Install via your package manager (see [Linux dependencies](#install-system-dependencies)) |
| Flutter command hangs | Set `FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"` if in a blocked region |

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
