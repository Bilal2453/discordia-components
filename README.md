# Discordia-Components

![Version](https://img.shields.io/github/v/release/Bilal2453/discordia-components)
![License](https://img.shields.io/github/license/Bilal2453/discordia-components)

discordia-components is a [Discordia](https://github.com/SinisterRectus/Discordia/) 2.x extension that adds support for [Message Components](https://discord.com/developers/docs/interactions/message-components), such as buttons and select menus. This also offers a somewhat high-level interface for dealing with components, with features such as automatic rows, and client-side requirement checking.

## Documentation

See [the wiki](https://github.com/Bilal2453/discordia-components/wiki) for the API documentation.
The [discordia-interactions wiki](https://github.com/Bilal2453/discordia-interactions/wiki) is also very relevant, you should check it out.

If you still can't figure it out, feel free to ask me on Discord. Join the [Discordia Server](https://discord.gg/sinisterware) and ask your question in the extensions-help channel, make sure to post any errors you are getting if any, otherwise explain what you want to achieve and why it is not working, and most importantly the code you've tried.

## Installation

1. Install `lit` if not already installed, see [Luvit installation guide](https://luvit.io/install.html) and [Discordia installation Tutorial](https://github.com/SinisterRectus/Discordia/wiki/Installing-Discordia).
2. Open a terminal (PowerShell or CMD on Windows) and preferably `cd` into your bot's directory.
3. In the terminal, execute `lit install Bilal2453/discordia-components`. (Note: if you have not set up your PATH, you might have to do `./lit` instead of just `lit`)
Once that is done, you should see Lit print the message `done: success`, indicating you are now ready to require the extension from your Discordia project.

You may also install the latest main branch by replacing the command in step 3 with:
```sh
git clone https://github.com/Bilal2453/discordia-components.git ./deps/discordia-components && git clone https://github.com/Bilal2453/discordia-interactions.git ./deps/discordia-interactions`
```

## Examples

See the [examples](/examples) directory.

- [Ping Pong](examples/pingPong.lua)
- [Music Controls](examples/controlMusic.lua)
- TicTacToe (To Be Done)

## License

This project is licensed under the Apache License 2.0, see [LICENSE] for more information.
Make sure to include the original copyright notice when copying!
