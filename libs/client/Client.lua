local discordia = require("discordia")
local class = discordia.class
local classes = class.classes

local enums = require("enums")
local componentType = enums.componentType
local interactionType = discordia.enums.interactionType

local Client = classes.Client

local function buildPredicate(msg, typ, id, predicate)
  predicate = type(predicate) == "function" or false
  return function(inter, ...)
    return (inter.type == interactionType.messageComponent) -- interaction corresponds to message component?
      and (not msg or inter.message and inter.message.id == msg.id) -- interaction was on same targeted message?
      and (not typ or typ == inter.data.component_type) -- does component type match user provided one if any?
      and (not id or id == inter.data.custom_id) -- does component id match user provided one if any?
      and (not predicate or predicate(inter, ...)) -- is user provided predicate satisfied if any?
  end
end

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
