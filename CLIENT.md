# Client setup (recommended)

Players should **not** download every ATM jar from this repo. Use official ATM10, then pull **only our extras**.

## What you need

Downloads use the public GitHub Releases on [District4k/atm10-server](https://github.com/District4k/atm10-server) (no login needed for the overlay zip).

1. **All the Mods 10** from CurseForge / Prism — same pack version as the live server (currently **8.2**).
2. That pack must use **NeoForge 21.1.251** (ATM10 8.2’s loader). The live server rejects other NeoForge builds with `incompatible client! Please use NeoForge 21.1.251`.
3. This overlay updater (extra mods + configs from [District4k/atm10-server](https://github.com/District4k/atm10-server)), including **GlitchCore** (required for Serene Seasons sync).

When the server adds or updates extras, a GitHub Release publishes `client-overlay.zip`. The updater downloads that into your instance before launch.

## One-time setup (Windows — Prism or CurseForge)

Server pack version to match: **ATM10 8.2** / **NeoForge 21.1.251**.

### A. After ATM10 finished downloading

1. Confirm the instance is **All the Mods 10** version **8.2** (not 8.1 or a random “latest”).
2. In Prism → instance **Settings → Version**, confirm loader is **NeoForge 21.1.251**. If not, reinstall ATM10 **8.2** (do not hand-pick a different NeoForge).
3. Download the Windows updater:
   - Open: https://raw.githubusercontent.com/District4k/atm10-server/prod/scripts/update-client.ps1  
   - Save as e.g. `C:\Games\atm10-update\update-client.ps1`
4. Find your instance folder:
   - **Prism:** right‑click instance → **Folder** / **Open folder**
   - **CurseForge:** instance → ⋮ → **Open folder**  
     Often under `%USERPROFILE%\curseforge\minecraft\Instances\...`
5. Run **once** in PowerShell (fix your instance path):

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Games\atm10-update\update-client.ps1" "C:\path\to\your\ATM10\instance"
```

6. You should see it download `client-overlay.zip`, report that **GlitchCore** (and other extras) were applied, and finish with `OK`. Then launch Minecraft and join the server.

### B. Auto-update every launch (recommended)

**Prism → instance Settings → Custom commands → Pre-launch command:**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Games\atm10-update\update-client.ps1" "$env:INST_DIR"
```

Each start pulls the newest overlay from GitHub before the game opens.

## One-time setup (macOS / Linux — Prism)

1. Install **Prism Launcher**.
2. Add instance → CurseForge → **All the Mods 10** → version **8.2** (NeoForge **21.1.251**).
3. Instance → **Settings → Custom commands** → pre-launch:
   ```bash
   /path/to/atm10-server/scripts/update-client.sh "$INST_DIR"
   ```
4. Launch once so the overlay installs (script must print that GlitchCore was found).

### CurseForge app (macOS / Linux)

```bash
./scripts/update-client.sh "/path/to/CurseForge/Instances/All the Mods 10"
```

## Manual update (any time)

**Windows:**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Games\atm10-update\update-client.ps1" "C:\path\to\ATM10-instance"
```

**macOS / Linux:**

```bash
./scripts/update-client.sh /path/to/your/ATM10-instance
```

After a server-side overlay fix, re-run the updater (or restart Prism so pre-launch runs) before joining again.

## For the host (you)

- Put shared extras in `custom/mods/`, client-only extras in `custom/client-mods/`.
- Keep a GitHub Release tag `extra-mods` with `extra-mods.zip` so CI can build overlays (jars are gitignored).
- Promote `upgrade → test → prod` (or `./scripts/promote-test-to-prod.sh`).
- Prod Action publishes a new Release with `client-overlay.zip` (must include the 12 jars from `custom/EXTRA_MODS.md`).
- Players get it automatically on next launch if pre-launch is set.

Better Compatibility Checker uses our stamped `VERSION` (e.g. `8.2-custom.1`) so outdated overlays can warn on join.

## Do not

- Mix a different ATM10 base version than the server (8.1 → NeoForge 21.1.249 will be kicked).
- Hand-copy random jars without the overlay (easy to desync).
- Replace the whole `mods` folder with a full redistributed ATM pack.
- Join without GlitchCore — you get `glitchcore:sync_config` / “channel is missing on the client”.

## Version mismatch warning

Better Compatibility Checker stamps our overlay `VERSION` (for example `8.2-custom.1`). If the **live server** already updated and your client overlay is old, you get a pack-version warning on join — run `update-client.ps1` / `update-client.sh` (or restart Prism so pre-launch runs) and try again.

While an update is waiting to apply (players still online), the **server chat** also announces that a new version is ready and asks people to log off when convenient.
