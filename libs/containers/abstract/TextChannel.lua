local discordia = require("discordia")
local class = discordia.class
local classes = class.classes
local resolver = require("discordia-interactions").resolver
local rawComponents = require("resolver").rawComponents

---A patched version of the Discordia TextChannel class and its inherited classes;
---namely GuildTextChannel and PrivateChannel.
---@class TextChannel
---<!tag:patch>
local TextChannel = classes.TextChannel

---@alias Components-Resolvable table

---Sends a new message with provided components attached to it.
---`content` is equivalent to `TextChannel:send(content)` except it supports all Discord fields.
---`components` can be any Components Resolvable, or a raw table that represents a [Discord Component](https://discord.com/developers/docs/interactions/message-components#component-object).
--- Components must be provided either by providing `components` argument, or by providing `contnet.components`.
---
---Returns the newly sent Message.
---@param content string|table
---@param components? Components-Resolvable|table
---@return Message
---<!tag:http>
function TextChannel:sendComponents(content, components)
  assert(content, "bad argument #1 to sendComponents (expected a string|table value)")
  if type(content) == "table" and not components then
    assert(type(content.components) == "table", "components not provided, either provide argument #2 to sendComponents or field `components` to argument #1")
    components = content.components
  else
    assert(type(components) == "table", "bad argument #2 to sendComponents (expected a Components|table value)")
  end

  content = type(content) == "table" and content or {
    content = content,
  }
  content.components = rawComponents(components)
  local payload, files = resolver.message(content)
  local data, err = self.client._api:createMessage(self._id, payload, files)

  if data then
    return self._messages:_insert(data)
  else
    return nil, err
  end
end

local GuildTextChannel = classes.GuildTextChannel
local PrivateChannel = classes.PrivateChannel
GuildTextChannel.sendComponents = TextChannel.sendComponents
PrivateChannel.sendComponents = TextChannel.sendComponents

return TextChannel
