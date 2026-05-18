# Asset Pack Checksums

SHA-256 baseline de zips CC0 descargados. Si re-bajás y cambia → investigar (publisher actualizó pack, o algo raro).

**Nota**: `_raw/` está en `.gitignore`, pero este CHECKSUMS.md sí se commitea — vive arriba de `_raw/`.

## Kenney

| Pack | Archivo | SHA-256 | Bajado |
|------|---------|---------|--------|
| Particle Pack | `kenney_particle-pack.zip` | `b631d4b07f7002549fdcf155f01141ad482f79f3440e4e301eed49ce5f1d8958` | 2026-05-18 |
| Fantasy Town Kit | `kenney_fantasy-town-kit.zip` | `1a7530c09f4d2fa2cdee259876f089334f8b1f27fa86a0c4f54ef86cdd8676ef` | 2026-05-18 |

## Quaternius

| Pack | Archivo | SHA-256 | Bajado |
|------|---------|---------|--------|
| Ultimate Modular Men (Feb 2022) | `quaternius_ultimate-modular-men.zip` | `716f4666605edfcae22b23372d4a617a9bea6867f2b67476cd43deba80b2b609` | 2026-05-18 |
| Ultimate Monsters | `quaternius_ultimate-monsters.zip` | `cf7c57d23976bc9c2ee25f1687a607dc8f925e44e5f41c6e3ef4b21c36a26311` | 2026-05-18 |
| Ultimate Stylized Nature (May 2022) | `quaternius_ultimate-stylized-nature.zip` | `9765b0a3c597f14dbdfdea98a2e2b5ed6d63f1ad825adee311df308909c02d4a` | 2026-05-18 |

## Verificación

```bash
cd game/assets/art/_raw/kenney/
sha256sum -c <(grep -E "kenney_(particle|fantasy)" ../CHECKSUMS.md | awk '{print $NF, $(NF-2)}' | sed 's/`//g')
```

(O comparación manual visual.)
