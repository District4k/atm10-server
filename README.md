# ATM10 custom server (District4k)

Private-group fork of **[All the Mods 10](https://www.curseforge.com/minecraft/modpacks/all-the-mods-10)** (Minecraft **1.21.1**, **NeoForge**).

Upstream configs/KubeJS: [AllTheMods/ATM-10](https://github.com/AllTheMods/ATM-10).  
This repo adds **extra mods**, **Docker live hosting**, **upgrade → test → prod**, and a **client overlay** so players stay in sync.

| | |
| --- | --- |
| Pack base | ATM10 **8.2** |
| Custom version | See [`VERSION`](VERSION) (e.g. `8.2-custom.1`) |
| Live host | Docker on the Mac (`atm10-live`, port **25565**) |
| GitHub | https://github.com/District4k/atm10-server |

---

## Quick links

| I want to… | Read |
| --- | --- |
| **Play (Windows / Prism)** | **[CLIENT.md](CLIENT.md)** |
| Run / update the **server** | **[SERVER.md](SERVER.md)** |
| See which **extra mods** we added | **[custom/EXTRA_MODS.md](custom/EXTRA_MODS.md)** |

---

## How it fits together

```
Official ATM10 8.2 (CurseForge)
        +
This repo’s overlay (extra mods + configs)
        =
What players and the live server run
```

- We do **not** re-upload the whole ATM modpack.
- Extras live in `custom/mods/` (and optional `custom/client-mods/`).
- On every **prod** release, GitHub publishes `client-overlay.zip` for players.

```
upgrade  →  test (checks)  →  prod
                              ├─ GitHub Release (client/server overlay zips)
                              └─ Docker live: wait for 0 players → cut over
                                 (chat announces new VERSION; rollback if boot fails)
```

---

## Players (client)

1. Install **All the Mods 10 version 8.2** in Prism / CurseForge.
2. Run our updater so extras download from GitHub Releases.
3. Launch and join the server.

**Windows (after ATM10 is installed):**

1. Save [update-client.ps1](https://raw.githubusercontent.com/District4k/atm10-server/prod/scripts/update-client.ps1)  
   e.g. to `C:\Games\atm10-update\update-client.ps1`
2. Open your ATM10 instance folder in Prism/CurseForge.
3. Run once in PowerShell (use your real instance path):

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Games\atm10-update\update-client.ps1" "C:\path\to\ATM10\instance"
```

4. Optional — Prism **Pre-launch command** (auto-update every start):

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Games\atm10-update\update-client.ps1" "$env:INST_DIR"
```

Full guide (Windows + Mac): **[CLIENT.md](CLIENT.md)**.

If the server is newer than your overlay, **Better Compatibility Checker** warns on join — run the updater again.

---

## Host (server)

### Folders (this Mac)

| Path | Role |
| --- | --- |
| `~/atm10-instances/prod` | Live world + pack |
| `~/atm10-instances/test` | Staging |
| `~/atm10-stock/ServerFiles-8.2` | Official 8.2 stock (read-only) |
| `~/atm10-server` | This git repo |

### Start live (Docker Desktop on, enough RAM)

```bash
cd ~/atm10-server
docker compose up -d --build
docker compose logs -f minecraft
```

### After changing extras / configs

```bash
# put jars in custom/mods/, bump VERSION if you want
git checkout upgrade
# commit & push upgrade  →  Actions: test → prod → release + deploy
# or locally:
./scripts/promote-test-to-prod.sh
```

Deploy **does not kick players**. Chat announces the new version; cutover happens at **0 players**. Failed boot restores the previous pack (world kept).

Details: **[SERVER.md](SERVER.md)**.

---

## Branches & Actions

| Branch | Purpose |
| --- | --- |
| `upgrade` | ATM upstream merges + WIP |
| `test` | Pack checks; then promotes to `prod` |
| `prod` | Release overlays + live Docker cutover |

Mac needs a GitHub **self-hosted runner** labeled `minecraft-prod` for automatic live deploys. Until then you can set `SKIP_LIVE_DEPLOY=true` and run Docker/deploy locally.

---

## Repo layout

```
custom/
  mods/           # extra jars (gitignored; shipped via Releases)
  client-mods/    # client-only extras
  overrides/      # configs that win over ATM defaults
  EXTRA_MODS.md   # list of extras
scripts/
  update-client.ps1 / update-client.sh
  deploy.sh / promote-test-to-prod.sh / …
compose.yaml      # atm10-live (+ atm10-next for pre-checks)
VERSION           # stamped into BCC for clients
```

---

## Attribution

Pack content and most configs come from **All the Mods 10** by the ATM team.  
Upstream issue tracker / pack README: [AllTheMods/ATM-10](https://github.com/AllTheMods/ATM-10).
