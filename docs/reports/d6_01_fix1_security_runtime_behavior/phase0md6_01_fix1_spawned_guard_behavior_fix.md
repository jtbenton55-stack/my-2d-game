# Spawned guard behavior fix

Chase uses existing `EnemyBase` / `Guard` AI. FIX1 adds **spawn offset**, **soft chase** meta, **fallback patrol ring** when security-spawned, and avoids **wrong default patrol** binding that pulled guards to unrelated world coordinates.
