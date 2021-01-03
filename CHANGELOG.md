# Changelog

# 1.0.0-beta-2

### Code changes:
- Fixed a problem with the animation timer for the loading Forge objects menu
- Added a new crosshair state that prevents you to place objects in a prohibited area
- Fixed a problem with the count of buttons displayed in the map voting menu
- Added a debug message to print how many objects exist on the Forge objects database
- Added a new format to save the name of all the Forge maps using a standard convention with underscores

### Map changes:
- New shield effects (plasma shader / shields gone / shields recharging)
- New announcer dialogues (still WIP and incomplete, I have to make some custom ones for certain events)
- Rescaled crosshairs to match H4 MCC ones
- New armor set (Mariner/Mister Chief variant)
- "Locus" armor has been removed
- New player indicator (that arrow above your team mate)
- Fixed diffuse map for "Forerunner crate small" is now the correct one
- Added an experimental convenant shield object from Halo 1
- Removed covenant barricade from Forge objects list due to problems with the collision
- Removed useless monitor Forge weapon (to prevent grenades interface appearing on the HUD)
- Added new textures for the UNSC Crate Large object
- New collisions and model optimizations for:
  ### BARRICADES:
  - Barricade large

  ### CRATES:
  - Container large
  - Container open large
  - Container small
  - Crate large
  - Crate metal large
  - Crate metal small
  - Crate packing large
  - Crate packing small
  - Crate small
  - Forerunner crate packing
  - Forerunner crate small
  - Oni crate small
  - Oni crate thin

  ### STRUCTURES/FORGE ISLAND:
  - Artifact base

  ### BRIDGES AND PLATFORMS:
  - Bridge diag small
  - Bridge diagonal
  - Bridge large
  - Bridge xlarge
  - Platform large
  - Platform xlarge

  NATURAL
  - Rock 4

# 1.0.0-beta-1

### Code changes:
- Restored category and name text being displayed by looking at Forge objects
- Added current project version number on pause menu

### Map changes:
- Weapons max ammo has been changed to be the same as Halo 4
- New textures and shaders for the FP at the techsuit level
- Corrected model of the Recruit armor for the FP Hands
- Minor adjustment in the tonality of the water
- New Forge objects have been added:
  - Artifact Base
  - Crate Barrel
  - Crate Metal Large
  - Crate Metal Small
  - Forerunner Crate Packing
  - ONI Crate Cube
  - ONI Crate Large
  - ONI Crate Small
  - ONI Crate Thin
  - UNSC Container Large
  - UNSC Container Small
  - UNSC Crate Large

### Known issues
- In local/LAN mode a test biped can be spawned by pressing Ctrl + E
- Monitor crosshair does not change colors and it can even dissapear sometimes
- Forge objects menu options are reset when opening object properties