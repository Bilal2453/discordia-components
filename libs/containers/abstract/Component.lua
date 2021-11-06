--[=[
@c Component
@t abc
@mt mem
@p data table
@p type number
@d Represents any Message Component, all other components classes should inherit from this.
]=]

local discordia = require("discordia")
local class = discordia.class

local Component, get = class("Component")

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

--[=[
@m set
@p property string/table
@op value any
@r Component
@d Sets the provided field(s) value. If `property` is a table, `value` is ignored;
the key of an entry is treated as the field name, and its value is the field's value.
Otherwise if `property` is a string, `value` is required.
Keep in mind this does not bypass validation rules.
]=]
function Component:set(property, value)
  property = type(property) == "table" and property or {
    [property] = value
  }

  if self._load then
    self:_load(property)
  else
    for k, v in pairs(property) do
      self._data[k] = v
    end
  end

  return self
end

--[=[
@m get
@p property string
@r any
@d Returns the value of the provided `property` name.
]=]
function Component:get(property)
  return self._data[property]
end

--[=[
@m disable
@r Component
@d Sets the `disabled` field to `true`.

Returns self.
]=]
function Component:disable()
  return self:_set("disabled", true)
end

--[=[
@m enable
@r Component
@d Sets the `disabled` field to `false`.

Returns self.
]=]
function Component:enable()
  return self:_set("disabled", false)
end

local function lowercase(m)
  return '_' .. m:lower()
end


--[=[
@m raw
@r table
@d Returns a table value of what the raw value Discord would accept is like based on assumptions
of the current component's field names.

User should never need to use this. Only documented for advanced users.
]=]
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

--[=[@p type number The component type as. See componentType enumeration for further info.]=]
function get.type(self)
  return self._data.type
end

--[=[@p id string The component custom_id. Nil for some components such as Link Buttons.]=]
function get.id(self)
  return self._data.id
end

--[=[@p disabled boolean Whether the current component is disabled or not.]=]
function get.disabled(self)
  return self._data.disabled or false
end

--[=[@p actionRow number The Action Row this component is using.]=]
function get.actionRow(self)
  return self._actionRow
end

return Component
