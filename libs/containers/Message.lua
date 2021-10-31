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

function Message:updateComponents(comp, data)
  data = type(data) == "table" or {}
  if not comp then
    data.components = null
    return self:_modify(data)
  end
  assert(type(comp) == "table", "bad argument #1 to updateComponents (expected a table|boolean value)")
  data.components = rawComponents(comp)
  return self:_modify(data)
end

function Message:replyComponents(...)
  return self._parent:sendComponents(...)
end

function get.components(self)
  return self._components
end

return Message
