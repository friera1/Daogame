# Visual assets plan

## Current visual direction
- xianxia / cultivation fantasy
- jade + gold palette
- misty mountain backgrounds
- premium vertical mobile composition
- elegant male cultivator hero as the central identity

## Generated asset set
These assets have already been generated for the project and should be imported into `assets/art/generated/` inside Godot:

1. `hero_fullbody_primary.png`
   - main lobby hero showcase
   - full-body standing cultivator

2. `lobby_background_primary.png`
   - main lobby background
   - floating mountains, pagodas, sunrise sky, empty space for UI overlays

3. `cultivation_background_primary.png`
   - cultivation screen background
   - meditating hero with qi circle and jade talismans

4. `hero_portrait_primary.png`
   - character screen portrait art
   - profile / card illustration

## Integration targets
- `scenes/lobby/LobbyScreen.tscn`
  - background art
  - hero showcase art
- `scenes/cultivation/CultivationScreen.tscn`
  - cultivation scene illustration
- `scenes/character/CharacterScreen.tscn`
  - portrait art
- later:
  - battle background
  - inventory card icons
  - skill icons
  - pet cards

## Immediate next implementation
1. Put generated art into `assets/art/generated/`
2. Replace ColorRect placeholders with TextureRect nodes
3. Add import presets and scale mode rules
4. Add soft glow / parallax movement in lobby
5. Add subtle qi VFX overlays via Control / CanvasLayer

## Notes
The current repository bootstrap uses placeholders so the project stays launchable even before all binary assets are committed.
