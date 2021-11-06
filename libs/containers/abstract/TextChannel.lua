--[=[
@c TextChannel
@t patch
@d A patched version of the Discordia TextChannel class and its inherited classes;
 namely GuildTextChannel and PrivateChannel.
]=]

local discordia = require("discordia")
local class = discordia.class
local classes = class.classes
local Resolver = require("Resolver")
local rawComponents = Resolver.rawComponents

local TextChannel = classes.TextChannel
local send = require("ported").TextChannel.send

--[=[
@m sendComponents
@t http
@p content string/table
@p components Components-Resolvable/table
@r Message
@d Sends a new message with provided components attached to it. `content` is equivalent to
`TextChannel:send(content)`. `components` can be any Components Resolvable,
or a raw table that represents a [Discord Component](https://discord.com/developers/docs/interactions/message-components#component-object).
Returns the newly sent Message.
]=]
function TextChannel:sendComponents(content, comp)
  assert(content, "bad argument #1 to sendComponents (expected a string|table value)")
  assert(type(comp) == "table", "bad argument #2 to sendComponents (expected a Components|table value)")
  content = type(content) == "table" and content or {content = content}
  content.components = rawComponents(comp)
  return send(self, content)
end

local GuildTextChannel = classes.GuildTextChannel
local PrivateChannel = classes.PrivateChannel
GuildTextChannel.sendComponents = TextChannel.sendComponents
PrivateChannel.sendComponents = TextChannel.sendComponents

return TextChannel
