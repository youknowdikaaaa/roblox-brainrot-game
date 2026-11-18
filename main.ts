// Brainrot Bay — make.fun roblox-brainrot-01 entry (Node 22, standard
// library only). The game is this directory's Rojo project: the 3D
// world and the Luau scripts under src/ are built into game.rbxl with
// `rojo build default.project.json --output game.rbxl`, and this
// program hands the entry in. It copies game.rbxl, src/, screenshots/
// and PLAY.json from beside this file to /output and writes
// /output/dossier.json, the summary the judge reads, with the vendored
// make.fun library (vendor/makefun-roblox.ts, unchanged).
//
// The game itself: buy absurd brainrots off the conveyor belt, keep
// them on your base where they earn money every second, climb the
// rarity ladder to the Secret tier, lock your base against thieves,
// steal from unlocked bases, outrun the Slime Wave, and rebirth for
// permanent income. See README.md for the full loop.
//
// Every name under /output starts with a letter, a digit or _ and
// holds only letters, digits, . _ and -: the grader fails an entry
// whose output holds any other, so a file such as .gitkeep or
// .DS_Store copied in fails it. So src/ and screenshots/ are copied
// without any name that starts with a dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for
// /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
function notDotted(path: string): boolean {
  return !basename(path).startsWith('.');
}

/** Fail loudly instead of handing in a half-built entry. */
function mustExist(path: string, what: string): void {
  if (!existsSync(path)) {
    throw new Error(`Brainrot Bay: missing ${what} at ${path} — rebuild with rojo first.`);
  }
}

/** Count the files a directory tree holds, for the build log. */
function countFiles(dir: string): number {
  let total = 0;
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    total += statSync(path).isDirectory() ? countFiles(path) : 1;
  }
  return total;
}

function copyEntry(): void {
  mkdirSync(out, { recursive: true });

  mustExist(join(here, 'game.rbxl'), 'the Rojo-built place (game.rbxl)');
  mustExist(join(here, 'PLAY.json'), 'PLAY.json');
  mustExist(join(here, 'src'), 'src/');

  copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
  copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
  cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
  mkdirSync(join(out, 'screenshots'), { recursive: true });
  if (existsSync(join(here, 'screenshots'))) {
    cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });
  }
}

function writeDossier(): void {
  // The scorer's own caps (reference/gate.json): only text_max_bytes
  // shapes the bytes; the others refuse an entry the scorer would
  // refuse (more than 4 screenshots or one over 256 KiB; a place of
  // more than 500000 instances, whose scripts' sources come to over
  // 8 MiB or whose scripts' paths come to over 1048576 characters).
  writeFileSync(
    join(out, 'dossier.json'),
    buildDossier(out, {
      text_max_bytes: 65536,
      screenshots: { max: 4, max_bytes: 262144 },
      max_instances: 500000,
      scripts_max_source_bytes: 8388608,
      scripts_max_path_chars: 1048576,
    }),
  );
}

copyEntry();
writeDossier();
console.log(
  `Brainrot Bay handed in: ${countFiles(join(out, 'src'))} script files, `
  + `${countFiles(join(out, 'screenshots'))} screenshots, dossier written.`,
);
