local discordia = require("discordia")
local class = discordia.class

local Component, get = class("Component")

function Component:__init(data, type)
  assert(data, "argument data must be supplied") -- always required.. ?
  data.type = type

  self._data = data
  self._actionRow = tonumber(data.actionRow)
end

function Component:set(property, value)
  self._data[property] = value
  return self
end

function Component:get(property)
  return self._data[property]
end

local function lowercase(m)
  return '_' .. m:lower()
end

-- Tries to assume what the raw field names are and returns that assumption
-- if the defined component fields do not match this;
-- you should overwrite :raw in the said component object
function Component:raw()
  local raw = {}
  for k, v in pairs(self._data) do
    raw[k:gsub('([A-Z])', lowercase)] = v
  end
  raw.custom_id, raw.id = raw.id, nil -- id field is always translated to custom_id in components
  raw.action_row = nil -- discord never accept such a field, used internally only
  return raw
end


function get.type(self)
  return self._data.type
end

function get.id(self)
  return self._data.id
end

return Component
