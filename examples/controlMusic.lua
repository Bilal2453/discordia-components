-- usage:
--  !music

local discordia = require("discordia")
require("discordia-components")

local client = discordia.Client()

local musicalControls = discordia.Components {
  {
    id = "skip_backwards",
    type = "button",
    label = "Previous Song",
    emoji = "⏪",
  },
  {
    id = "resume",
    type = "button",
    label = "Resume Song",
    emoji = "▶️",
  },
  {
    id = "pause",
    type = "button",
    label = "Pause Song",
    emoji = "⏸️",
  },
  {
    id = "skip_forward",
    type = "button",
    label = "Next Song",
    style = "secondary",
    emoji = "⏩",
  },
  {
    id = "abort",
    type = "button",
    label = "Abort Song",
    style = "danger",
    actionRow = 2,
  },
}

local action_map = {
  skip_backwards = function (intr)
    intr:reply("Skipped to previous song", true)
  end,
  resume = function (intr)
    intr:update("Song is currently playing!")
  end,
  pause = function (intr)
    intr:update("Song is currently paused!")
  end,
  skip_forward = function (intr)
    intr:reply("Skipped to next song", true)
  end,
  abort = function (intr, msg)
    msg:setComponents(false)
    intr:reply {
      embed = {
        title = "Aborted",
        color = 0xf20000,
      }
    }
  end,
}

client:on("messageCreate", function(message)
  if message.content == "!music" then
    local sent_msg = message:replyComponents("Here your music controls!", musicalControls)

    local success, interaction
    local pressed_button
    repeat
      success, interaction = sent_msg:waitComponent("button")
      if not success then
        break
      end
      pressed_button = interaction.data.custom_id
      action_map[pressed_button](interaction, sent_msg)
    until pressed_button == "abort"
  end
end)

client:run("Bot [TOKEN]")
