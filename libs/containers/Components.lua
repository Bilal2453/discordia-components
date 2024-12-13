local discordia = require("discordia")
local enums = require("enums")
local class = discordia.class
local isInstance = class.isInstance
local componentType = enums.componentType

local utils = require("utils")
local errorf = utils.errorf

local Component = require("containers/abstract/Component")
local ComponentsContainer = require("containers/abstract/ComponentsContainer")
local SelectMenu = require("components/SelectMenu")
local Button = require("components/Button")

---Represents a set of Component objects, offering an interface to control, modify, and retrieve Message Components easily.
---This is the entry point of this library and what this whole thing is about, that is, the builder.
---@class Components: ComponentsContainer
---@field buttons ArrayIterable A cache of all constructed Button objects in this instance.
---@field selectMenus ArrayIterable A cache of all constructed SelectMenu objects in this instance.
---@type fun(data?: Components-Resolvable): Components
---@overload fun(data: table): Components
---<!tag:interface> <!method-tags:mem>
local Components = class("Components", ComponentsContainer)

local MAX_ROW_CELLS = 5 -- Maximum number of components per action row.
local MAX_ROWS = 5 -- Maximum number of action rows per message.
local COMPONENTS = {Button, SelectMenu}

---<!ignore>
---Creates a new `Components` object to act as the container and the builder for all of the components.
---@param data table
function Components:__init(data)
  ComponentsContainer.__init(self, {
    maxRows = MAX_ROWS,
    maxRowCells = MAX_ROW_CELLS,
    components = COMPONENTS,
  })
  if data then return self:_load(data) end
end

local function copy(tbl)
  local rtn = {}
  for i, v in pairs(tbl) do
    rtn[i] = v
  end
  return rtn
end

---<!ignore>
---Load the provided data into the instance cache.
---@param data Components|Component|table<number, table>
function Components:_load(data)
  local data_type = type(data)
  if data_type ~= "table" then
    errorf("bad argument #1 to Components (expected Component|table of Component-like|Components, got %s)", 4, data_type)
  end
  if isInstance(data, Components) then
    self._cacheMap = copy(data._cacheMap)
    self._rows = copy(data._rows)
  elseif isInstance(data, Component) then
    self:_buildComponent(data.__class, data)
  elseif #data > 0 and type(data[1]) == "table" and data[1].type then
    for i = 1, #data do
      local comp = data[i]
      local comp_type = type(comp.type) == "number" and comp.type or componentType[comp.type]
      self:_buildComponent(COMPONENTS[comp_type - 1], comp)
    end
  else
    errorf("bad components structure", 4)
  end
end

---Constructs a new Button object with the initial provided data; if `data` is a string it is treated
---as if it were the `id` field. `actionRow` is an optional number of which Action Row this Button should go into.
---
---Returns self.
---@param data Button-Resolvable|Custom-ID-Resolvable
---@param actionRow? number
---@return Components self
function Components:button(data, actionRow)
  assert(data, "data argument is required")
  self:_buildComponent(Button, data, actionRow)
  return self
end

---Constructs a new SelectMenu object with the initial provided data; if `data` is a string
---it is treated as if it were the `id` field.
---
---Returns self.
---@param data SelectMenu-Resolvable|Custom-ID-Resolvable
---@return Components self
function Components:selectMenu(data)
  assert(data, "data argument is required")
  self:_buildComponent(SelectMenu, data)
  return self
end

---Removes a previously constructed Button object with the custom_id of `id`.
---
---Returns self and the removed Button.
---@param id string
---@return Components self
---@return Button # The removed [[Button]] object.
function Components:removeButton(id)
  return self:_remove(Button, id)
end

---Removes a previously constructed SelectMenu object with the custom_id of `id`.
---
---Returns self and the removed [[SelectMenu]] object.
---@param id string
---@return Components self
---@return SelectMenu # The removed SelectMenu object.
function Components:removeSelectMenu(id)
  return self:_remove(SelectMenu, id)
end

return Components
