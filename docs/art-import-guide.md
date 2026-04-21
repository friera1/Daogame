# Art import guide

## Folder layout
- `assets/art/generated/hero_fullbody_primary.png`
- `assets/art/generated/lobby_background_primary.png`
- `assets/art/generated/cultivation_background_primary.png`
- `assets/art/generated/hero_portrait_primary.png`

## Godot usage
### Lobby
- background: full-screen `TextureRect`
- hero: centered `TextureRect` with preserve aspect fit
- additional light swirls: overlay `TextureRect` or shader later

### Cultivation
- use a single large background illustration
- keep UI panels semi-transparent above it

### Character screen
- portrait `TextureRect`
- optional gold frame overlay later

## Texture recommendations
- compression: use default import first
- size: keep originals, but prepare 720x1280 and 1080x1920 variants later
- filtering: enabled
- repeat: disabled

## Follow-up tasks
- generate transparent VFX sprites
- generate icon set for inventory / skills / pets
- create 9-slice UI frames in jade/gold theme
