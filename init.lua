--[[
  Design Notes:

  1. builder using tables
  local component = TextChannel:newComponent {
    { -- Action Row 1, lib-controller
      id = "button_1"
      type = "button",
      style = "danger",
      disabled = true,
    },
    { -- Action Row 1, lib-controller
      id = "button_2"
      type = "button",
    },
    { -- Action Row 2, lib-controller
      id = "selectmenu_1"
      type = "selectMenu",
      options = {
        {label = "Option 1", value = "1", description = "The option 1 of this menu", default = true},
        {label = "Option 2", value = "2", description = "The option 2 of this menu"},
        {label = "Option 3", value = "3", description = "The option 3 of this menu"},
      },
      placeholder = "Select an option or else Discordia will kill you!",
      minValue = 2
    },
    { -- Action Row 3, user-controller
      id = "button_3"
      type = "button",
      actionRow = 3
    },
    { -- Action Row 1, lib-controller
      id = "button_4"
      type = "button",
      style = "primary",
    }
  }
  TextChannel:sendComponent(component) -- send empty message with components only
  -- or
  TextChannel:sendComponent {  -- Passed to custom TextChannel:send
    components = component,
    content = "Hello There" -- message content
  }
  -- In both cases, return the newly constructed message object, with proper component field linkde to the component object created by user

  2. builder using methods
  local component = TextChannel:newComponent()
    :button {
      id = "button_1"
      style = "danger",
      disabled = true
    }
    :button("button_2")
    :selectMenu {
      id = "selectmenu_1"
      options = {
        {label = "Option 1", value = "1", description = "The option 1 of this menu", default = true},
        {label = "Option 2", value = "2", description = "The option 2 of this menu"},
        {label = "Option 3", value = "3", description = "The option 3 of this menu"},
      },
      placeholder = "Select an option or else Discordia will kill you!",
      minValue = 2
    }
    :button("button_3", 3) -- optional action row
    :button {
      id = "button_4"
      style = "primary",
    }
  -- same way of sending component to previous

  3. builder using classes
  local DI = require("discordia-components")
  local button = DI.Button("button_3")
    :style "danger"
  local components = TextChannel:newComponent()
    :button(
      DI.Button("button_1")
        :style("danger")
        :disable()
    )
    :button("button_2")
    :selectMenu(
      DI.SelectMenu("selectmenu_1")
        :option("Option 1", "1", "The option 1 of this menu", true)
        :option("Option 2", "2", "The option 2 of this menu")
        :option("Option 3", "3", "The option 3 of this menu")
        :placeholder("Select an option or else Discordia will kill you")
        :minValue(2)
    )
    :button(button, 3) -- optional action row
    -- etc
]]

local discordia = require("discordia")
require("../discordia-interactions")

-- [[ Patch Following Classes Into Discordia ]]
require("client/Client")
require("containers/abstract/Component")
require("containers/abstract/TextChannel")
require("containers/Message")

-- [[ Patch Discordia's Enums to Add New Types ]]
do
  local enums = require("enums")
  local discordiaEnums = discordia.enums
  local enum = discordiaEnums.enum
  for k, v in pairs(enums) do
    discordiaEnums[k] = enum(v)
  end
end

-- [[ Add a Shortcut to The Builder ]]
discordia.Components = require("containers/Components")

return {
  Button = require("components/Button"),
  SelectMenu = require("components/SelectMenu"),
  Components = require("containers/Components")
}
