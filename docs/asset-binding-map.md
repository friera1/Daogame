# Asset binding map

This file maps generated art assets to scene slots.

## Expected imported files
Place these files in `assets/art/generated/`:
- `hero_fullbody_primary.png`
- `lobby_background_primary.png`
- `cultivation_background_primary.png`
- `hero_portrait_primary.png`

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

## Next art tasks
- battle background art
- shop banner art
- summon banner art
- icon set for skills, items and pets
- 9-slice ornamental UI frames
