# Alpha Asset Packs — Opción C Canon

**Estado**: Canon — 2026-05-18 (post scope reset)
**Scope**: Solo Piso 1 Pradera (MVP demo, vertical slice 10 min)
**Reemplaza**: subset de `p1_assets_sourcing.md` §1 — para alpha mandan ESTOS 5 packs, no la lista vieja.

> Filtro vigente: "¿Esto acerca o aleja de los 5 mapas publicables?"
> Para alpha, 5 packs cubren ~90% del piso 1. No bajar packs extra hasta que se demuestre necesidad.

---

## 1. Los 5 packs

| # | Pack | URL | Cubre |
|---|------|-----|-------|
| 1 | Quaternius Ultimate Modular Characters | https://quaternius.com/packs/ultimatemodularcharacters.html | Warrior / Mage / Archer (mix armor diferencia clases) + bandit humanoids (E10, E11, E16 base) |
| 2 | Quaternius Ultimate Monsters | https://quaternius.com/packs/ultimatemonsters.html | Slime (E01-E03), golem (E13), spider (E07), monstruos genéricos. 50+ rigged. |
| 3 | Quaternius Ultimate Stylized Nature | https://quaternius.com/packs/ultimatestylizednature.html | Árboles, bushes, rocas, hierba, flores, hongos, helechos, cliffs. 300+ assets — pradera entera. |
| 4 | Kenney Fantasy Town Kit | https://kenney.nl/assets/fantasy-town-kit | Casas medievales 3D, muros, torres, props outpost. 100+. (Reemplaza "Medieval Kit" que no existe en Kenney actual). |
| 5 | Kenney Particle Pack | https://kenney.nl/assets/particle-pack | Sprites VFX (fuego, humo, magic, charge, projectiles). 100+ PNG sprites Kimetsu-feel. |

**Licencia**: los 5 son CC0 (uso comercial sin atribución). Donar opcional si monetizamos.
**Formato**: todos `.glb` (Kenney también ofrece `.fbx` / `.obj` — usar GLB, Godot 4 carga nativo).

---

## 2. Mapping rápido — qué pack para qué entidad

### Personajes jugables
- **Warrior** → Pack 1 (armor heavy variant)
- **Mage** → Pack 1 (robe variant)
- **Archer** → Pack 1 (light armor + bow accessory)

### Enemigos combate Piso 1
- **Bandit melee / archer / leader** (E10, E11, E16) → Pack 1 (armor + weapons variants)
- **Slime green / mini / water** (E01-E03) → Pack 2
- **Wolf / fox / bird crow / hawk / rat** (E04-E09) → **NO cubierto** (Quaternius Animated Animals fuera de scope alpha — usar CSG placeholder o agregar pack 6 si se necesita)
- **Spider / bat / snake** (E07, E12, E15) → Pack 2 (monsters)
- **Golem rock** (E13) → Pack 2

### Ambiente
- **Árboles / bushes / rocas / hierba / flores / cliffs** (V01-V12, N01-N05) → Pack 3
- **Empalizadas / torres / ruinas / casas outpost** (H01-H05, H11-H14) → Pack 4
- **Cofres / barriles / cajas / tiendas / fogatas / torches / gates** (H06-H10, H16) → Pack 4

### VFX
- **Charge / war_cry / projectiles / hit / magic** → Pack 5 (sprites)
- **Fuego campfire / humo chimney** → Pack 5

### Hero assets (NO en packs — AI gen / Blender)
- **N07 giant_diamond** → Meshy/Rodin (hero P0)
- **N06 crystal_ceiling** → Meshy + emission material
- **S01 cave_ceiling_dome** → Blender directo (UV sphere invertida)
- **S03 distant_mountains** → Krita billboards
- **U01/U02 portals** → Meshy + shader custom

**Gap conocido**: fauna animal (lobo/zorro/halcón/pájaro). Decisión scope reset: usar CSG/placeholder hasta que el slice 10 min los necesite. Si los necesita → agregar **Quaternius Ultimate Animated Animals** como pack 6.

---

## 3. Download steps

