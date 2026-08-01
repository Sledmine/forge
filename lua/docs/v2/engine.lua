-- SPDX-License-Identifier: GPL-3.0-only
-- This file documents the Balltze Lua plugin API v2 (Engine namespace).
-- It should not be included; it exists purely for IDE autocomplete/type-checking.

---@meta _
---@diagnostic disable: missing-return
---@diagnostic disable: unused-local

Engine = {}


-------------------------------------------------------
-- Engine.cacheFile
-------------------------------------------------------

Engine.cacheFile = {}

-- Get the header of the currently loaded cache file
---@return CacheFileHeader|nil @nil if no map is loaded
function Engine.cacheFile.getLoadedCacheFileHeader() end

-- List every .map file under the game's "maps" directory (recursively), as paths relative to it
---@return string[]
function Engine.cacheFile.getList() end


-------------------------------------------------------
-- Engine.game
-------------------------------------------------------

Engine.game = {}

-- Get the number of ticks since the engine started
---@return integer
function Engine.game.getTickCount() end

-- Get the currently active game engine type (e.g. "slayer", "ctf"), or nil if there's no active game engine
---@return GameEngineType|nil
function Engine.game.getGameEngineType() end

-- Get this machine's role in the current game session: "local" for single-player/non-networked
-- multiplayer, "networkClient" or "networkServer" when connected to a multiplayer session over
-- the network, or "filmPlayback" while watching a saved film.
---@return GameConnectionType|nil @nil if unavailable
function Engine.game.getGameConnectionType() end

-- Whether the current multiplayer game variant is team-based.
---@return boolean|nil @nil if no game variant is active (e.g. not in multiplayer)
function Engine.game.isTeamGame() end


-------------------------------------------------------
-- Engine.script
-------------------------------------------------------

Engine.script = {}

-- Execute a Halo Script (HSC) string
---@param script string
function Engine.script.execute(script) end


-------------------------------------------------------
-- Engine.tag
-------------------------------------------------------

Engine.tag = {}

-- Look up a tag by its path and group. Errors if no map is loaded.
---@param path string
---@param group TagGroup
---@return TagHandle|nil @nil if no tag with that path/group exists
function Engine.tag.lookupTag(path, group) end

