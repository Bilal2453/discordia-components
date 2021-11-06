--[=[
@c Message
@t patch
@d A patched version of the Discordia Message class.
]=]

local null = require("json").null
local Resolver = require("Resolver")
local discordia = require("discordia")

local classes = discordia.class.classes
local rawComponents = Resolver.rawComponents

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

--[=[
@m updateComponents
@t http
@op components Components-Resolvable
@op data table
@r Message
@d Similar to `Message:update(data)` except `data` is optional and mainly used to modify `components` field of a message.
If `components` is set to falsy, all components on that message will be removed.
`data` may be optionally supplied to override more fields such as `content`, `embed`, etc.

Returns the modified version of the Message.
]=]
function Message:updateComponents(comp, data)
  data = type(data) == "table" or {}
  if not comp then
    data.components = null
    return self:_modify(data)
  end
  assert(type(comp) == "table", "bad argument #1 to updateComponents (expected a Components|falsy value)")
  data.components = rawComponents(comp)
  return self:_modify(data)
end

--[=[
@m replyComponents
@t http
@p content string/table
@p components Components-Resolvable/table
@r Message
@d Equivalent to `Message.channel:sendComponents(content, components)`.
]=]
function Message:replyComponents(...)
  return self._parent:sendComponents(...)
end

--[=[
@m waitComponent
@op type string/number
@op id Custom-ID-Resolvable
@op timeout number
@op predicate function
@r boolean
@r ...
@d Equivalent to `self.client:waitComponent(self, ...)`.
]=]
function Message:waitComponent(...)
  return self.client:waitComponent(self, ...)
end

--[=[@p components table The raw table representing the components attached to this Message.
See [Discord's Component Structure](https://discord.com/developers/docs/interactions/message-components#component-object)
for documentations of this field. ]=]
function get.components(self)
  return self._components
end

return Message
