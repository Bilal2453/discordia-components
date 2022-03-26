local discordia = require("discordia")
require("discordia-interactions")

-- [[ Define the module's classes ]]
local module = {
  Component = require('containers/abstract/Component'),
  Components = require("containers/Components"),
  Button = require("components/Button"),
  SelectMenu = require("components/SelectMenu"),
}

-- [[ Patch the following Discordia classes ]]
require("client/Client")
require("containers/abstract/Component")
require("containers/abstract/TextChannel")
require("containers/Message")

-- [[ Patch Discordia's enums to add additional values ]]
do
  local enums = require("enums")
  local discordiaEnums = discordia.enums
  local enum = discordiaEnums.enum
  for k, v in pairs(enums) do
    discordiaEnums[k] = enum(v)
  end
end

-- [[ Path the module into Discordia as an entry point ]]
for k, v in pairs(module) do
  discordia[k] = v
end

return module
