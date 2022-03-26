local null = require("json").null
local resolver = require("resolver")
local discordia = require("discordia")

local classes = discordia.class.classes
local rawComponents = resolver.rawComponents

---The Discordia Message class patched to include additional features.
---@class Message
---@field components table The raw table representing the components attached to this Message. See [Discord's Component Structure](https://discord.com/developers/docs/interactions/message-components#component-object) for documentations of this field.
---<!tag:patch>
local Message = classes.Message
local get = Message.__getters

-- monkey patch _loadMore to make sure other extensions that also patch _loadMore are still compatible
-- if other extensions don't account for this and just override it, load discordia-components lastly
do local oldLoad = Message._loadMore
  Message._loadMore = function(self, data)
    self._components = data.components
    return oldLoad(self, data)
  end
end

---Sets the message's components.
---If `components` is false or nil, the message's components are removed.
---
---Returns `true` on success, otherwise `nil, err`.
---@param components? Components-Resolvable|boolean
---@return boolean
function Message:setComponents(components)
  components = components and rawComponents(components) or {}
  return self:_modify{components = components}
end

---Sets multiple properties of the message at the same time. Identical to the one in Discordia;
---except supported fields are `content`, `embed` and `components`.
---
---Returns `true` on success, otherwise `nil, err`.
---@param data table
---@return boolean
---<!tag:http>
function Message:update(data)
  local components = data.components and rawComponents(data.components)
	return self:_modify{
    components = components or {},
		content = data.content or null,
		embed = data.embed or null,
	}
end

---<!ignore>
---Similar to `Message:update(data)` except `data` is optional and mainly used to modify `components` field of a message.
---If `components` is false/nil, all components on that message will be removed.
---`data` may optionally be supplied to override other fields such as `content`, `embed`, etc.
---
---Returns the modified version of the Message.
---@param components? Components-Resolvable|boolean
---@param data? table
---@return Message
---@deprecated Use `Message:update()` instead.
function Message:updateComponents(components, data)
  self.client._deprecated("Message", "updateComponents", "update")
  data = type(data) == "table" and data or {}
  if not components then
    data.components = {}
    return self:_modify(data)
  end
  assert(components == true or type(components) == "table", "bad argument #1 to updateComponents (expected a Components|falsy value)")
  data.components = rawComponents(components)
  return self:_modify(data)
end

---Equivalent to `Message.channel:sendComponents(content, components)`.
---@param content string|table
---@param components? Components-Resolvable|table
---@return Message
---<!tag:http>
function Message:replyComponents(content, components)
  return self._parent:sendComponents(content, components)
end

---Equivalent to `Message.client:waitComponent(Message, ...)`.
---@param type? string|number
---@param id? Custom-ID-Resolvable
---@param timeout? number
---@param predicate? function
---@return boolean
---@return ...
function Message:waitComponent(type, id, timeout, predicate)
  return self.client:waitComponent(self, type, id, timeout, predicate)
end

function get.components(self)
  return self._components
end

return Message
