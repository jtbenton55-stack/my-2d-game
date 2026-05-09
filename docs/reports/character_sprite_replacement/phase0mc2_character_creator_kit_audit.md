# 0M-C2 Character Creator Kit Audit

Kit structure: layer-based PVGames Character Creator Kit, not ready-made complete character exports.
PNG count observed: 384; spritesheet count observed: 192; Female spritesheets observed: 98.
Female layer categories found: Base, Head, Hair, Tops, Bottoms, Accessories, Weapons.
All sampled core layers were 10000x10000 PNG spritesheets with alpha and aligned frames.
No README/docs found in the kit folder.
Animation layout exists but direction semantics were not documented, so no directional animation was promoted.
Safest route: generate one static composite from obvious same-size layers and add it as visual-only child.
