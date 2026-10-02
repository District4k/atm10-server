# Extra mods (not in official ATM10 8.2)

These 12 jars are the fork overlay. They are not in the ATM-10 **8.2** “Added mods” list (that only adds Copycats+, Just Enough Stuff, MezzConfig).

| Jar | Role |
| --- | --- |
| `legendarysurvivaloverhaul-1.21.1-2.4.7.2.jar` | Temperature / thirst / survival |
| `insanelib-2.4.32.0.jar` | Library for LSO |
| `Diet-1.21.1-NeoForge.jar` | Diet groups |
| `spectrelib-neoforge-0.17.1+1.21.jar` | Library for Diet |
| `SereneSeasons-neoforge-1.21.1-10.1.0.3.jar` | Seasons |
| `GlitchCore-neoforge-1.21.1-2.1.0.2.jar` | Library for Serene Seasons |
| `betterdays-1.21.1-3.3.6.3-NEOFORGE.jar` | Longer / better days |
| `Enhanced-Celestials-2-Core-NeoForge-1.21.1-2.0.3.3.jar` | Blood/harvest moons |
| `Enhanced-Celestials-2-Default-Lunar-Events-NeoForge-1.21.1-2.0.1.3.jar` | Default lunar events |
| `Data_Anchor-neoforge-1.21.1-2.0.0.16.jar` | Library (celestials stack) |
| `ExtremeZombieMoon-1.21-2.0.jar` | Extra zombie moon |
| `better_climbing-neoforge-4.jar` | Climbing |

Jars live in `custom/mods/` (gitignored). Matching configs live in `custom/overrides/config/`.

`apply-overlay.sh` copies them onto **atm10-instances/prod** and **test**.

For CI / GitHub `client-overlay.zip` builds, also publish those jars as release tag `extra-mods` / asset `extra-mods.zip` (see `scripts/seed-extra-mods.sh`). Without that, overlays ship with an empty `mods/` folder and Prism clients get kicked for missing `glitchcore:sync_config`.
