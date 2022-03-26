local discordia = require("discordia")
local class = discordia.class
local classes = class.classes

local enums = require("enums")
local componentType = enums.componentType
local interactionType = discordia.enums.interactionType

---The Discordia Client class patched to include additional features.
---@class Client
---<!tag:patch>
local Client = classes.Client

local function buildPredicate(msg, typ, id, predicate)
  predicate = type(predicate) == "function" and predicate or false
  return function(inter, ...)
    return
      -- interaction corresponds to message component?
      (inter.type == interactionType.messageComponent)
      -- interaction was on same targeted message?
      and (not msg or inter.message and inter.message.id == msg.id)
      -- does component type match user provided one if any?
      and (not typ or typ == inter.data.component_type)
      -- does component id match user provided one if any?
      and (not id or id == inter.data.custom_id)
      -- is user provided predicate satisfied if any?
      and (not predicate or predicate(inter, ...))
  end
end

---@alias Custom-ID-Resolvable string

---Equivalent to `client:waitFor("interactionCreate", timeout, predicate)`
---except that it pre-provides a predicate for ease of use.
---If `msg` is provided, only interactionCreate event that reference this Message will pass.
---`type` is the type of the component interaction see componentType enumeration for acceptable values,
---if none specified any will match.
---`id` is the component custom_id, if none provided any id will match,
---`timeout` behave similar to waitFor's, so do `predicate`.
---@param msg? Message
---@param typ? string|number
---@param id? Custom-ID-Resolvable
---@param timeout? number
---@param predicate? function
---@return boolean
---@return ...
function Client:waitComponent(msg, typ, id, timeout, predicate)
  if msg then
    assert(#msg._components > 0, "Cannot wait for components on a message that does not even contain any components")
    assert(msg.author == msg.client.user, "Cannot wait for components on a message not owned by this bot client")
  end

  typ = type(typ) == "number" and typ or componentType[typ]
  predicate = buildPredicate(msg, typ, id, predicate)

  return self:waitFor("interactionCreate", timeout, predicate)
end

return Client
