local discordia = require("discordia")
local enums = require("enums")
local class = discordia.class
local classes = class.classes
local ceil, max, min = math.ceil, math.max, math.min
local isInstance = class.isInstance
local componentType = enums.componentType

local resolver = require("resolver")
local objComponents = resolver.objComponents

local ArrayIterable = classes.ArrayIterable
local SelectMenu = require("components/SelectMenu")
local Button = require("components/Button")

---Represents a set of Component objects, offering an interface to control, modify, and retrieve Components easily.
---This is the entry point of this library and what this whole thing is about, that is, the builder.
---@class Components
---@field buttons ArrayIterable A cache of all constructed Button objects in this instance.
---@field selectMenus ArrayIterable A cache of all constructed SelectMenu objects in this instance.
---@type fun(data?: Components-Resolvable): Components
---<!tag:interface> <!method-tags:mem>
local Components, get = class("Components")

---@type table
local getter = get

local MAX_ROW_CELLS = 5 -- Maximum number of components per action row.
local MAX_ROWS = 5 -- Maximum number of action rows per message.
local MAX_COMPONENTS = MAX_ROW_CELLS * MAX_ROWS -- Maximum overall components per message.

---<!ignore>
---Returns the index at which the cell is located at in a table of MAX_ROW_CELLS rows.
---@param row number
---@param column number
---@return number
local function cellIndex(row, column)
  return (row - 1) * MAX_ROW_CELLS + column
end

---<!ignore>
---Locate the index of the very last cell in a table of MAX_COMPONENTS nodes.
---@param tbl table
---@return number
local function findLast(tbl)
  -- FIXME: would starting at index 1 or at MAX_COMPONENTS be better?
  for i = MAX_COMPONENTS, 1, -1 do
    if tbl[i] ~= nil then return i end
  end
end

---<!ignore>
---Return the component index that matches the provided id in table `tbl`.
---@param tbl table
---@param id string
---@return number
local function findComponent(tbl, id)
  for i = 1, #tbl do
    if tbl[i].id == id then return i end
  end
end

---<!ignore>
---Sets the fields `_buttons`, `_selectMenus` and `_cacheMap` to their initial values.
---@param obj Components
local function buildCompCache(obj)
  obj._buttons = {}
  obj._selectMenus = {}
  obj._cacheMap = {
    [SelectMenu] = obj._selectMenus,
    [Button] = obj._buttons,
  }
end


---<!ignore>
---Creates a new `Components` object to act as the container and the builder for all of the components.
---@param data table
---@return Components
function Components:__init(data)
  if data then return self:_load(data) end
  self._cacheMap = {}
  buildCompCache(self)

  -- An array of Component objects (nils as default) to track each action row stats,
  -- where a cell will be a Component-based object if provided at that index, otherwise a nil.
  -- This inconvenient structure is used to make sure we are not wasting any memory;
  -- Glad to suffer in order to save your memory!
  -- Maybe I felt bad for eating some of your brain's memories earlier and want to make up for it,
  -- who knows.
  self._rows = {
    -- nil, nil, nil, nil, nil, -> Row 1
    -- nil, nil, nil, nil, nil, -> Row 2
    -- nil, nil, nil, nil, nil, -> Row 3
    -- nil, nil, nil, nil, nil, -> Row 4
    -- nil, nil, nil, nil, nil, -> Row 5
    n = 0, -- how many cells(components) are currently provided
    m = 0, -- in which row the last cell is located?
  }
end

---<!ignore>
---Load the provided data into the instance cache.
---@param data Component|table<number, table>
function Components:_load(data)
  data = objComponents(data)
  if not data then return end
  self._buttons = data._buttons
  self._selectMenus = data._selectMenus
  self._rows = data._rows
end

