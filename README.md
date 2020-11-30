
<html>
    <p align="center">
        <img width="450px" src="assets/forge_logo.png"/>
    </p>
    <h1 align="center">Halo Custom Edition - Forge</h1>
    <p align="center">
       Halo Custom Edition Forge system using Chimera and SAPP
    </p>
</html>

# What is it?

Forge is a project that aims to add Forge-like system from posterior sequels of the Halo saga into any Halo Custom Edition map, mostly by replacting the Sapien capabilities, by now Forge is only compatible with the [Forge Island](https://www.youtube.com/watch?v=K_QViDBnpq0) map project, there are plans to add compatibility with other maps like [Forge World](https://www.youtube.com/watch?v=kUDYwVF0OLk) in the future!

# How was it created?

This project was made with Chimera Lua Scripting for the client side and SAPP Lua Scripting for the server side, it has in built rcon communication system, allowing us to share data via rcon messages and intercept any message to execute client side or server side actions.

Forge implements [lua-blam](https://github.com/Sledmine/lua-blam) giving easy memory access and ensuring API compatibility with SAPP, keeping same code base for each platform, plus other libraries to give the most stable experience, avoiding random crashes as possible with unit testing and ensuring project maintainability.

This project is based in some type of REST architecture, meaning that data persistence is done via requests, keeping bandwith, flow and functionality along the entire development, every request is proccessed just once, only when needed, in a single rcon message with specific properties.

Forge reimplements some concepts from modern app libraries like the store from [redux-js](https://redux.js.org) using [lua-redux](https://github.com/piperswe/lua-redux), giving security, performance and operability to the project.

# Highlights

- Provides a store for all the Forge objects created on the server meaning the store is reusable, when a player joins mid game all the objects in the store can be pushed to the new player and sync everything created by other players on the server.
- Any forged map is stored in a versionless .fmap meaning that forged maps will work in almost any Forge map version, objects that are not anymore in the Forge map will be ignored.
- Forge works in local mode **(Playing the map via LAN mode option, this does not work in a real LAN game)**, the script will act as a server and client at the same time allowing you to play in the same way as if you were connected to a real server.
- Rcon messages are not persistent, except data intercepted from them, meaning that messages are not sent too often, only when they are needed, ensuring performance and less spamming messages blocking Halo Custom Edition thread flow.
- Rcon messages come with full range compression to send specific values like floats that are hard to send via string message, for example coordinates and rotation values for every object are too important to keep them exactly in the same way they were sent, the compression used in Forge ensures the maximum and the minimum exact value at the moment of decompression using `string.pack` and `string.unpack` from **Lua 5.3** (SAPP uses **Lua 5.1**, but some compatibility with **Lua 5.3** can be achived by implemeting a compatibility library, bringing `string.unpack` and `string.pack` as a backport).

# Features

### **Multiple Biped Support**
There is a simple built in system to associate players with a specific biped, used to swap between spartan and monitor, other bipeds can be added to this system to achieve different armors, biped based gametypes, etc.

### **Object Selection**
Objects are highligted when a monitor is looking at them, object selection is calculated via projectile interception, this is suposed to change in the future due to objects must have a collision to be selected.

### **Dynamic Forge Objects Addition**
Every Forge object is basically a scenery, so every scenery in a specific tag collection is taken as a Forge object and stored in a scenery database to be used.

### **Dynamic Forge menu**
Every scenery stored in the scenery database is automatically split into categories and dynamically loaded in the Forge objects menu.

- Create, update and delete for any Forge object
- Forged maps file support, saving and loading
- Spawn reflection system

## In progress
- ~~- Better dynamic object selection, taking objects from distance or objects that are too big is really difficult by now.~~
- ~~- Map voting menu, non admin required servers are a key piece in the Forge project, let players play what they want to play.~~
- Automatic constant tag detection, there are some base tags and constant values needed by Forge to work, this must be done dynamically in client and server side. **(ALMOST DONE)**

## To do
- Forge permission system, deny Forge requests to the server for specific players.

## Help needed with
We are giving our best effort to make this project as complete and useful as possible, but there is some stuff out of our knowledge where you can probably give us a hand to concentrate in other key less demanding features.

- Object placement features, grid, magnetisim, etc.
- Object history placement, provide undo, redo operations along time.
- Better controls implementation, multi input devices is key, keyboard, mouse and joystick support are must have features.

## Libraries used in the project

- [lua-blam](https://github.com/Sledmine/lua-blam)
- [redux](https://github.com/piperswe/lua-redux)
- [lfs](https://github.com/keplerproject/luafilesystem)
- [glue](https://github.com/Sledmine/glue)
- [inspect](https://github.com/kikito/inspect.lua)
- [json](https://github.com/rxi/json.lua)
- [lua-compat-5.3](https://github.com/keplerproject/lua-compat-5.3)
- [luaunit](https://github.com/bluebird75/luaunit)

# Building Forge

To bundle the project you need to be sure to have all the required dependencies installed on the project, there are some symlinks on this repository but you need to recreate them manually or install every dependency on the project manually as well.

Then you can use [Mercury](https://github.com/Sledmine/Mercury) to bundle the project using the next command line on the project folder:
```cmd
mercury bundle
```

There are not release builds of [Mercury](https://github.com/Sledmine/Mercury) at the creation of this document, instead you can use [luacc](https://github.com/mihacooper). [Mercury](https://github.com/Sledmine/Mercury) is using the same implementation of [luacc](https://github.com/mihacooper) to bundle lua projects.

# Long way to Forge

This project is part of something just much bigger than creating a project with an Island and Forge for Halo Custom Edition, here are some points that can help this to grow a lot!

- Forged maps are tons way smaller than full maps, so sharing different map layouts for different gametypes means fast on demand maps. But we need a place, cof cof, workshop... to keep those forged maps, we are looking for something like Mercury to achieve this.

- Any other map can implement Forge compatibility with the correct adjustments, we are working into a way for providing base tag files for adding Forge to any map... as Gangstarr said: "infinite skills create miracles".

- Forge is now an open source project for anything your mind can create, with Forge came different concepts and libraries to help you to expand Halo Custom Edition (just took us like 15 years to reach this point of content lol)

# Special Thanks and Credits

- Visual Studio Code and EmmyLua for the fast workflow for Lua
- Luaunit for the unit testing framework
- Egor Skriptunoff for resolving the [old rotation function](https://stackoverflow.com/questions/30493826/yaw-pitch-and-roll-rotations-to-six-float-variables)
- aLTis94 for providing help and examples of different implementation methods
- Jerry for adding functionality to Chimera and keeping features updated
- Sled for the entire Forge system designment, UI designment and reverse engineering game functions and stuff like tools and libraries
- MrChromed for all shaders, models, sounds, fixes, and all what he does, I can't list all here
- Solink for porting and optimizing models for Forge, such as the bsp and almost all the objects of the project