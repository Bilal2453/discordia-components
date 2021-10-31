local discordia = require("discordia")
local enums = require("enums")
local class = discordia.class
local classes = class.classes
local ceil, max = math.ceil, math.max
local isInstance = class.isInstance
local componentType = enums.componentType

local Resolver = require("Resolver")
local objComponents = Resolver.objComponents

local ArrayIterable = classes.ArrayIterable
local SelectMenu = require("components/SelectMenu")
local Button = require("components/Button")

local Components, get = class("Components")

local MAX_ROW_CELLS = 5
local MAX_ROWS = 5
local MAX_COMPONENTS = MAX_ROW_CELLS * MAX_ROWS

local function cellIndex(row, column)
  return (row - 1) * MAX_ROW_CELLS + column
end

local function findLast(tbl)
  for i = MAX_COMPONENTS, 1, -1 do
    if tbl[i] ~= nil then return i end
  end
end

local function findComponent(tbl, id)
  for i = 1, #tbl do
    if tbl[i].id == id then return i end
  end
end

function Components:__init(data)
  if data then return self:_load(data) end
  self._buttons = {}
  self._selectMenus = {}
  self._cacheMap = {
    [SelectMenu] = self._selectMenus,
    [Button] = self._buttons,
  }

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
    m = 0, -- last used row
  }
end

function Components:_load(data)
  data = objComponents(data)
  if not data then return end
  self._buttons = data._buttons
  self._selectMenus = data._selectMenus
  self._rows = data._rows
end

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
      "Cannot have two components of same type and ID at the same time!"
    ):format(typ.__name, value.id), 4)
  end
  cache[#cache + 1] = value
end

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

local function checkAny(rows)
  for c = 1, MAX_COMPONENTS do
    if not rows[c] then
      return true, c
    end
  end
  return false, ("All Action Rows are full; Cannot have more than %d component per message")
    :format(MAX_COMPONENTS)
end

local function checkPredicate(rows, targetRow, predicate)
  local success, msg, cell = true, nil, nil
  for c = cellIndex(targetRow, 1), targetRow * MAX_ROW_CELLS do
    if rows[c] then
      success, msg = predicate(rows[c], c)
    elseif not cell then
      cell = c -- first empty cell
    end
    if not success then
      return false, msg or "Predicate was not satisfied"
    end
  end
  return true, cell
end

function Components:_isEligible(actionRow, predicate)
  actionRow = tonumber(actionRow)
  local targetRow = actionRow or 1
  local rows = self._rows
  local cell

  -- Do we even have an available action row to start with?
  if rows.n >= MAX_COMPONENTS then
    return false, ("All Action Rows are full; Cannot have more than %d component per message")
      :format(MAX_COMPONENTS)
  end

  -- Does the specified action row jump over an empty row? that's a gap between rows
  if targetRow and (targetRow - rows.m) > 1 then
    return false, "Cannot use an Action Row while the previous row is empty"
  end

  -- If no predicate is specified, use first empty cell
  if type(predicate) ~= "function" then
    return checkAny(rows)
  end

  -- If actionRow is presented, run the predicate-check over that specified row only
  -- otherwise, if no actionRow is specified, check all rows until one is available (or not)
  local success
  repeat
    success, cell = checkPredicate(rows, targetRow, predicate)
    targetRow = success and targetRow or targetRow + 1
  until success or actionRow or targetRow > MAX_ROWS or targetRow - rows.m > 1
  if not success then return false, cell end

  return true, cell
end

function Components:_buildComponent(comp, data, ...)
  data = comp._validate and comp._validate(data, ...) or data
  -- Can we fit a new component in the provided builder?
  local success, cell = self:_isEligible(data.actionRow, comp._eligibilityCheck)
  if not success then error(cell, 3) end
  -- Create and insert the component into the action row
  -- using isInstance as an optimization for passing an already constructed component
  local obj = isInstance(data, comp) and data or comp(data)
  return obj
end

function Components:button(data, ...)
  assert(data, "data argument is required")
  self:_buildComponent(Button, data, ...)
  return self
end

function Components:selectMenu(data, ...)
  assert(data, "data argument is required")
  self:_buildComponent(SelectMenu, data, ...)
  return self
end

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

function Components:removeAllComponents()
  self._buttons = {}
  self._selectMenus = {}
  self._cacheMap = {
    [SelectMenu] = self._selectMenus,
    [Button] = self._buttons,
  }
  return self
end

function Components:removeButton(id)
  return self:_remove(Button, id)
end

function Components:removeSelectMenu(id)
  return self:_remove(SelectMenu, id)
end

function get.buttons(self)
  return ArrayIterable(self._buttons)
end

function get.selectMenus(self)
  return ArrayIterable(self._selfMenus)
end

return Components
