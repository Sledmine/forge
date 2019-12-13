# HForge
Halo Custom Edition Forge system using Chimera and SAPP

### What is it?
HForge is a project that aims to add Forge-like system from posterior sequels of the game to any Halo Custom Edition map, currently the project is only compatible with Forge Island map project.

### How was it created?
This project was made with Chimera Lua Scripting for the client side and SAPP Lua Scripting on the server side this allow us to share data via rcon messages and intercept any message to execute actions client or server sided.

HForge implements LuaBlam giving easy memory access and ensuring API compatibility with SAPP plus other libraries implemented to give the best experience as possible.

Using semi-REST architecture as the base of this project we are able to keep performance, data persistence and functionality along all the entire development.

It reimplements some concepts from modern app libraries like the store from react-redux, giving behavior and operability to the project.

### Highlights
- Provides a store for all the Forge objects created on the server meaning the store is reusable, when a player joins mid game all the objects stored on it can be pushed to the new player and sync everything created by other players on the server.
- Any forged map is stored in a versionless .fmap meaning that forged maps will work in almost any map version.
- HForge works in local, the script will act as a server and client at the same time allowing you to play in the same way as if you were connected to a real server.
- Rcon messages are not persistent except by the data intercepted from them, meaning that messages are not sent too often, only when they are needed, ensuring performance and less spamming messages.
- Rcon messages with full range compression, position and rotation values are too important to keep them exactly in the same way they were sent, the compression used in HForge ensures the maximum and the minimum exact value at the moment of decompression.

### Features
- Full forge mode control, monitor biped, interactive menu, semi-CRUD for any forge object.
- Forged maps file support, saving and loading.
- Spawn reflection system.

### Long way to Forge
This project is part of something just much bigger than adding one map with Forge to a game like Halo Custom Edition.

- Forged maps are tons way smaller than full maps, so sharing different map layouts for different gametypes means fast on demand maps.
But we need a place to keep those forged maps... ;)

-  If any other map would have HForge compatibility... as Gangstarr said: "infinite skills create miracles".

- HForge is now an open source project for anything your mind can create, with HForge came different concepts and libraries to help you to expand Halo Custom Edition.
