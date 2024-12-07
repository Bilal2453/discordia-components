--[[
                    Apache License 2.0

  Copyright (c) 2022-2024 Bilal2453

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
]]

local discordia = require("discordia")
local discordiaInteractions = require("discordia-interactions")
local rawComponents = require("resolver").rawComponents

local isInstance = discordia.class.isInstance
local resolver = discordiaInteractions.resolver

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

-- [[ Patch the module into Discordia as an entry point ]]
for k, v in pairs(module) do
  discordia[k] = v
end

-- [[ Wrap resolver.message to make it understand components field ]]
resolver.message_resolvers.components = function(content)
  if isInstance(content, module.Components) or isInstance(content, module.Component) then
    return {
      components = content
    }
  end
end

resolver.message_wrappers.components = function(content)
  if content.components then
    content.components = rawComponents(content.components) or content.components
  end
end

return module
