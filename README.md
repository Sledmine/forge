
<html>
    <p align="center">
        <img width="450px" src="assets/forge_logo.png"/>
    </p>
    <h1 align="center">Forge CE</h1>
    <p align="center">
       Halo Custom Edition Forge system using Chimera and SAPP
    </p>
</html>

# Description

Forge CE is a project that aims to add Forge-like system from posterior sequels of the Halo saga into any Halo Custom Edition map, mostly by replicating Sapien capabilities on runtime, by now Forge is only compatible with the [Forge Island](https://www.youtube.com/watch?v=K_QViDBnpq0) map project, there are plans to add compatibility with other maps like [Forge World](https://www.youtube.com/watch?v=kUDYwVF0OLk) in the future!

Forge is not magic.. it is the compilation of enthusiast modders and developers with a strong understanding of the Halo Custom Edition engine, that are aiming to provide projects with a professional build.

No, it is not compatible with Halo 1 on MCC yet... we need to create a port of Chimera Lua before thinking about a port for MCC, but a port is theoretically possible.

# How was it created?

This project was made with Chimera Lua scripting for the client side and SAPP Lua scripting for the server side, it has in built rcon communication system, allowing us to share data via rcon messages and intercept any message to execute client side or server side actions.

Forge implements [lua-blam](https://github.com/Sledmine/lua-blam) giving easy memory access and ensuring API compatibility with SAPP, keeping same code base for each platform, plus other libraries to give the most stable experience, avoiding random crashes as possible with unit testing and ensuring project maintainability.

This project is based in some type of REST architecture, meaning that data persistence is done via requests, keeping bandwith, flow and functionality along the entire development, every request is proccessed just once, only when needed, in a single rcon message with specific properties.

It reimplements some concepts from modern app libraries like the store from [redux-js](https://redux.js.org) using [lua-redux](https://github.com/piperswe/lua-redux), giving security, performance and operability to the project.

# Documentation
Checkout some of the markdowns hosted on this repository about Forge in general:

[Controls and commands](FORGE.md)

[Changelog](CHANGELOG.md)

# Features

## Multiple Biped Support
Forge CE has a system to associate players with a specific biped, used to swap between spartan and monito, other bipeds can be added to this system to achieve different armors, biped based gametypes, etc.

## Dynamic Objects Addition
Every Forge object is basically a scenery, so every scenery in a specific tag collection is taken as a Forge object and stored in a scenery database to be used in game.

## Dynamic Objects Navigation
Every scenery stored in the scenery database is automatically converted into an option for the Forge objects menu by splitting the tag path of the object into categories to achieve dynamic menu navigation.

## Settings Menu
Every settings available to customize Forge CE can be configured on the pause menu screen.

## Misc
- Create, update and delete for any Forge object in online or local mode
- Maps file support, save and load Forge maps
- Spawn reflection system, Forge objects can reflect data to the netgame system to create player spawns, weapon spawns, vehicle spaws, flag spawns, etc

# Highlights
- Provides a store for all the Forge objects created on the server meaning the store is reusable, when a player joins mid game all the objects in the store can be pushed to the new player and sync everything created by other players on the server, also this process is an async process that can push tons of objects to different players without having to block the server main thread
- Any forged map is stored in a versionless .fmap meaning that forged maps will work in almost any Forge map version, objects that are not anymore in the Forge map will be ignored
- Forge works in local mode **(Playing the map via LAN mode option, this does not work in a real LAN game)**, the script will act as a server and client at the same time allowing you to play in the same way as if you were connected to a real server
- Rcon messages are not persistent, except data intercepted from them, meaning that messages are not sent too often, only when they are needed, ensuring performance and less spamming messages blocking Halo Custom Edition thread flow
- Rcon messages come with full range compression to send specific values like floats that are hard to send via string message, for example coordinates and rotation values for every object are too important to keep them exactly in the same way they were sent, the compression used in Forge ensures the maximum and the minimum exact value at the moment of decompression using `string.pack` and `string.unpack` from **Lua 5.3** (SAPP uses **Lua 5.1**, but some compatibility with **Lua 5.3** can be achived by implemeting a compatibility library, bringing `string.unpack` and `string.pack` as a backport)

# Help needed with
We are giving our best effort to make this project as complete and useful as possible, but there are a few things out of our knowledge where you can probably give us a hand to accelerate development.

- Object placement features, grid, magnetisim, etc.
- Object history placement, provide undo, redo operations along time.
- Better controls implementation, multi input devices is key, keyboard, mouse and joystick support are must have features.

# Building Forge CE
To bundle the lua code you need to be sure to have all the required dependencies installed on the project.
Currently all the required dependencies are stored in this repository so there is no need to gather external dependencies by now, then you can use [Mercury](https://github.com/Sledmine/Mercury) to bundle the project using the next command line on the project folder:

**Forge Island - Client:**
```cmd
mercury luabundle
```

**Forge Island - Server:**
```cmd
mercury luabundle server
```

Server bundled script requires the **compat53/** folder from this repository placed in the **lua/** folder of a SAPP server to work, this folder can't be bundled with the script.

If for some reason you can't use [Mercury](https://github.com/Sledmine/Mercury) to bundle the
project, you can use [luacc](https://github.com/mihacooper/luacc), this is the bundle implementation used in [Mercury](https://github.com/Sledmine/Mercury) for modular lua projects.

Forge tagset is not available to the public yet, it will be available here later somewhere.

Also as now the project is using [Invader](https://github.com/SnowyMouse/invader) as part of the
building tools due to extended file limits size, some modifications for SAPP are needed in order
to bring support for these invader expanded maps. Some more info about this
will be added later in the future.

# Long way to Forge

This project is part of something just much bigger than creating a project with an Island and Forge for Halo Custom Edition, here are some points that can help this to grow a lot!

- Forged maps are way smaller than custom maps, sharing different map layouts for different gametypes means fast on demand maps. But we need a place, cof cof, workshop... to keep those forged maps, we are looking for something like Mercury to achieve this.

- Any other map can implement Forge compatibility with the correct adjustments, we are working into a way for providing base tag files for adding Forge to any map... as Gangstarr said: "infinite skills create miracles".

- Forge is now an open source project for anything your mind can create, with Forge came different concepts and libraries to help you to expand Halo Custom Edition (just took us like 15 years to reach this point of content lol)

# Thanks and Credits

- Visual Studio Code and [EmmyLua](https://github.com/EmmyLua) for the fast workflow for Lua
- Luaunit for the unit testing framework
- Egor Skriptunoff for resolving the [old rotation function](https://stackoverflow.com/questions/30493826/yaw-pitch-and-roll-rotations-to-six-float-variables)
- [aLTis94](https://github.com/aLTis94) for providing help and examples of different implementation methods
- [JerryBrick](https://github.com/JerryBrick) for adding functionality to Chimera and keeping features updated
- Sled for the entire Forge system desig, UI design, reverse engineering game functions, libraries, etc
- MrChromed for doing shaders, models, sounds, tag fixes, etc
- Solink for porting and optimizing models for Forge, such as the bsp and almost all the objects of the project