-- Get the data of a tag by handle and group. Errors if no map is loaded, or if the tag's
-- actual group doesn't match the group argument.
---@param handle TagHandle
---@param group TagGroup
---@return table @the concrete tag data type depends on `group`; see the per-group overloads below
---@overload fun(handle: TagHandle, group: "actor"): Actor
---@overload fun(handle: TagHandle, group: "actor_variant"): ActorVariant
---@overload fun(handle: TagHandle, group: "antenna"): Antenna
---@overload fun(handle: TagHandle, group: "model_animations"): ModelAnimations
---@overload fun(handle: TagHandle, group: "biped"): Biped
---@overload fun(handle: TagHandle, group: "bitmap"): Bitmap
---@overload fun(handle: TagHandle, group: "spheroid"): Spheroid
---@overload fun(handle: TagHandle, group: "continuous_damage_effect"): ContinuousDamageEffect
---@overload fun(handle: TagHandle, group: "model_collision_geometry"): ModelCollisionGeometry
---@overload fun(handle: TagHandle, group: "color_table"): ColorTable
---@overload fun(handle: TagHandle, group: "contrail"): Contrail
---@overload fun(handle: TagHandle, group: "device_control"): DeviceControl
---@overload fun(handle: TagHandle, group: "decal"): Decal
---@overload fun(handle: TagHandle, group: "ui_widget_definition"): UiWidgetDefinition
---@overload fun(handle: TagHandle, group: "input_device_defaults"): InputDeviceDefaults
---@overload fun(handle: TagHandle, group: "device"): Device
---@overload fun(handle: TagHandle, group: "detail_object_collection"): DetailObjectCollection
---@overload fun(handle: TagHandle, group: "effect"): Effect
---@overload fun(handle: TagHandle, group: "equipment"): Equipment
---@overload fun(handle: TagHandle, group: "flag"): Flag
---@overload fun(handle: TagHandle, group: "fog"): Fog
---@overload fun(handle: TagHandle, group: "font"): Font
---@overload fun(handle: TagHandle, group: "material_effects"): MaterialEffects
---@overload fun(handle: TagHandle, group: "garbage"): Garbage
---@overload fun(handle: TagHandle, group: "glow"): Glow
---@overload fun(handle: TagHandle, group: "grenade_hud_interface"): GrenadeHudInterface
---@overload fun(handle: TagHandle, group: "hud_message_text"): HudMessageText
---@overload fun(handle: TagHandle, group: "hud_number"): HudNumber
---@overload fun(handle: TagHandle, group: "hud_globals"): HudGlobals
---@overload fun(handle: TagHandle, group: "item"): Item
---@overload fun(handle: TagHandle, group: "item_collection"): ItemCollection
---@overload fun(handle: TagHandle, group: "damage_effect"): DamageEffect
---@overload fun(handle: TagHandle, group: "lens_flare"): LensFlare
---@overload fun(handle: TagHandle, group: "lightning"): Lightning
---@overload fun(handle: TagHandle, group: "device_light_fixture"): DeviceLightFixture
---@overload fun(handle: TagHandle, group: "light"): Light
---@overload fun(handle: TagHandle, group: "sound_looping"): SoundLooping
---@overload fun(handle: TagHandle, group: "device_machine"): DeviceMachine
---@overload fun(handle: TagHandle, group: "globals"): Globals
---@overload fun(handle: TagHandle, group: "meter"): Meter
---@overload fun(handle: TagHandle, group: "light_volume"): LightVolume
---@overload fun(handle: TagHandle, group: "gbxmodel"): Gbxmodel
---@overload fun(handle: TagHandle, group: "model"): Model
---@overload fun(handle: TagHandle, group: "multiplayer_scenario_description"): MultiplayerScenarioDescription
---@overload fun(handle: TagHandle, group: "null"): nil
---@overload fun(handle: TagHandle, group: "preferences_network_game"): PreferencesNetworkGame
---@overload fun(handle: TagHandle, group: "object"): Object
---@overload fun(handle: TagHandle, group: "particle"): Particle
---@overload fun(handle: TagHandle, group: "particle_system"): ParticleSystem
---@overload fun(handle: TagHandle, group: "physics"): Physics
---@overload fun(handle: TagHandle, group: "placeholder"): Placeholder
---@overload fun(handle: TagHandle, group: "point_physics"): PointPhysics
---@overload fun(handle: TagHandle, group: "projectile"): Projectile
---@overload fun(handle: TagHandle, group: "weather_particle_system"): WeatherParticleSystem
---@overload fun(handle: TagHandle, group: "scenario_structure_bsp"): ScenarioStructureBsp
---@overload fun(handle: TagHandle, group: "scenery"): Scenery
---@overload fun(handle: TagHandle, group: "shader_transparent_chicago_extended"): ShaderTransparentChicagoExtended
---@overload fun(handle: TagHandle, group: "shader_transparent_chicago"): ShaderTransparentChicago
---@overload fun(handle: TagHandle, group: "scenario"): Scenario
---@overload fun(handle: TagHandle, group: "shader_environment"): ShaderEnvironment
---@overload fun(handle: TagHandle, group: "shader_transparent_glass"): ShaderTransparentGlass
---@overload fun(handle: TagHandle, group: "shader"): Shader
---@overload fun(handle: TagHandle, group: "sky"): Sky
---@overload fun(handle: TagHandle, group: "shader_transparent_meter"): ShaderTransparentMeter
---@overload fun(handle: TagHandle, group: "sound"): Sound
---@overload fun(handle: TagHandle, group: "sound_environment"): SoundEnvironment
---@overload fun(handle: TagHandle, group: "shader_model"): ShaderModel
---@overload fun(handle: TagHandle, group: "shader_transparent_generic"): ShaderTransparentGeneric
---@overload fun(handle: TagHandle, group: "ui_widget_collection"): UiWidgetCollection
---@overload fun(handle: TagHandle, group: "shader_transparent_plasma"): ShaderTransparentPlasma
---@overload fun(handle: TagHandle, group: "sound_scenery"): SoundScenery
---@overload fun(handle: TagHandle, group: "string_list"): StringList
---@overload fun(handle: TagHandle, group: "shader_transparent_water"): ShaderTransparentWater
---@overload fun(handle: TagHandle, group: "tag_collection"): TagCollection
---@overload fun(handle: TagHandle, group: "camera_track"): CameraTrack
---@overload fun(handle: TagHandle, group: "dialogue"): Dialogue
---@overload fun(handle: TagHandle, group: "unit_hud_interface"): UnitHudInterface
---@overload fun(handle: TagHandle, group: "unit"): Unit
---@overload fun(handle: TagHandle, group: "unicode_string_list"): UnicodeStringList
---@overload fun(handle: TagHandle, group: "virtual_keyboard"): VirtualKeyboard
---@overload fun(handle: TagHandle, group: "vehicle"): Vehicle
---@overload fun(handle: TagHandle, group: "weapon"): Weapon
---@overload fun(handle: TagHandle, group: "wind"): Wind
---@overload fun(handle: TagHandle, group: "weapon_hud_interface"): WeaponHudInterface
---@overload fun(handle: TagHandle, group: "vector_font"): VectorFont
---@overload fun(handle: TagHandle, group: "vector_font_data"): VectorFontData
function Engine.tag.getTagData(handle, group) end

