# Changelog

# 1.0.0-beta.5
## Code changes:
- Fixed memory leaks causing incremental low performance and eventual crashes
- Add dynamic multibipeds support

# 1.0.0-beta.4
## Code changes:
- General code optimizations
- Fixed bug with fmaps storing garbage properties
- Moved `fspawn` command to normal commands instead of debug commands
- Fixed oddball netgame flag spawning
- Added feature to hide Forge spawning objects when in spartan mode
- Added support for teleporters
- Added support for objects with colors
- Added fmap name and current incoming object path to loading screen
- Added health regeneration for client and server side
- Fixed bug at saving configuration files due to a non existing folder
- Added HUD upgrades, sounds for different grenade types, hard landing sound
compatibility with aLTis hud sway, blur effect on low health
- Improved server fmaps automatic mapcycle, fmaps are now scanned to determine
available gametypes supported for that map
- Added Forge controls on pause menu, change when on monitor or spartan

## Map changes:
- Use "metal hull" as material in collision_geometry for every single metallic object
- SFX sounds for sand material
- SFX sounds for weapon drops
- Created new "camera track" values for vehicles
- Added new vehicle models
- Added overheat meter for Warthog chaingun
- Ported remaining announcer voices for team-based actions
- Updated textures for "Crate large", "crate small" and "pallet metal"
- Restored "grass detail" into rock objects
- Ported "Station 4 way large cap" into Forge
- Ported "Central Floor Cap" into Forge
- Ported "Bridge wall" into Forge
- Ported "Erosion" objects into Forge
- Ported "Catwalk LP" into Forge
- Ported "Catwalk 1" into Forge
- Ported H4 Flag
- Modified visor textures to be more accurate to "H1/Legacy" reflections and brightness
- Updated "Jersey Barrier" and "Jersey Barrier Short" collisions
- Replaced skull textures for hologram visuals in "Oddball skull spawn"
- Created new variants for "Forerunner Barrier Triple"
- New collision for Forerunner Barrier Triple
- Added "Covenant Barricade" scenery
- Added SFX sounds for Portable Shield
- Renamed "Covenant Energy Shield" to "Portable Shield"
- Updated countdown beep SFX
- New contrail particles for Rocket Launcher
- Updated rigging on knees for Strider armor
- Set new fall damage values


# 1.0.0-beta.3
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

# 1.0.0-beta.2

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

# 1.0.0-beta.1
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