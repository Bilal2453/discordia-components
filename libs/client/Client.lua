local discordia = require("discordia")
local class = discordia.class
local classes = class.classes

local enums = require("enums")
local componentType = enums.componentType
local interactionType = discordia.enums.interactionType

local Client = classes.Client

local function buildPredicate(typ, id, predicate)
  predicate = type(predicate) == "function" or false
  return function(inter, ...)
    return (inter.type == interactionType.messageComponent)
      and (not typ or typ == inter.data.component_type)
      and (not id or id == inter.data.custom_id)
      and (not predicate or predicate(inter, ...))
  end
end

function Client:waitComponent(typ, id, timeout, predicate)
  typ = type(typ) == "number" and typ or componentType[typ]
  predicate = buildPredicate(typ, id, predicate)
  return self:waitFor("interactionCreate", timeout, predicate)
end

return Client