-- Get the tag entry (metadata: group, handle, path, ...) for a tag handle. Errors if no map
-- is loaded.
---@param handle TagHandle
---@return TagEntry|nil
function Engine.tag.getTagEntry(handle) end

-- List every resident tag entry of a group, optionally filtered by a path substring. Errors
-- if no map is loaded.
---@param group TagGroup
---@param pathFilter? string @only tags whose path contains this substring; omit/empty for all
---@return TagEntry[]
function Engine.tag.filterTags(group, pathFilter) end

-- Import a tag (and its whole dependency tree) from another map into the currently loaded
-- map's live tag table. The imported tag and every dependency are fully self-contained
-- copies — not references back into the source map. If a tag with the same path and group
-- already exists in the destination, it's reused instead of imported again. Errors if no map
-- is loaded; returns nil if the source map or tag couldn't be found/imported.
---@param mapName string @name of the source map, without extension (e.g. "bloodgulch")
---@param tagPath string @path of the tag to import, without extension
---@param group TagGroup
---@return TagHandle|nil
function Engine.tag.importTag(mapName, tagPath, group) end


-------------------------------------------------------
-- Engine.object
-------------------------------------------------------

Engine.object = {}

-- Get a game object by handle
---@param handle ObjectHandle|integer
---@param type? ObjectType @if given, only returns the object if it matches this type
---@return DynamicObjectBase|nil
---@overload fun(handle: ObjectHandle|integer, type: "biped"): BipedObject|nil
---@overload fun(handle: ObjectHandle|integer, type: "vehicle"): VehicleObject|nil
---@overload fun(handle: ObjectHandle|integer, type: "weapon"): WeaponObject|nil
---@overload fun(handle: ObjectHandle|integer, type: "equipment"): EquipmentObject|nil
---@overload fun(handle: ObjectHandle|integer, type: "garbage"): GarbageObject|nil
---@overload fun(handle: ObjectHandle|integer, type: "projectile"): ProjectileObject|nil
---@overload fun(handle: ObjectHandle|integer, type: "deviceMachine"): DeviceMachineObject|nil
---@overload fun(handle: ObjectHandle|integer, type: "deviceControl"): DeviceControlObject|nil
---@overload fun(handle: ObjectHandle|integer, type: "deviceLightFixture"): DeviceLightFixtureObject|nil
function Engine.object.getObject(handle, type) end

-- Spawn an object
---@param tagHandle TagHandle|integer
---@param parentObjectHandle? ObjectHandle|integer
---@param position Point3d|{x: number, y: number, z: number} @a plain table with x/y/z fields works too
---@return ObjectHandle
function Engine.object.createObject(tagHandle, parentObjectHandle, position) end

-- Delete an object. Errors if the handle doesn't refer to a currently live object.
---@param objectHandle ObjectHandle|integer
function Engine.object.deleteObject(objectHandle) end

-- Attach an object to another object's marker
---@param objectHandle ObjectHandle|integer
---@param objectMarker string|nil
---@param attachmentObjectHandle ObjectHandle|integer
---@param attachmentMarker string|nil
function Engine.object.objectAttachToMarker(objectHandle, objectMarker, attachmentObjectHandle, attachmentMarker) end


-------------------------------------------------------
-- Engine.player
-------------------------------------------------------

Engine.player = {}

