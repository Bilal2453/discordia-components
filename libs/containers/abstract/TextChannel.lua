local discordia = require("discordia")
local class = discordia.class
local classes = class.classes
local Resolver = require("Resolver")
local rawComponents = Resolver.rawComponents

local TextChannel = classes.TextChannel
local send = require("ported").TextChannel.send

function TextChannel:sendComponents(comp, content)
  assert(type(comp) == "table", "bad argument #1 to sendComponents (expected a table|Component value)")
  assert(content, "bad argument #2 to sendComponents (expected a string|table value)")
  content = type(content) == "table" and content or {content = content}
  content.components = rawComponents(comp)
  return send(self, content)
end

local GuildTextChannel = classes.GuildTextChannel
local PrivateChannel = classes.PrivateChannel
GuildTextChannel.sendComponents = TextChannel.sendComponents
PrivateChannel.sendComponents = TextChannel.sendComponents

return TextChannel
