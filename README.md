# Discordia-Components

discordia-components is a [Discordia](https://github.com/SinisterRectus/Discordia/) 2.x extension aiming at making the use of [Message Components](https://discord.com/developers/docs/interactions/message-components) possible and user-friendly; Message components include buttons and select menus.

## Documentation

For docmentation please refer to [the wiki](https://github.com/Bilal2453/discordia-components/wiki).

If you still can't find what you want, feel free to ask me on Discord. You will find me on any of the official communities.

## Installing

First make sure you `cd` into your bot directory. Then you have two options to install the library:

**Note: Due to unsolved bug in Lit, the package will error when installing; as of now you will have to use the Git method described below __AND NOT LIT__.**

1. `git clone https://github.com/Bilal2453/discordia-components.git ./deps/discordia-components && git clone https://github.com/Bilal2453/discordia-interactions ./deps/discordia-interactions`.

    Make sure that after running the above command it did not error, and that the folders `discordia-interactions` & `discordia-components` now do show up under your `deps` folder.

2. ~~`lit install Bilal2453/discordia-components`. (preferred)~~

## Examples

See the [examples](/examples) directory.

- [Ping Pong](examples/pingPong.lua)
- [Music Controls](examples/controlMusic.lua)
