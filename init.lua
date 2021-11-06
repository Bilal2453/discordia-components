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

local module = {
  Button = require("components/Button"),
  SelectMenu = require("components/SelectMenu"),
  Components = require("containers/Components")
}

-- [[ Patch the Module into Discordia as a Shortcut]]
do
  for k, v in pairs(module) do
    discordia[k] = v
  end
end

return module
