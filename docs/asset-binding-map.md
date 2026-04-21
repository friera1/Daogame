# Asset binding map

This file maps generated art assets to scene slots.

## Expected imported files
Place these files in `assets/art/generated/`:
- `hero_fullbody_primary.png`
- `lobby_background_primary.png`
- `cultivation_background_primary.png`
- `hero_portrait_primary.png`
- `battle_background_primary.png`
- `shop_banner_primary.png`
- `summon_banner_primary.png`

## Scene bindings
### Lobby
Scene: `scenes/lobby/LobbyScreen.tscn`
- `LobbyBackgroundArt` -> `res://assets/art/generated/lobby_background_primary.png`
- `HeroArt` -> `res://assets/art/generated/hero_fullbody_primary.png`

### Cultivation
Scene: `scenes/cultivation/CultivationScreen.tscn`
- `CultivationBackgroundArt` -> `res://assets/art/generated/cultivation_background_primary.png`
- `MeditationArt` -> `res://assets/art/generated/cultivation_background_primary.png`

### Character
Scene: `scenes/character/CharacterScreen.tscn`
- `CharacterBackgroundArt` -> `res://assets/art/generated/hero_portrait_primary.png`
- `PortraitArt` -> `res://assets/art/generated/hero_portrait_primary.png`

### Battle
Scene: `scenes/battle/BattleScreen.tscn`
- `BattleBackgroundArt` -> `res://assets/art/generated/battle_background_primary.png`
- `ArenaBackdropArt` -> `res://assets/art/generated/battle_background_primary.png`

### Shop
Scene: `scenes/shop/ShopScreen.tscn`
- `ShopBackgroundArt` -> `res://assets/art/generated/lobby_background_primary.png`
- `BannerArt` -> `res://assets/art/generated/shop_banner_primary.png`

### Summon
Scene: `scenes/shop/SummonScreen.tscn`
- `SummonBackgroundArt` -> `res://assets/art/generated/lobby_background_primary.png`
- `BannerArt` -> `res://assets/art/generated/summon_banner_primary.png`

## Integration checklist
1. Import PNG files into `assets/art/generated/`
2. Open each scene and assign textures to the listed `TextureRect` nodes
3. Verify `stretch_mode` visually on a 720x1280 viewport
4. Adjust `self_modulate` and overlay tint values for readability
5. Replace placeholder labels once art is confirmed in-engine

## Next art tasks
- battle background art
- shop banner art
- summon banner art
- icon set for skills, items and pets
- 9-slice ornamental UI frames
- glow/VFX overlays for cultivation and summon
