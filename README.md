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
- No separate .NET install needed — the release package is self-contained.

## Installing

Command Palette only finds extensions that are installed as a real Windows package (it doesn't scan for apps the way a Start Menu search does) — so unlike most GitHub tools, this isn't a plain EXE you just run. Pick one of the two options below.

### Option 1 — MSIX package (recommended for most users)

1. From the [Releases](https://github.com/dah007/f1speed-rss-read/releases) page, download for your CPU architecture:
   - `F1RssFeedRead_<version>_x64.msix` — Intel/AMD 64-bit
   - `F1RssFeedRead_<version>_arm64.msix` — ARM64 (Surface Pro X, etc.)
   - `F1SpeedFeedRead.cer` — the publisher certificate
2. **Trust the certificate** (one-time, per machine). The package is signed with a self-signed certificate rather than a paid one, so Windows won't install it until you tell it to trust that signer — and it must go in the **Local Machine** store specifically, not Current User:
   - **GUI:** Double-click `F1SpeedFeedRead.cer` → **Install Certificate** → **Local Machine** → accept the UAC prompt → **Place all certificates in the following store** → **Browse** → **Trusted People** → **OK** → **Next** → **Finish**.
   - **PowerShell (as Administrator), equivalent:**

     ```powershell
     Import-Certificate -FilePath .\F1SpeedFeedRead.cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople
     ```

3. Double-click the `.msix` file and install it (or `Add-AppxPackage -Path .\F1RssFeedRead_<version>_x64.msix` in PowerShell).
4. Open Command Palette, run **Reload** → **Reload Command Palette extensions**.
5. Search for **F1 News** or **Manage F1 Feeds**.

> **Troubleshooting:** if step 3 fails with `App installation failed... error 0x800B0109: The root certificate of the signature in the app package or bundle must be trusted`, the certificate landed in the **Current User** store instead of **Local Machine** — the AppX Deployment service that validates the signature runs as SYSTEM and only checks Local Machine stores. Redo step 2, making sure to pick **Local Machine** in the wizard's first screen (it defaults to Current User).

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

Either way you installed it, this is a normal Windows package: **Settings → Apps → Installed apps**, find **F1Speed Feed Read**, and uninstall. Run **Reload** in Command Palette afterward if it's still listed.

## Building the package yourself

The `F1RssFeedRead/installer/` folder has everything needed to produce the same signed MSIX packages published in Releases:

```powershell
cd F1RssFeedRead/installer
.\build-msix.ps1 -Version "0.1.0"
```

This finds (or creates, on first run) a self-signed code-signing certificate matching the `Publisher` in `Package.appxmanifest` (`CN=dah007`), then publishes and packages the app as a signed, sideload-only MSIX for both `x64` and `ARM64`, plus exports the certificate's public half. Output lands in `F1RssFeedRead\installer\Release\`:

```text
Release/
├── x64/.../F1RssFeedRead_<version>_x64.msix
├── ARM64/.../F1RssFeedRead_<version>_arm64.msix
└── F1SpeedFeedRead.cer
```

**Why not a plain EXE installer?** Command Palette discovers extensions through Windows' `AppExtensionCatalog` API, which only enumerates *installed packages* that declare the `com.microsoft.commandpalette` app extension in their manifest (see `Package.appxmanifest`) — it never scans COM registry entries directly. A registry-only registration (what an Inno Setup–style EXE installer would produce) is enough for *activating* the extension once Command Palette has found it, but not for being found in the first place. So the extension has to ship as a real package — MSIX here, rather than a Store listing — and installing it means trusting the signing certificate once, the same as for any other self-signed sideloaded app.

If you ever need a *different* signing certificate (e.g. a paid one from a CA), update `Publisher` in `Package.appxmanifest` to match its Subject exactly, and pass `-CertSubject` to `build-msix.ps1`. Never commit the `.pfx`/private key to the repo — only the exported `.cer` (public key) is meant to be distributed.

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
    └── build-msix.ps1                 # Builds the signed, sideloadable MSIX packages
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
