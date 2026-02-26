# EM Copilot

AI-powered 1:1 and performance review assistant for Engineering Managers.

Powered by Claude (claude-opus-4-6). Native macOS + iOS app.

---

## Features

| Feature | What it does |
|---|---|
| **Performance Review** | Paste your notes → structured perf narrative with calibration language |
| **Promotion Document** | Accomplishments + peer feedback → promo doc ready for nomination |
| **1:1 Summary** | Raw meeting notes → clean summary with action items |
| **PIP / Dev Plan** | Performance gaps → structured improvement plan |
| **Program Status Report** | Program updates → executive-ready status report |
| **Stakeholder Email** | Key points → polished email for VPs / steering committees |
| **Risk Report** | Risk notes → risk register + mitigation plan |
| **Program Manager** | Track programs, risks, and generate reports per-program |
| **macOS Menu Bar** | One-click access from the menu bar — no switching to main window |

---

## Setup

### Requirements
- Xcode 15+ (macOS 14+ SDK)
- An Anthropic API key — get one at [console.anthropic.com](https://console.anthropic.com/account/keys)

### 1. Generate the Xcode project

```bash
cd /path/to/EM-Copilot
python3 generate_xcodeproj.py
open EMCopilot.xcodeproj
```

### 2. Configure in Xcode

1. Select the `EMCopilot` target → **Signing & Capabilities**
2. Choose your Apple Developer Team
3. Change the Bundle Identifier from `com.yourname.emcopilot` to your own reverse domain
   - You can also update this in `generate_xcodeproj.py` and re-run

### 3. macOS entitlements (for network access)

The app needs outbound network access to call the Anthropic API.

In Xcode: Target → Signing & Capabilities → **App Sandbox** → check **Outgoing Connections (Client)**

Or add `EMCopilot.entitlements` manually:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

### 4. Add your API key

Run the app → Settings → paste your Anthropic API key → Save Key → Test Connection

---

## Project Structure

```
EMCopilot/
├── App/
│   └── EMCopilotApp.swift          # Entry point, MenuBarExtra, SwiftData setup
├── Models/
│   ├── DirectReport.swift           # SwiftData model for team members
│   ├── GeneratedDocument.swift      # All generated docs (perf, promo, 1:1, PIP…)
│   └── Program.swift                # Programs, risks, updates
├── Services/
│   ├── ClaudeService.swift          # Anthropic API client
│   └── Prompts.swift                # All EM-specific system prompts
└── Views/
    ├── ContentView.swift             # macOS split view / iOS tab bar
    ├── Home/HomeView.swift           # Dashboard + quick actions
    ├── DirectReports/                # Manage direct reports
    ├── Generator/                    # Document generator + output view
    ├── Programs/                     # Program manager
    └── Settings/SettingsView.swift   # API key config
```

---

## Regenerating the Xcode project

If you add new Swift files, add them to `SOURCE_FILES` in `generate_xcodeproj.py` and re-run:

```bash
python3 generate_xcodeproj.py
```

---

## Roadmap

- [ ] iCloud sync for documents across devices
- [ ] Export to PDF / Markdown file
- [ ] Direct report notes history / timeline
- [ ] Promo doc templates by company (Amazon, Google, Meta, etc.)
- [ ] Stripe billing integration for SaaS
- [ ] App Store distribution

---

## Monetization (planned)

- Direct sale via own website + Stripe: $29–49/month
- App Store (Mac App Store): single purchase or subscription
- Target audience: EMs at FAANG / high-growth tech companies
