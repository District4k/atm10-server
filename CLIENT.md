# Client setup (recommended)

Players should **not** download every ATM jar from this repo. Use official ATM10, then pull **only our extras**.

## What you need

Downloads use the public GitHub Releases on [District4k/atm10-server](https://github.com/District4k/atm10-server) (no login needed for the overlay zip).

1. **All the Mods 10** from CurseForge / Prism — same pack version as the live server (currently **8.2**).
2. This overlay updater (extra mods + configs from [District4k/atm10-server](https://github.com/District4k/atm10-server)).

When the server adds or updates extras, a GitHub Release publishes `client-overlay.zip`. The updater downloads that into your instance before launch.

## One-time setup (Prism Launcher)

1. Install **Prism Launcher**.
2. Add instance → CurseForge → **All the Mods 10** → version **8.2** (or whatever matches the server).
3. Instance → **Settings → Custom commands** → enable pre-launch:
   ```bash
   /Users/enricokallaste/atm10-server/scripts/update-client.sh "$INST_DIR"
   ```
   Friends on other PCs: clone/copy this repo (or just `scripts/update-client.sh`) and point the path at their copy. The script defaults to repo `District4k/atm10-server`.
4. Launch the instance once. The overlay installs into `mods/` and `config/`.

### CurseForge app

Same idea: install ATM10 8.2, then run:

```bash
./scripts/update-client.sh "/path/to/CurseForge/Instances/All the Mods 10"
```

Or add that as a shortcut / shell alias before playing.

## Manual update (any time)

```bash
cd ~/atm10-server   # or wherever the script lives
./scripts/update-client.sh /path/to/your/ATM10-instance
```

## For the host (you)

- Put shared extras in `custom/mods/`, client-only extras in `custom/client-mods/`.
- Promote `upgrade → test → prod` (or `./scripts/promote-test-to-prod.sh`).
- Prod Action publishes a new Release with `client-overlay.zip`.
- Players get it automatically on next launch if pre-launch is set.

Better Compatibility Checker uses our stamped `VERSION` (e.g. `8.2-custom.1`) so outdated overlays can warn on join.

## Do not

- Mix a different ATM10 base version than the server.
- Hand-copy random jars without the overlay (easy to desync).
- Replace the whole `mods` folder with a full redistributed ATM pack.
