# Discordia-Components
discordia-components is a Discordia 2.x extension that makes sending and responding to Buttons/SelectMenus possible!

As of time of writing this, the library is still in beta, but it should be fully functional with only few bugs.

## Documentations
For docs please refer to [the wiki](https://github.com/Bilal2453/discordia-components/wiki)

## Installing

To install this library you have two options:
**Note: Due to unsolved bug in Lit, the package will error when installing; as of now you will have to use the Git method described below.**
1. `lit install Bilal2453/discordia-components`. ~~(preferred)~~
2. `git clone https://github.com/Bilal2453/discordia-components.git && git clone https://github.com/Bilal2453/discordia-interactions.git`.
    After cloning both, make sure to rename them to become `discordia-components` and `discordia-interactions` respectively. Then moving both into your `deps` folder.

## Examples
More examples and tutorials are planned, but as of now here are couple that should do:

Music Controls Loop:
```lua
local discordia = require("discordia")
require("discordia-components")

local client = discordia.Client()
local musicalControls = discordia.Components {
  {
    id = "skip_single",
    type = "button",
    label = "Skip Song",
    style = "secondary",
    emoji = "⏭️",
  },
  {
    id = "pause",
    type = "button",
    label = "Pause Song",
    emoji = "⏯️",
  },
  {
    id = "resume",
    type = "button",
    label = "Resume Song",
    emoji = "⏯️",
  },
  {
    id = "abort",
    type = "button",
    label = "Abort Song",
    style = "danger",
    actionRow = 2,
  },
}

client:on("messageCreate", function(msg)
  if msg.content == "!music" then
    local bmsg = msg:replyComponents("Here your music controls!", musicalControls)

    local success, inter
    while true do
      success, inter = bmsg:waitComponent("button")
      if not success then break end

      if inter.data.custom_id == "skip_single" then
        inter:reply("Song Skipped! Playing Next One", true)
      elseif inter.data.custom_id == "pause" then
        inter:update("Song is Currently Paused!")
      elseif inter.data.custom_id == "resume" then
        inter:update("Playing Cool Song!")
      else
        inter:reply("Aborting!")
        break
      end
    end
  end
end)

client:run("Bot TOKEN")
```

Simple Tic Tac Toe: (Note this does not check for game end or winners)
```lua
local discordia = require("discordia")
require("discordia-components")

local client = discordia.Client()
local function defaultControls()
  local defaultButtons = discordia.Components()
  for i=1, 9 do
    defaultButtons:button {
      id = i,
      style = "secondary",
      label = "-",
      actionRow = math.ceil(i / 3),
    }
  end
  defaultButtons:button {
    id = "abort",
    label = "Abort",
    style = "danger",
    actionRow = 4,
  }
  return defaultButtons
end

local activeGames = {}

client:on("messageCreate", function(msg)
  if msg.content == "!tie" then
    if activeGames[msg.author.id] then
      msg:reply "A game is already active! consider aborting it before starting a new one"
      return
    end
    activeGames[msg.author.id] = true
    local playerState = true

    local components = defaultControls()
    local cmsg = msg:replyComponents("Your gameplay is ready:", components)

    while true do
      local _, inter = cmsg:waitComponent("button")
      if inter.data.custom_id == "abort" then
        inter:reply("Game have been aborted")
        activeGames[msg.author.id] = nil
        break
      end

      local buttonId = tonumber(inter.data.custom_id)
      local button = components.buttons:find(function(b)
        return b.id == buttonId
      end)
      
      button:label(playerState and "X" or "O")
        :style(playerState and "danger" or "primary")
        :disable()

      playerState = not playerState
      inter:update {
        components = components:raw()
      }
    end
  end
end)

client:run("Bot ")
```