-- Get a player. With no argument, returns the local player (controller 0).
---@param playerHandle? PlayerHandle|integer
---@return Player|nil
function Engine.player.getPlayer(playerHandle) end


-------------------------------------------------------
-- Engine.terminal
-------------------------------------------------------

Engine.terminal = {}

-- Print a message to the terminal/console, formatted with the `lfmt` library ({}-style, not
-- string.format's %-style). The color argument is optional; without it, the message prints
-- in the default terminal color.
---@param color ColorARGB
---@param format string
---@param ... any
---@overload fun(format: string, ...: any)
function Engine.terminal.print(color, format, ...) end


-------------------------------------------------------
-- Engine.uiWidget
-------------------------------------------------------

Engine.uiWidget = {}

-- Launch a widget: opens it as a child of the currently active widget, or as the root widget
-- if none is active.
---@param widgetDefinition TagHandle|integer
---@return Widget|nil
function Engine.uiWidget.launchWidget(widgetDefinition) end

-- Get the currently active (root) widget
---@return Widget|nil
function Engine.uiWidget.getActiveWidget() end

-- Close the currently active widget
function Engine.uiWidget.closeWidget() end

-- Replace a widget in place with a newly-loaded widget of a different definition
---@param widget Widget
---@param widgetDefinition TagHandle|integer
---@return Widget
function Engine.uiWidget.replaceWidget(widget, widgetDefinition) end

-- Reload a widget: reloads it with its current definition and state
---@param widget Widget
---@return Widget
function Engine.uiWidget.reloadWidget(widget) end

-- Give input focus directly to a widget (as a child of its own parent)
---@param widget Widget
function Engine.uiWidget.focusWidget(widget) end

-- Remove input focus from a widget, if it is its parent's focused child
---@param widget Widget
function Engine.uiWidget.unfocusWidget(widget) end

-- Recursively search a widget tree (depth-first: children, then siblings) for widgets whose
-- definition tag handle matches. Defaults to searching from the currently active widget.
---@param widgetDefinition TagHandle|integer
---@param baseWidget? Widget @defaults to the currently active widget
---@param firstMatch? boolean @stop at the first match instead of collecting every match
---@return Widget[]
function Engine.uiWidget.findWidgets(widgetDefinition, baseWidget, firstMatch) end

---@param widget Widget
function Engine.uiWidget.disableWidget(widget) end

---@param widget Widget
function Engine.uiWidget.enableWidget(widget) end

-- Get the index of a child widget within its parent's child list
---@param parentWidget Widget
---@param childWidget Widget
---@return integer|nil @nil if childWidget is not a child of parentWidget
function Engine.uiWidget.getIndexForChildWidget(parentWidget, childWidget) end

-- Get the Nth (0-based) child of a widget
---@param parentWidget Widget
---@param index integer
---@return Widget|nil
function Engine.uiWidget.getNthChildWidget(parentWidget, index) end

---@param widget Widget
---@return Widget|nil
function Engine.uiWidget.getLastChildWidget(widget) end

-- Walk up widget.parent until reaching the widget with no parent
---@param widget Widget
---@return Widget
function Engine.uiWidget.getTopmostParentWidget(widget) end

---@param widget Widget
---@return boolean
function Engine.uiWidget.isListWidget(widget) end

---@param widget Widget
---@return boolean
function Engine.uiWidget.textBoxWidgetIsFocused(widget) end


-------------------------------------------------------
-- Engine.hud
-------------------------------------------------------

Engine.hud = {}

---@class HudText
local HudText = {}

-- Replace this text's displayed string.
---@param text string
function HudText:setText(text) end

-- Stop drawing this text. Calling this a second time is an error.
function HudText:remove() end

-- Add a persistent text overlay to the HUD. It is redrawn automatically every frame for as
-- long as it exists — no need to draw it yourself from a "frame" (or any other) event
-- listener. It draws for every active local player's HUD (i.e. every split-screen pane), at
-- the same position relative to each pane. It's automatically taken down if the plugin that
-- created it is unloaded (e.g. on a map change for a map-scoped plugin) without having called
-- HudText:remove() itself.
---@param text string
---@param x integer @pixels from the left edge of the HUD viewport
---@param y integer @pixels from the top edge of the HUD viewport
---@param color? {a: number, r: number, g: number, b: number} @0-1 per channel; defaults to opaque white
---@return HudText
function Engine.hud.addText(text, x, y, color) end
