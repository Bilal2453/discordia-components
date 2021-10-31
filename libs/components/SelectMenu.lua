local Component = require("containers/abstract/Component")
local discordia = require("discordia")
local enums = require("enums")
local class = discordia.class
local componentType = enums.componentType

local SelectMenu = class("SelectMenu", Component)

function SelectMenu:__init(data)
  -- Validate input into appropriate structure
  data = self._validate(data)
  assert(data.id, "an id must be supplied")
  -- Make sure options structure always exists
  if not data.options then
    data.options = {}
  end

  -- Base constructor initializing
  Component.__init(self, data, componentType.selectMenu)
end

function SelectMenu._validate(data)
  if type(data) ~= "table" then
    data = {id = data}
  end
  return data
end

function SelectMenu._eligibilityCheck(c)
  local err = "An Action Row that contains a Select Menu cannot contain any other component!"
  return not c, err
end

function SelectMenu:disable()
  return self:set("disabled", true)
end

function SelectMenu:enable()
  return self:set("disabled", false)
end

function SelectMenu:option(label, value, description, default, emoji)
  local data = type(label) == "table" and label or {
    label = label,
    value = value,
    description = description,
    default = default,
    emoji = emoji
  }

  local err = "field %s must be a string that is at most 100 character long"
  local function check(v) return type(v) == "string" and v <= 100 end
  assert(data.label and check(data.label), err:format("label"))
  assert(data.value and check(data.value), err:format("label"))
  assert(not data.description or check(data.description), err:format("description"))

  local options = self._data.options
  if not options then self._data.options = {} end
  options[#options + 1] = data
  return self
end

function SelectMenu:options(options)
  assert(type(options) == "table", "options must be a table value")
  assert(#options <= 25, "options can at most have 25 option only")
  return self:set("options", options)
end

function SelectMenu:placeholder(placeholder)
  placeholder = tostring(placeholder)
  assert(placeholder and placeholder <= 100, "placeholder must be a string that is at most 100 character long")
  return self:set("placeholder", placeholder)
end

function SelectMenu:minValues(val)
  val = tonumber(val) or -1
  assert(val > 0 and val <= 25, "minValues must be a number in the range 0-25")
  return self:set("minValues", val)
end

function SelectMenu:maxValues(val)
  val = tonumber(val) or -1
  assert(val <= 25, "maxValues must be a number that is <= 25")
  return self:set("maxValues", val)
end

return SelectMenu
