# F1 Speed Feed Read

A [Command Palette](https://learn.microsoft.com/windows/powertoys/command-palette/overview) extension that pulls Formula 1 news from your favorite RSS feeds and shows it right inside Command Palette — no browser tab required.

Repo: [github.com/dah007/f1speed-rss-read](https://github.com/dah007/f1speed-rss-read)

## What it does

- Aggregates headlines from several F1 RSS feeds into one scrollable, Markdown-rendered news page.
- Comes pre-configured with four feeds (BBC Sport F1, Autosport, Motorsport.com, Formula1.com Official) — add, remove, or replace them with whatever sources you trust.
- Adds a **F1 News** item to Command Palette's dock band, so the latest headlines are one click away.
- Click a headline to open the full article in your default browser.
- Everything is stored locally; nothing but the feed requests themselves leaves your machine.

## Requirements

- Windows 10 (build 19041+) or Windows 11.
- [Command Palette](https://learn.microsoft.com/windows/powertoys/command-palette/overview) (ships with recent [PowerToys](https://aka.ms/PowerToys) releases, or standalone from the Microsoft Store).
- No separate .NET install needed — the release installer ships a self-contained build.

## Installing

### Option 1 — Installer (recommended)

1. Grab the latest installer for your CPU architecture from the [Releases](https://github.com/dah007/f1speed-rss-read/releases) page:
   - `F1Speed Feed Read_<version>_x64compatible.exe` — Intel/AMD 64-bit
   - `F1Speed Feed Read_<version>_arm64.exe` — ARM64 (Surface Pro X, etc.)
2. Run it. It installs per-user (no admin rights needed) to `%LOCALAPPDATA%\Programs\F1Speed Feed Read` and registers the extension with Windows.
3. Open Command Palette, run **Reload** → **Reload Command Palette extensions**.
4. Search for **F1 News** or **Manage F1 Feeds**.

### Option 2 — Build and deploy from source

1. Install [Visual Studio](https://visualstudio.microsoft.com/) with the **.NET desktop development** and **Windows App SDK** workloads, plus the [.NET 10 SDK](https://dotnet.microsoft.com/download).
2. Clone the repo and open `F1RssFeedRead/F1RssFeedRead.sln`.
3. Set the launch profile to **F1RssFeedRead (Package)**.
4. **Build > Deploy** (not just Build) — this registers the MSIX package locally.
5. In Command Palette, run **Reload** → **Reload Command Palette extensions**.

## Using it

- **F1 News** — opens the aggregated feed. Each entry shows its source, publish time, and a short summary; click the title to read the full article.
- **Manage F1 Feeds** — lists your configured feeds. From here you can:
  - **Add feed** — enter a name and the feed's RSS/Atom URL.
  - **Remove** a feed — open its context menu (the `...` on a feed item) and choose the delete action.
- Feed data is stored locally in `feeds.json` under your Command Palette extension settings folder. Deleting the extension's settings resets you back to the four default feeds.

## Uninstalling

If you installed via the EXE installer:

- **Settings → Apps → Installed apps**, find **F1Speed Feed Read**, and uninstall — or run the installer again and choose uninstall.
- This removes the installed files and the registry entries that registered the extension, so it disappears from Command Palette. Run **Reload** in Command Palette afterward if it's still listed.

If you deployed from Visual Studio, remove it the same way you'd remove any sideloaded MSIX app (**Settings → Apps**), or use **Build > Clean**.

## Building the installer yourself

The `F1RssFeedRead/installer/` folder has everything needed to produce the same EXE installers published in Releases:

```powershell
# Requires Inno Setup 6: https://jrsoftware.org/isdl.php
cd F1RssFeedRead/installer
.\build-exe.ps1 -Version "0.1.0"
```

This publishes the app unpackaged and self-contained for both `x64` and `arm64` (via `-p:WindowsPackageType=None` on the command line only — your `.csproj` and the Visual Studio **(Package)** dev workflow are untouched), then runs Inno Setup against `setup.iss` to produce the installers in `F1RssFeedRead\installer\Installer\`.

`setup.iss` registers the extension's out-of-process COM server (`HKCU\...\CLSID\{20d1b788-ddd1-4b84-a5fa-df3b61a47939}\LocalServer32`) so Command Palette can activate it without an MSIX package — the same CLSID used by `Package.appxmanifest` for the Store/sideload path. Uninstalling removes those registry entries along with the files.

## Project structure

```text
F1RssFeedRead/
├── F1RssFeedRead.sln
└── F1RssFeedRead/
    ├── Program.cs                     # COM server entry point
    ├── F1RssFeedRead.cs               # IExtension implementation
    ├── F1RssFeedReadCommandsProvider.cs
    ├── Pages/
    │   ├── F1RssFeedReadPage.cs        # "F1 News" — renders the aggregated feed
    │   ├── ManageFeedsPage.cs          # "Manage F1 Feeds" — list of configured feeds
    │   └── AddFeedPage.cs              # "Add feed" form
    ├── Commands/RemoveFeedCommand.cs
    ├── Services/RssFetcher.cs          # Fetches + parses RSS/Atom feeds
    ├── Helpers/FeedsManager.cs         # Loads/saves feeds.json
    ├── Models/                         # FeedSource, RssArticle, FeedFormResult
    └── Persistence/                    # feeds.json (de)serialization
└── installer/
    ├── setup.iss                      # Inno Setup installer/uninstaller script
    └── build-exe.ps1                  # Publishes + builds the installer EXEs
```

## Tech stack

- C# / .NET 10, targeting `net10.0-windows10.0.26100.0`
- [Microsoft.CommandPalette.Extensions](https://learn.microsoft.com/windows/powertoys/command-palette/extensibility-overview) for the extension APIs
- [Shmuelie.WinRTServer](https://github.com/Shmuelie/Shmuelie.WinRTServer) for the out-of-process COM server
- Trimmed, AOT-friendly, self-contained single-file publish for the installer build

## Development notes

- Always use **Build > Deploy**, not just Build, when testing in Command Palette — Deploy registers the MSIX package.
- After deploying, run **Reload** in Command Palette to pick up changes.
- Debug output goes to **Ctrl+Alt+O** (Output window, "Debug" source) when running under the **(Package)** launch profile with F5.

## License

[MIT](LICENSE)

## Contributing

Issues and pull requests are welcome at [github.com/dah007/f1speed-rss-read](https://github.com/dah007/f1speed-rss-read).