### Kenney (auto, Claude puede bajarlos)
URLs `.zip` directas. Comando:
```bash
cd game/assets/art/_raw/kenney/
curl -L -O https://kenney.nl/media/pages/assets/particle-pack/f8fe0f8cb8-1677578741/kenney_particle-pack.zip
curl -L -O https://kenney.nl/media/pages/assets/fantasy-town-kit/efe948d309-1754222374/kenney_fantasy-town-kit_2.0.zip
```

### Quaternius (manual, Joan)
Botón Download usa modal JS a Google Drive — no URL directa fetchable. 3 clicks:
1. https://quaternius.com/packs/ultimatemodularcharacters.html → click Download → guardar como `_raw/quaternius/ultimate-modular-characters.zip`
2. https://quaternius.com/packs/ultimatemonsters.html → idem → `_raw/quaternius/ultimate-monsters.zip`
3. https://quaternius.com/packs/ultimatestylizednature.html → idem → `_raw/quaternius/ultimate-stylized-nature.zip`

Descomprimir cada uno en carpeta paralela (`_raw/quaternius/ultimate-modular-characters/`).
**No commitear** `_raw/` — ya está en `.gitignore`.

Tamaño total estimado: ~400-500 MB raw (zips + extracted).

**Nota Modular Characters**: el pack se llama "Ultimate Modular MEN Pack" en quaternius. Si necesitamos Mage femenina post-alpha, agregar `ultimatemodularwomen.html`.

---

## 4. Workflow extraction → asset oficial

Por cada asset que se necesite (no copiar todo el pack):

1. Buscar mesh dentro de `_raw/{kenney|quaternius}/{pack}/Models/` (o `glTF/`).
2. Abrir en Blender → ajustar escala 1u=1m + pivot a base + simplificar material si trae PBR pesado.
3. Export `.glb` con nombre canon `{prefix}_{descripcion}.glb` (ver README `piso1_pradera/`).

### 4.1 Tier I canon — sin normal maps / PBR

Por canon `visual_bible.md` §P1, baseline Tier I = **sin normal maps, sin PBR**. Quaternius packs incluyen normal maps grandes (ej. `BirchTree_Bark_Normal.png` = 22 MB). Workflow:

- **Borrar** `*_Normal.png` post-extraction.
- **Editar JSON** del `.gltf`: sacar `normalTexture` field del material, sacar la entry de `images[]` y `textures[]` correspondiente, renumerar índices.
- **Originales conservados en `_raw/`** — si más adelante Tier II / hero closeup necesita PBR, re-extract desde raw + re-edit JSON.

Alternativa más limpia (cuando haya Blender): re-export como `.glb` binario con PBR strip aplicado, evita edit manual JSON.
4. Mover a subcarpeta correcta:
   - `terrain/` → tiles suelo
   - `vegetation/` → árboles/bushes/grass/flowers
   - `props/{rocks|ceiling|water|outpost|ruins|common}/` → props decorativos
   - `enemies/` → meshes + animaciones enemy
   - `skybox/` → dome + billboards
5. Import en Godot → verificar con lighting canon P1.
6. Commit: `art(p1): add <prefix>_<nombre> from <pack>`.

---

## 5. Próximos pasos (post-descarga)

1. **P0 hoy**: Joan descarga los 5 zips → `_raw/` (manual, ~10 min).
2. **P0 siguiente**: extraer **`env_tree_oak_01`** desde Stylized Nature, importar Godot con lighting canon, screenshot baseline.
3. **P0 después**: extraer **`char_warrior_base`** desde Modular Characters, reemplazar cápsula azul Warrior.
4. **P1**: extraer enemy básico (`enemy_slime_green` desde Monsters), reemplazar cubo rojo enemy_basic.
5. **P1**: arrancar iteración hero **N07 giant_diamond** en Meshy/Rodin.

---

## 6. Links cruzados

- README estructura: `game/assets/art/piso1_pradera/README.md`
- Lista completa assets P1: `game/docs/art/p1_pradera.md`
- Sourcing detallado (legacy, pre scope reset): `game/docs/art/p1_assets_sourcing.md`
- Visual canon: `game/docs/art/_art_direction_bible.md` + `visual_bible.md` §P1
- Pipeline ops: `game/docs/art/_visual_pipeline.md`
