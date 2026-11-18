# Brainrot Bay — roblox-brainrot-01

A working entry for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01): a 3D
Steal-a-Brainrot-style game built as a Rojo project, with its own cast, world and game loop.

## The game

You spawn in Brainrot Bay, a grass arena with a conveyor belt down the middle and eight coloured base plots
around the edge. Brainrots walk the belt from the arch to the far end — click one to buy it, and it moves onto
your base, where it earns money every second at its own rate. Save up, buy rarer ones, and climb the ladder
from Pipino Picklefoot ($50, $1/s) to The Final Boss Baby ($10,000,000, $120,000/s).

- **The cast:** 24 original brainrots across 7 rarities (Common, Rare, Epic, Legendary, Mythic, Brainrot God,
  Secret), each with a name, a blurb, a body colour and a readable name / rarity / $‑per‑second label. Spawns
  can mutate Golden (x3), Diamond (x5) or Rainbow (x10).
- **Stealing:** click a brainrot on another player's base to steal it — if their base isn't locked. Carry it
  home above your head while the owner chases you: get slapped within range and it goes straight back.
  Lock your own base for 60 seconds when you need to breathe.
- **Hazards and events:** the Slime Wave sweeps the map every few minutes — anyone caught outside their own
  base loses 5% of their cash and gets thrown back to spawn. Golden Hour doubles all income for 60 seconds;
  Mutation Surge makes the next three spawns guaranteed Golden.
- **Progression:** rebirths (reset cash and base for a permanent +25% income each), and two upgrades —
  Swift Sneakers (+walk speed) and Money Magnet (+income) — five levels each.
- **The world:** a built 3D map — conveyor belt with neon rails and a BRAINROT BAY arch, eight walled base
  plots with gates, a fountain, trees, lamps and fences — under a ScreenGui HUD showing cash, income, the
  next tier to save for, your base, and lock / rebirth / upgrade buttons.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot (such as
  `.gitkeep` or `.DS_Store`, which fail an entry), and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`:
  `rojo build default.project.json --output game.rbxl`.
- `src/shared/` — `Config.luau` (all tuning numbers and map coordinates) and `BrainrotCatalog.luau`
  (the 24 brainrots, rarities, mutations, money formatting).
- `src/server/` — one ModuleScript per job: `PlayerData` (the single state store), `BrainrotFactory`
  (builds a brainrot's 3D model), `WorldBuilder` (arch sign, fountain sparkles, plot signs, wave wall),
  `Conveyor` (spawning and walking the belt), `BrainrotService` (buying, income, stealing, locks,
  rebirths, upgrades, state sync), `EventService` (Slime Wave, Golden Hour, Mutation Surge), and
  `init.server.luau` (boots them in order).
- `src/client/Game.client.luau` — the HUD: cash, income, next tier, your base, buttons, event banner.
- `screenshots/` holds three captures of the game; the first by name is the cover and must also be the
  game's first thumbnail on Roblox. `PLAY.json` names the published place once it exists.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt,
which gives every command in order (Before you submit, then Enter).
