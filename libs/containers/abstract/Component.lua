local discordia = require("discordia")
local class = discordia.class

---Represents any Message Component, all other components classes should inherit from this.
---@class Component
---@field type number The component type. See componentType enumeration for further info.
---@field id string The component custom_id. Nil for some components such as Link Buttons.
---@field disabled boolean Whether the current component is disabled or not.
---@field actionRow number The Action Row this component is using.
---@type fun(data: table, type: number): Component
---<!tag:abstract> <!method-tags:mem>
local Component, get = class("Component")

---@type table
local getter = get

function Component:__init(data, type)
  assert(data, "argument data must be supplied") -- always required.. ?
  data.type = type

  self._data = data
  self._actionRow = tonumber(data.actionRow)
end

function Component:_set(property, value)
  self._data[property] = value
  return self
end

---Sets the provided field(s) value. If `property` is a table, `value` is ignored;
---the key of an entry is treated as the field name, and its value is the field's value.
---Otherwise if `property` is a string, `value` is required.
---Keep in mind this will validate the inputs and error if not valid.
---@param property string|table
---@param value? any
---@return Component self
function Component:set(property, value)
  property = type(property) == "table" and property or {
    [property] = value
  }

  ---@diagnostic disable: undefined-field
  if self._load then
    self:_load(property)
  else
    for k, v in pairs(property) do
      self._data[k] = v
    end
  end

  return self
end

---Returns the value of the provided `property` name.
---@param property string
---@return any
function Component:get(property)
  return self._data[property]
end

---Sets the `disabled` field to `true`.
---
---Returns self.
---@return Component self
function Component:disable()
  return self:_set("disabled", true)
end

---Sets the `disabled` field to `false`.
---
---Returns self.
---@return Component self
function Component:enable()
  return self:_set("disabled", false)
end

local function lowercase(m)
  return '_' .. m:lower()
end

-- Tries to assume what the raw field names are and returns that assumption
-- if the defined component fields do not match this;
-- you should overwrite :raw in the said component object

---Returns a table value of what the raw value Discord would accept is like based on assumptions
---of the current component's field names.
---
---By design, user should never need to use this method.
---@return table
function Component:raw()
  local raw = {}
  for k, v in pairs(self._data) do
    raw[k:gsub('([A-Z])', lowercase)] = v
  end
  raw.custom_id, raw.id = raw.id, nil -- id field is always translated to custom_id in components
  raw.action_row = nil -- discord never accept such a field, used internally only
  return raw
end

function getter:type()
  return self._data.type
end

function getter:id()
  return self._data.id
end

function getter:disabled()
  return self._data.disabled or false
end

function getter:actionRow()
  return self._actionRow
end

return Component
