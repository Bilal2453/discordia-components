--[=[
@c SelectMenu x Component
@t ui
@mt mem
@p data SelectMenu-Resolvable
@d Represents a Component of type SelectMenu. SelectMenus are interactive message components
that offers the user multiple choices form, once one is selected an interactionCreate event is fired.

For accepted `data` table's fields see SelectMenu-Resolvable.

General rules you should follow:
1. Only a single SelectMenu can be sent in each Action Row.
2. SelectMenu and Buttons cannot be in same row.
]=]

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

  -- Properly load rest of data
  self:_load(data)
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

function SelectMenu:_load(data)
  if data.options then
    self:options(data.options)
  end
  if data.placeholder then
    self:placeholder(data.placeholder)
  end
  if data.minValues then
    self:minValues(data.minValues)
  end
  if data.maxValues then
    self:maxValues(data.maxValues)
  end
end

--[=[
@m option
@p label table/string
@op value string
@op description string
@op default boolean
@op emoji Emoji-Resolvable
@r SelectMenu
@d Creates a new option in the menu with the provided values. If `label` is a table
you should pass rest of parameters as fields in that table, the only required fields are `label` and `value`.

Returns self.
]=]
function SelectMenu:option(label, value, description, default, emoji)
  local data = type(label) == "table" and label or {
    label = label,
    value = value,
    description = description,
    default = default,
    emoji = emoji
  }

  local err = "field %s must be a string that is at most 100 character long"
  local function check(v) return type(v) == "string" and #v <= 100 end
  assert(data.label and check(data.label), err:format("label"))
  assert(data.value and check(data.value), err:format("label"))
  assert(not data.description or check(data.description), err:format("description"))

  local options = self._data.options
  if not options then self._data.options = {} end
  options[#options + 1] = data
  return self
end

--[=[
@m options
@p options table
@r SelectMenu
@d Overrides current options with the ones provided. `options` is an array of tables (25 at most),
each representing an option, available fields for each option are: `label` and `value` required,
`description`, `default`, `emoji` optional; See option method's parameters for more info.

Returns self.
]=]
function SelectMenu:options(options)
  assert(type(options) == "table", "options must be a table value")
  assert(#options <= 25, "options can at most have 25 option only")
  return self:_set("options", options)
end

--[=[
@m placeholder
@p placeholder string
@r SelectMenu
@d A placeholder in case nothing is specified.

Returns self.
]=]
function SelectMenu:placeholder(placeholder)
  placeholder = tostring(placeholder)
  assert(placeholder and #placeholder <= 100, "placeholder must be a string that is at most 100 character long")
  return self:_set("placeholder", placeholder)
end

--[=[
@m minValues
@p val number
@r SelectMenu
@d The least required amount of options to be selected. Must be in range 0 < `val` <= 25.

Returns self.
]=]
function SelectMenu:minValues(val)
  val = tonumber(val) or -1
  assert(val > 0 and val <= 25, "minValues must be a number in the range 0-25")
  return self:_set("minValues", val)
end

--[=[
@m maxValues
@p val number
@r SelectMenu
@d The upmost amount of options to be selected.Must be in range `val` <= 25.

Returns self.
]=]
function SelectMenu:maxValues(val)
  val = tonumber(val) or -1
  assert(val <= 25, "maxValues must be a number that is <= 25")
  return self:_set("maxValues", val)
end

return SelectMenu
