# Forge - for Forge Island
Halo Custom Edition Forge system using Chimera and SAPP

### What is it?
Forge is a project that aims to add Forge-like system from posterior sequels of the game to any Halo Custom Edition map, by now our Forge Island map is the only one compatible with the project.

### How was it created?
This project was made with Chimera Lua Scripting on the client side and SAPP Lua Scripting on the server side, allowing us to share data via rcon messages and intercept any message to execute client side or server side actions.

Forge implements LuaBlam giving easy memory access and ensuring API compatibility with SAPP, plus other implemented libraries to give the best possible experience.

Using semi-REST architecture as the base of this project we are able to keep performance, data persistence and functionality along all the entire development, every request for update, deletion and creation is proccessed just once, only when needed in a single rcon message with specific properties.

It reimplements some concepts from modern app libraries like the store from react-redux, giving behavior and operability to the project.

### Highlights
- Provides a store for all the Forge objects created on the server meaning the store is reusable, when a player joins mid game all the objects in the store can be pushed to the new player and sync everything created by other players on the server.
- Any forged map is stored in a versionless .fmap meaning that forged maps will work in almost any map version.
- Forge works in local, the script will act as a server and client at the same time allowing you to play in the same way as if you were connected to a real server.
- Rcon messages are not persistent, except data intercepted from them, meaning that messages are not sent too often, only when they are needed, ensuring performance and less spamming messages.
- Rcon messages come with full range compression, position and rotation values are too important to keep them exactly in the same way they were sent, the compression used in Forge ensures the maximum and the minimum exact value at the moment of decompression using string.pack and string.unpack from Lua 5.3 (SAPP uses Lua 5.1, but some compatibility with Lua 5.3 can be achived by implemeting a compatibility library, bringing string.unpack and string.pack as a backport).

### Features
**Multiple biped support**
There is a simple built in system to associate players with a specific biped, used to swap between spartan and monitor, other bipeds can be added.

**Object highlighting**
If you are looking at a certain object this one becomes "highlighted" from the rest of the objects.

**Dynamic Forge objects addition**
Every scenery in the scenario palette is going to be taken as a Forge object.

**Dynamic forge menu**
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

- Any other map can implement Forge compatibility... as Gangstarr said: "infinite skills create miracles".

- Forge is now an open source project for anything your mind can create, with Forge came different concepts and libraries to help you to expand Halo Custom Edition (just took us like 15 years to reach this point of content lol).

### Now.. some comments about the project made by me

- Believe it or not, the hardest part was not object synchronization in a multiplayer game, (pretty much based on the same behaviour of simple HTTP requests).
- The most frustating part was the dynamic forge menu, i love it and i hate it, that menu is almost fake, Halo CE was not designed at all to handle a menu with that functionality and interaction.
- I really wanted to encourage library implementation, they are useful to avoid repeated code, providing abstraction and bringing some standard functionality to any project.
- All the dynamic stuff is in deed dynamic but... in a certain range of a static structure, by default Halo CE is pretty much static and some stuff was not supposed to change on the fly.
- A Forge version compatible with other maps can be done, but we need to make a standard static map structure, to achieve a really universal forge script.
- Spawn reflection was refactored a couple of times due to bad implementation and at the end the correct structure to handle spawns was simple than i expected, i ended mixing my fake "redux store" with spawn stuff meaning that some objects in the store are just forge objects, but some of those forge objects are spawn points.. or what i called spawn objects.

# FAQ

## Why is not possible to see objects that other other players forging? 
- I wanted to keep the communication system "REST" as possible, sending data about 16 players taking, leaving and rotating objects in real time would be really hard to handle, there are some possibilities of bringing this feature in future versions of Forge. At the end of the day that's just some kind of "visual" feature, create, update and delete is 100% covered now and it's functional.

## Can i run this on a LAN game?
- The answer is yes.. but actually no. You can indeed run Forge on a LAN game, but just that, if you start a game on LAN you will be able to access to all the Forge features except playing with people, this is because in LAN there is no "server" to ask for object requests, you are the server but you are not able to make rcon replys and keep communication with players connected to your game.

