# ATM10 fork — server, custom pack, and promote pipeline

This repo is a **fork of [AllTheMods/ATM-10](https://github.com/AllTheMods/ATM-10)** (Minecraft **1.21.1**, **NeoForge**).

Official ATM-10 on GitHub is **configs, KubeJS, datapacks** — not the CurseForge mod jars. Clients still install **All the Mods 10** from CurseForge/Prism, then pull **this fork’s overlay** so your extra mods and configs stay in sync with the live server.

## Folders on this Mac

| Path | What it is |
| --- | --- |
| `/Users/enricokallaste/atm10-instances/prod` | **Live server**: ATM10 8.2, extra mods, world, players. Screen `atm10-prod`. |
| `/Users/enricokallaste/atm10-instances/test` | Staging / smoke tests. Screen `atm10-test`. |
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
| `test` | Staging. After tests pass, Action promotes to `prod`. |
| `prod` | Live pack. Action uploads overlays and restarts the Minecraft server. |

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

## GitHub setup (once)

1. Create a **private** GitHub repo and push all three branches:

   ```bash
   gh repo create atm10-server --private --source . --remote origin
   git push -u origin upgrade test prod
   ```

2. Repo **Settings → Actions → General**: allow Actions, and allow Actions to **create and approve pull requests** is not required; workflows **push** `upgrade → test → prod` with `contents: write`.

3. **Self-hosted runner** on the machine that runs Minecraft (same idea as your older 1.20.1 pack):

   - Label it `minecraft-prod` (prod deploy) and optionally `minecraft-test` (full boot smoke test).
   - Copy `deploy.env.example` to `deploy.env` **on the runner host** (not in git). Point `LIVE_SERVER_DIR` at `/Users/enricokallaste/atm10-instances/prod` and `TEST_SERVER_DIR` at `.../test`.

4. Secrets / variables:

   | Name | Where | Purpose |
   | --- | --- | --- |
   | `ENABLE_SMOKE_TEST` | Actions variable `true` | `test` also boots Minecraft on a runner labeled `minecraft-test` |
   | `ENABLE_LIVE_DEPLOY` | Actions variable `true` | After overlay zips are published, restart the live server on `minecraft-prod` |
   | (none required for promote) | | `GITHUB_TOKEN` is enough to push branches |

   Set **ENABLE_LIVE_DEPLOY=true** only after the `minecraft-prod` runner is online, or the deploy job is skipped and you still get GitHub Release zips.

## Clients on PCs

1. Install **All the Mods 10** matching the ATM version in `VERSION` (see `config/bcc-common.toml` on `prod` after overlay).
2. In Prism/CurseForge, set a **pre-launch command** to `scripts/update-client.sh` **or** run that script against the instance folder after each prod release.
3. The script downloads the latest GitHub Release asset `client-overlay.zip` from `prod` and extracts it into the instance (`mods/`, `config/`, `kubejs/`, …).

Until you push to GitHub, generate a local overlay:

```bash
./scripts/build-overlays.sh
```

## Local apply (no GitHub)

```bash
./scripts/apply-overlay.sh /path/to/ATM10-server-or-client-instance
```