---<!ignore>
---Adds a component object to the `self._row` cache at the specified `index` if possible.
---@param index number
---@param value Component
function Components:_insert(index, value)
  local rows = self._rows
  if rows[index] then return end

  rows[index] = value
  rows.n = rows.n + 1
  rows.m = max(rows.m, ceil(findLast(rows) / 5))

  local typ = value.__class
  local cache = self._cacheMap[typ]
  if findComponent(cache, value.id) then
    error((
      'Component of the type "%s" and the ID "%s" already exists; ' ..
      "Cannot have two components of the same type and ID at the same time!"
    ):format(typ.__name, value.id), 4)
  end
  cache[#cache + 1] = value
end

---<!ignore>
---Removes a component of the id `id` and the type `type` from the `self._rows` cache.
---@param type Component
---@param id string
---@return Components self
---@return Component # The removed component.
function Components:_remove(type, id)
  local cache = self._cacheMap[type]
  local index = findComponent(cache, id)
  local rows = self._rows
  if not index then
    error(('No such %s with the ID %s'):format(type.__name, id), 2)
  end
  table.remove(cache, index)

  index = findComponent(rows, id)
  rows.n = rows.n - 1
  rows.m = max(rows.m, ceil(findLast(rows) / 5))

  return self, table.remove(rows, index)
end

---<!ignore>
---Iterates the table `rows` and returns the first empty cell out of MAX_COMPONENTS cells.
---@param rows table
---@return boolean success
---@return number|string result # The cell index if `success` is true, otherwise a string explaining what went wrong.
local function checkAny(rows)
  for c = 1, MAX_COMPONENTS do
    if not rows[c] then
      return true, c
    end
  end
  return false, ("All Action Rows are full; Cannot have more than %d component per message")
    :format(MAX_COMPONENTS)
end

---<!ignore>
---Iterates table `rows` and returns the index of the first cell that satisfies the predicate at row `targetRow`.
---@param rows table
---@param targetRow number
---@param predicate fun(cell: Component, cellIndex: number)
---@return boolean success
---@return string|number result # The cell index if `success` is true, otherwise a string explaining what went wrong.
local function checkPredicate(rows, targetRow, predicate)
  local success, msg, cell
  for c = cellIndex(targetRow, 1), targetRow * MAX_ROW_CELLS do
    if rows[c] then
      success, msg = predicate(rows[c], c)
    elseif not cell then
      cell = c -- first empty cell
    end
    if success == false then
      return false, msg or "Predicate was not satisfied"
    end
  end
  if not cell then
    return false, "Action Row not eligible" -- user should never see this error message
  end
  return true, cell
end

---<!ignore>
---Returns the first cell that fits the predicate at the provided actionRow if provided, or at any row if not.
---@param targetRow number
---@param predicate fun(cell:Component,cellIndex:number)
---@return boolean success
---@return string|number result # The cell index if `success` is true, otherwise a string explaining what went wrong.
function Components:_isEligible(targetRow, predicate)
  targetRow = tonumber(targetRow)
  local rows = self._rows

  -- Do we even have an available action row to start with?
  if rows.n >= MAX_COMPONENTS then
    return false, ("All Action Rows are full; Cannot have more than %d component per message")
      :format(MAX_COMPONENTS)
  end

  -- Does the specified action row jump over an empty row? that's a gap between rows
  if targetRow and targetRow > rows.m + 1 then
    return false, "Cannot use an Action Row while the previous row is empty"
  end

  -- If no predicate is specified, use first empty cell
  if type(predicate) ~= "function" then
    return checkAny(rows)
  end

  -- If targetRow is presented, run the predicate-check over that specified row only
  -- otherwise, if no targetRow is specified, check all rows until one is available (or not)
  local success, cell
  if targetRow then
    success, cell = checkPredicate(rows, targetRow, predicate)
  else
    for row = 1, min(MAX_ROWS, rows.m + 1) do
      success, cell = checkPredicate(rows, row, predicate)
      if success then break end
    end
  end
  if not success then
    return false, targetRow and cell or "No eligible Action Row for the provided component"
  end

  return true, cell
end

---<!ignore>
---Constructs a new Component instance of the provided `comp` class with the arguments `data, ...`
---and then insert into the current instance cache.
---@param comp Component
---@param data any
---@param ... any
---@return Component
function Components:_buildComponent(comp, data, ...)
  -- Validate and factor the provided arguments
  data = comp._validate and comp._validate(data, ...) or data
  -- Can we fit a new component in the provided builder?
  local success, cell = self:_isEligible(data.actionRow, comp._eligibilityCheck)
  if not success then error(cell, 3) end
  -- Create and insert the component into the action row
  -- using isInstance as an optimization for passing an already constructed component
  local obj = isInstance(data, comp) and data or comp(data)
  self:_insert(cell, obj)
  return obj
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

---Removes all components attached to this instance and reset its cache.
---
---Returns self.
---@return Components self
function Components:removeAllComponents()
  buildCompCache(self)
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

---Returns a table value of what the raw value Discord would accept is like based on assumptions
---of the current components.
---
---By design, user should never need to use this method.
---@return table
function Components:raw()
  local data = {}
  local rows = self._rows
  if rows.n <= 0 then return {} end

  -- Read rows and assign each row to table data while respecting its index
  local row, cell
  for r = 1, MAX_ROWS do
    row = nil
    for c = 1, MAX_ROW_CELLS do
      cell = rows[cellIndex(r, c)]
      if cell then
        row = row or {}
        row[#row + 1] = cell:raw()
      end
    end
    if row then data[r] = row end
  end

  -- Convert each row table in table data to a valid Action Row table object
  for i = 1, MAX_ROWS do
    row = data[i]
    if not row then goto continue end
    data[i] = {
      type = componentType.actionRow,
      components = row
    }
    ::continue::
  end

  return data
end

function getter.buttons(self)
  return ArrayIterable(self._buttons)
end

function getter.selectMenus(self)
  return ArrayIterable(self._selectMenus)
end

return Components
