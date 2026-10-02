# ATM10 fork — server, custom pack, and promote pipeline

This repo is a **fork of [AllTheMods/ATM-10](https://github.com/AllTheMods/ATM-10)** (Minecraft **1.21.1**, **NeoForge**).

Official ATM-10 on GitHub is **configs, KubeJS, datapacks** — not the CurseForge mod jars. Clients still install **All the Mods 10** from CurseForge/Prism, then pull **this fork’s overlay** so your extra mods and configs stay in sync with the live server.

## Folders on this Mac

| Path | What it is |
| --- | --- |
| `/Users/enricokallaste/atm10-instances/prod` | **Live** world + pack. Docker `atm10-live` on port 25565. |
| `/Users/enricokallaste/atm10-instances/prod-next` | Background **next** pack (throwaway world). Docker `atm10-next` on 25566. |
| `/Users/enricokallaste/atm10-instances/prod-snapshot` | Pack snapshot for rollback (no world). |
| `/Users/enricokallaste/atm10-instances/test` | Test overlay target (not Docker). |
| `/Users/enricokallaste/atm10-stock/ServerFiles-8.2` | Official ATM10 8.2 pack (read-only bootstrap source). |
| `/Users/enricokallaste/atm10-server` | Git fork + GitHub Actions. |

Create instances from the 8.2 stock pack:

```bash
chmod +x scripts/*.sh
./scripts/bootstrap-instance.sh /Users/enricokallaste/atm10-instances/prod
./scripts/bootstrap-instance.sh /Users/enricokallaste/atm10-instances/test
```

Put extra jars in `custom/mods/` then run `./scripts/apply-overlay.sh` on prod and/or test (or bootstrap again). Overlay copies those jars into instance `mods/` folders.

The 12 extra mods are listed in `custom/EXTRA_MODS.md`.

Prod and test are **ATM10 8.2** (464 stock mods + 12 extras = 476). GitHub ATM-10 `main` is the same 8.2 config generation.

`custom/overrides/server.properties` and `user_jvm_args.txt` apply to prod/test.

## Branches

| Branch | Role |
| --- | --- |
| `upgrade` | Incoming ATM-10 updates + your WIP. GitHub Action promotes to `test`. |
| `test` | Staging. After pack tests pass, git fast-forwards `prod` and `deploy.sh` starts a zero-player cutover. |
| `prod` | Live pack. Deploy prepares `next`, waits for 0 players, then overlays live. |

Do not commit worlds, logs, or `.jar` files. Put extra jars in `custom/mods/` on the machine (gitignored) or attach them to GitHub Releases.

## Your custom content

Put files that should **win over** ATM-10 in the same relative paths under `custom/overrides/`:

```
custom/overrides/config/...
custom/overrides/kubejs/...
custom/overrides/defaultconfigs/...
custom/overrides/datapacks/...
```

- Extra **server + client** mods: `custom/mods/` (same filenames you want in `mods/`)
- Extra **client-only** mods: `custom/client-mods/`
- Mods to **delete** from an ATM server pack (client-only junk, etc.): `custom/remove-mods.txt` (one filename glob per line)

`scripts/apply-overlay.sh` copies overrides on top of an ATM-10 tree and stamps `config/bcc-common.toml` with `VERSION` so Better Compatibility Checker can nag outdated clients.

## Pull ATM-10 into `upgrade`

```bash
git remote add upstream https://github.com/AllTheMods/ATM-10.git   # already set locally
git fetch upstream main
git checkout upgrade
git merge upstream/main
git push origin upgrade
```

A scheduled workflow also tries this merge. If Git reports conflicts, fix them on `upgrade` and push.

## GitHub Actions pipeline

```
push upgrade  →  validate  →  push test
push test     →  pack test (+ optional smoke)  →  push prod
push prod     →  GitHub Release (client/server overlay zips)
              →  Mac self-hosted runner: deploy.sh (Docker blue-green)
```

`deploy.sh` waits until **0 players**, then cuts over. It does **not** kick players. Failed new live boot restores pack from `prod-snapshot`.

### One-time GitHub setup

1. Create a **private** repo and push all three branches:

   ```bash
   brew install gh   # if needed
   gh auth login
   gh repo create atm10-server --private --source . --remote origin
   git push -u origin upgrade test prod
   ```

2. **Settings → Actions → General**: allow Actions. Workflows need `contents: write` (default `GITHUB_TOKEN` is enough to push branches).

3. **Self-hosted runner on this Mac** (Docker Desktop must be running):

   - Repo → Settings → Actions → Runners → New self-hosted runner (macOS).
   - Labels: `self-hosted` and **`minecraft-prod`** (required by `deploy-prod.yml`).
   - Install runner as a service so it stays online.
   - In the **atm10-server** checkout the runner uses (or next to `deploy.sh`), keep `deploy.env` + `.env` with `LIVE_SERVER_DIR`, `NEXT_SERVER_DIR`, `SNAPSHOT_DIR`.

4. Variables (optional):

   | Name | Purpose |
   | --- | --- |
   | `ENABLE_SMOKE_TEST=true` | Also boot Minecraft on a `minecraft-test` runner before promoting |
   | `SKIP_LIVE_DEPLOY=true` | Publish overlay Release only; skip Docker cutover |

Normal flow after setup: push (or merge) to **`upgrade`** and Actions carries it through **test → prod → live Docker** when the server is empty.

## Clients on PCs

1. Install **All the Mods 10** matching the ATM version in `VERSION` (see `config/bcc-common.toml` on `prod` after overlay).
2. In Prism/CurseForge, set a **pre-launch command** to `scripts/update-client.sh` **or** run that script against the instance folder after each prod release.
3. The script downloads the latest GitHub Release asset `client-overlay.zip` from `prod` and extracts it into the instance (`mods/`, `config/`, `kubejs/`, …).

Until you push to GitHub, generate a local overlay:

```bash
./scripts/build-overlays.sh
```

## Live server (Docker on this Mac)

Give Docker Desktop **enough RAM for two JVMs while next is booting** (~12G live + ~12G next), then next is stopped after cutover.

First start (bind-mounts the live world; does not copy it):

```bash
docker compose up -d --build
docker compose logs -f minecraft
```

Players connect to this Mac on port **25565**. Container name: `atm10-live`.

### Cutover after `test` is good

```bash
./scripts/promote-test-to-prod.sh
```

`deploy.sh` does **not** kick players:

1. Snapshot live **pack** (mods/config/libraries, **not** `world/`) to `prod-snapshot`.
2. Build `prod-next`, apply overlay, boot `atm10-next` on **127.0.0.1:25566** with an empty throwaway world.
3. If next fails health-check, **stop next and leave live running**.
4. If next is healthy, stop next (free RAM), then poll live player count until **0** (no timeout, no force restart).
5. Stop live, apply overlay onto `prod` (**world stays**), start `atm10-live`, health-check.
6. On success: stop next. On live boot failure: restore pack from snapshot, start live again.

Rollback never replaces `prod/world`.

Overlay any instance folder (clients, test):

```bash
./scripts/apply-overlay.sh /path/to/ATM10-instance
```
