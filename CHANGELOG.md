# Changelog

# 1.0.0-beta-4
## Code changes:
- General optmization for object spawn requests.
- Fixed a problem with Forge maps at saving garbage properties.
- Moved `fspawn` command to normal commands instead of debug commands.
- Fixed oddball game mode spawning.
- Added feature to hide Forge spawn objects when in spartan mode.
- Added support for teleporters and object colors

# 1.0.0-beta-3
## Code changes:
- Improved performance and security in general
- Restored colors for different crosshair states as a monitor
- Restored ability to take objects without collision as a monitor
  
## Map changes:
### **MISC**
- Shields for the FP hands have been removed until further notice
- Removed collision_geometry for spawn objects
- Tweaked shaders for stock vehicles to mimic OG Xbox visuals
- Added campaign lights for Ghost_MP vehicle
- C Gun Turret contrail mimics the OG Xbox counterpart
  
### **GRENADES**
- Added Frag grenade explosion sounds from Halo 4
- Added grenade pickup sfx from Halo 4
- Added Frag grenade throw sfx from Halo 4
- Added Plasma grenade explosion sounds from Halo 4
- Added Plasma grenade throw sfx from Halo 4

### **SPARTANS**
- Minor rigging tweaks for knees (still in progress)
- Renamed "multibipeds 2" to "multibipeds"
- Renamed "spartans 2.model_collision_geometry" to "multibipeds.model_collision_geometry"

### **HUD**
- H4 teammate indicator icon has been replaced with a modified version from "Flood 09"
- Weapon pickup icons have been resized, including offset fixes
- Multiple weapon pickup icons have been deleted from the texture since those weapon haven't been ported and/or included into the map yet

## Known issues
- Forge objects menu options are reset when opening object properties

# 1.0.0-beta-2

## Code changes:
- Fixed a problem with the animation timer for the loading Forge objects menu
- Added a new crosshair state that prevents you to place objects in a prohibited area
- Fixed a problem with the count of buttons displayed in the map voting menu
- Added a debug message to print how many objects exist on the Forge objects database
- Added a new format to save the name of all the Forge maps using a standard convention with underscores
- Fixed a bug with a debug feature that allowed to spawn test bipeds

## Map changes:
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
  ### **BARRICADES**
  - Barricade large

  ### **CRATES**
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

  ### **STRUCTURES/FORGE ISLAND**
  - Artifact base

  ### **BRIDGES AND PLATFORMS**
  - Bridge diag small
  - Bridge diagonal
  - Bridge large
  - Bridge xlarge
  - Platform large
  - Platform xlarge

  **NATURAL**
  - Rock 4

## Known issues
- Forge objects menu options are reset when opening object properties

# 1.0.0-beta-1

## Code changes:
- Restored category and name text being displayed by looking at Forge objects
- Added current project version number on pause menu

## Map changes:
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

## Known issues
- Monitor crosshair does not change colors and it can even dissapear sometimes
- Forge objects menu options are reset when opening object properties