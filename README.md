# HForge
Halo Custom Edition Forge system using Chimera and SAPP

### What is it?
HForge is a project that aims to add Forge-like system from posterior sequels of the game to any Halo Custom Edition map, currently the project is only compatible with Forge Island map project.

### How was it created?
This project was made with Chimera Lua Scripting on the client side and SAPP Lua Scripting on the server side, allowing us to share data via rcon messages and intercept any message to execute client side or server side actions.

HForge implements LuaBlam giving easy memory access and ensuring API compatibility with SAPP, plus other implemented libraries to give the best possible experience.

Using semi-REST architecture as the base of this project we are able to keep performance, data persistence and functionality along all the entire development, every request for update, deletion and creation is proccessed just once, only when needed in a single rcon message with specific properties.

It reimplements some concepts from modern app libraries like the store from react-redux, giving behavior and operability to the project.

### Highlights
- Provides a store for all the Forge objects created on the server meaning the store is reusable, when a player joins mid game all the objects in the store can be pushed to the new player and sync everything created by other players on the server.
- Any forged map is stored in a versionless .fmap meaning that forged maps will work in almost any map version.
- HForge works in local, the script will act as a server and client at the same time allowing you to play in the same way as if you were connected to a real server.
- Rcon messages are not persistent, except data intercepted from them, meaning that messages are not sent too often, only when they are needed, ensuring performance and less spamming messages.
- Rcon messages come with full range compression, position and rotation values are too important to keep them exactly in the same way they were sent, the compression used in HForge ensures the maximum and the minimum exact value at the moment of decompression using string.pack and string.unpack from Lua 5.3 (SAPP uses Lua 5.1, but some compatibility with Lua 5.3 can be achived by implemeting a compatibility library, bringing string.unpack and string.pack as a backport).

### Features
- Multiple biped support.
- Object highlight.
- Dynamic forge objects addition.
- Dynamic forge menu.
- Semi-CRUD for any forge object.
- Forged maps file support, saving and loading.
- Spawn reflection system.

### In progress
- Forge permission system, deny forge commands and features for specific players.
- Better dynamic object selection.

### To do
- Semi-gravity system for more precise object spawning (concept only working on spawn points already).
- Grid layout for object placement.

### Long way to Forge
This project is part of something just much bigger than creating a map with Forge for Halo Custom Edition.

- Forged maps are tons way smaller than full maps, so sharing different map layouts for different gametypes means fast on demand maps. But we need a place to keep those forged maps... if you know what i mean ;)

- Any other map can implement HForge compatibility... as Gangstarr said: "infinite skills create miracles".

- HForge is now an open source project for anything your mind can create, with HForge came different concepts and libraries to help you to expand Halo Custom Edition (just took us like 15 years to reach this point lol).

### Now.. some comments about the project made by me

- Believe it or not, the hardest part was not object synchronization in s multiplayer game, (pretty much based on just HTTP requests).
- One of the most frustrating part was the dyanmic forge menu, i love it and i hate it, that menu is almost fake, Halo was not designed to handle that kind of interaction with a menu at all.
