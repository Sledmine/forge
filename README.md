# Forge - for Forge Island
Halo Custom Edition Forge system using Chimera and SAPP

## What is it?
Forge is a project that aims to add Forge-like system from posterior sequels of the Halo saga into any Halo Custom Edition map!... **BY NOW** Forge is only compatible with the Forge Island map, there are plans to add compatibility with Forge World in the future!

## How was it created?
This project was made with Chimera Lua Scripting on the client side and SAPP Lua Scripting on the server side, allowing us to share data via rcon messages and intercept any message to execute client side or server side actions.

Forge implements [lua-blam](https://github.com/Sledmine/lua-blam) giving easy memory access and ensuring API compatibility with SAPP, plus other libraries to give the most stable experience, avoiding random crashes as possible and ensuring project maintainability.

This project is based in some type of REST architecture, meaning that is made to keep data persistence and functionality along the entire development, every request proccess for updating, deleting and spawning is proccessed just once, only when needed, in a single rcon message with specific properties.

Forge reimplements some concepts from modern app libraries like the store from [redux-js](https://redux.js.org) using [lua-redux](https://github.com/piperswe/lua-redux), giving security, performance and operability to the project.

## Highlights
- Provides a store for all the Forge objects created on the server meaning the store is reusable, when a player joins mid game all the objects in the store can be pushed to the new player and sync everything created by other players on the server.
- Any forged map is stored in a versionless .fmap meaning that forged maps will work in almost any map version.
- Forge works in local, the script will act as a server and client at the same time allowing you to play in the same way as if you were connected to a real server.
- Rcon messages are not persistent, except data intercepted from them, meaning that messages are not sent too often, only when they are needed, ensuring performance and less spamming messages.
- Rcon messages come with full range compression, position and rotation values are too important to keep them exactly in the same way they were sent, the compression used in Forge ensures the maximum and the minimum exact value at the moment of decompression using string.pack and string.unpack from Lua 5.3 (SAPP uses Lua 5.1, but some compatibility with Lua 5.3 can be achived by implemeting a compatibility library, bringing string.unpack and string.pack as a backport).

## Features
- **Multiple biped support**:
There is a simple built in system to associate players with a specific biped, used to swap between spartan and monitor, other bipeds can be added

- **Object highlighting**:
If you are looking at a certain object this one becomes "highlighted" from the rest of the objects

- **Dynamic Forge objects addition**:
Every scenery in the a specific tag collection is taken as a Forge object and stored in a scenery database

- **Dynamic Forge menu**: Every scenery stored in the scenery database is split into categories and dynamically loaded in the Forge objects menu

- Create, update and delete for any Forge object
- Forged maps file support, saving and loading
- Spawn reflection system

## In progress
- Forge permission system, deny Forge requests and features for specific players.
- Object placement grid
- Map voting menu

## To do
- Better dynamic object selection
- Automatic constant tag detection

## Long way to Forge
This project is part of something just much bigger than creating a map with Forge for Halo Custom Edition.

- Forged maps are tons way smaller than full maps, so sharing different map layouts for different gametypes means fast on demand maps. But we need a place, cof cof, workshop... to keep those forged maps. If you know what I mean ;)

- Any other map can implement Forge compatibility with the correct adjustments, we are working into a way for providing base files for adding Forge to any map... as Gangstarr said: "infinite skills create miracles"

- Forge is now an open source project for anything your mind can create, with Forge came different concepts and libraries to help you to expand Halo Custom Edition (just took us like 15 years to reach this point of content lol)

## Special Thanks and Credits

- Visual Studio Code and EmmyLua for the fast workflow for Lua
- Kepler Project for the lua file system and the lua 5.3 compatibility
- Luaunit for the unit testing framework
- Egor Skriptunoff for resolving the [old rotation function](https://stackoverflow.com/questions/30493826/yaw-pitch-and-roll-rotations-to-six-float-variables)
- aLTis94 for providing the old rotation function on his fake forge script
- Jerry for back adding functionality to Chimera and bug fixing
- Sled for all the forge core designment, some Forge UI design, hard reverse engineering functions and stuff for tools and libraries
- MrChromed for all shaders, models, sounds, fixes, and all what he does, I can't list all here
- Solink for porting and optimizing models for Forge, such as the bsp and almost all the objects of the project

## Libraries used in the project

- [lua-blam](https://github.com/Sledmine/lua-blam)
- [redux](https://github.com/piperswe/lua-redux)
- [lfs](https://github.com/keplerproject/luafilesystem)
- [glue](https://github.com/Sledmine/glue)
- [inspect](https://github.com/kikito/inspect.lua)
- [json](https://github.com/rxi/json.lua)
- [lua-compat-5.3](https://github.com/keplerproject/lua-compat-5.3)
- [luaunit](https://github.com/bluebird75/luaunit)
