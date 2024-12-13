local discordia = require("discordia")
local enums = require("enums")
local class = discordia.class
local classes = class.classes

local isInstance = class.isInstance
local componentType = enums.componentType
local ArrayIterable = classes.ArrayIterable

local utils = require("utils")
local errorf = utils.errorf
local remove = table.remove

---A container class constructed by the library to store components data
---for action row validation and caching purposes.
---@class ComponentsContainer
local ComponentsContainer = class("ComponentsContainer")

---<!ignore>
---Return the component index that matches the provided id in table `tbl`.
---@param tbl table
---@param id string
---@return number?
local function findComponent(tbl, id)
  for i = 1, #tbl do
    if tbl[i].id == id then return i end
  end
end

---<!ignore>
---Converts an UpperCase string into camelCase by just lowering first letter.
---@param str string
---@return string
local function toCamelCase(str)
  return str:sub(1, 1):lower() .. str:sub(2)
end

function ComponentsContainer:__init(data)
  assert(data, "argument data is required when initializing ComponentsContainer")
  self._maxRows = assert(data.maxRows, "expected field data.maxRows")
  self._maxRowCells = assert(data.maxRowCells, "expected field data.maxRowCells")
  self._maxComponents = data.maxComponents or data.maxRows * data.maxRowCells
  self._components = data.components

  -- build cache and getters
  self:_buildCache()
end

---<!ignore>
---Builds a new cache and getters for the current instance.
function ComponentsContainer:_buildCache()
  -- build rows cache
  self._rows = {
    rows_count = 0, -- how many row is currently provided?
    comps_count = 0, -- how many total component is there?
  }
  -- build components cache and getters
  self._cacheMap = {}
  for _, comp in pairs(self._components) do
    local index = comp.__name
    local cache = {}
    self._cacheMap[index] = cache
    cache.Iterable = ArrayIterable(cache)
    self.__getters[toCamelCase(index) .. 's'] = function()
      return cache.Iterable
    end
  end
end

---<!ignore>
---Inserts a component into the action row `row`.
---@param row number
---@param comp Component
function ComponentsContainer:_insert(row, comp)
  -- make sure the given row is within limits
  if row > self._maxRows then
    errorf("Cannot have more than %s action row, got %s rows", 3, self._maxRows, row)
  end

  -- create the row if doesn't already exists
  -- a table holding row is only created when needed, to save some memory
  local rows = self._rows
  if not rows[row] then
    -- make sure the row before this one is allocated
    if row ~= 1 and not rows[row - 1] then
      errorf("Cannot have row %s when the row before it (%s) is empty", 3, row, row - 1)
    end
    rows[row] = {}
    rows.rows_count = rows.rows_count + 1
  end

  -- make sure we have available slot in the row
  row = rows[row]
  if #row > self._maxRowCells then
    errorf("An action row cannot have more than %s component", 3, self._maxRowCells)
  end

  -- make sure we don't have a registered component with that ID already
  local comp_name = comp.__name
  local cache = self._cacheMap[comp_name]
  if findComponent(cache, comp.id) and not comp.url then
    errorf("Cannot have two components of the same type and ID, already have '%s' %s registered", 3, comp.id, comp_name)
  end

  -- add the new component
  row[#row+1] = comp
  rows.comps_count = rows.comps_count + 1
  -- insert the component into the cache
  cache[#cache + 1] = comp

  return self
end

---<!ignore>
---Remove a component from this container and action row.
---@param comp_class Component # The class of the component you are removing
---@param id string # The ID of the component to be removed
---@return ComponentsContainer self
---@return Component # The removed component.
function ComponentsContainer:_remove(comp_class, id)
  -- make sure we have such class cache registered
  local cache = self._cacheMap[comp_class.__name]
  if not cache then
    errorf("Unknown type %s to _remove", 3, comp_class)
  end
  -- make sure we have such component registered
  local index = findComponent(cache, id)
  if not index then
    errorf("No such %s with the ID '%s'", 3, comp_class.__name, id)
  end

  -- remove the component from its cache
  remove(cache, index)

  -- remove the component from its action row
  local rows = self._rows
  local removed_comp
  for i = 1, rows.rows_count do
    index = findComponent(rows[i], id)
    if index then
      removed_comp = remove(rows[i], index)
      break
    end
  end
  rows.comps_count = rows.comps_count - 1

  -- remove any empty row and shift rows back if necessarily
  for i = 1, rows.rows_count do
    if rows[i] and #rows[i] == 0 then
      remove(rows, i)
      rows.rows_count = rows.rows_count - 1
    end
  end

  return self, removed_comp
end

---<!ignore>
---Locates an eligible row for the provided component.
---@param comp Component
---@param target number|nil
---@return number|boolean # the row where the component should go into, or false
---@return string|nil # if first return is false, an error message explaining what went wrong
function ComponentsContainer:_locateRow(comp, target)
  local cb = comp._isEligible
  -- if the user has specified a targeted row, check that
  if target then
    if self._rows[target] then
      return cb(self._rows[target])
    else
      return target
    end
  end
  -- otherwise, check for first eligible row
  for i = 1, self._maxRows do
    local row = self._rows[i]
    if not row or #row < self._maxRowCells and cb(row) then
      return i
    end
  end
  -- we found no eligible row
  return false, "No available action row: cannot have more than " .. self._maxRows .. " row per message"
end

---<!ignore>
---Constructs a new Component instance of the provided `comp` class with the arguments `data, ...`
---and then insert into the current instance cache.
---@param comp Component
---@param data any
---@param ... any
---@return Component
function ComponentsContainer:_buildComponent(comp, data, ...)
  -- make sure argument comp exists
  if not comp then
    errorf('bad argument #1 to _buildComponent (expected Component, got %s)', 4, comp)
  end

  -- make sure this component have been registered
  if not self._cacheMap[comp.__name] then
    errorf('Component %s is not valid in this context', 4, comp.__name)
  end

  -- validate and refactor the provided data
  data = comp._validate and comp._validate(data, ...) or data

  -- can we have the component in an action row?
  local row, err = self:_locateRow(comp, data.actionRow)
  if not row then error(err, 4) end
  ---@cast row -true

  -- create and insert the component into the action row
  -- using isInstance as an optimization for passing an already constructed component
  local obj = isInstance(data, comp) and data or comp(data)
  self:_insert(row, obj)

  return obj
end

---Removes all components attached to this instance and reset its cache.
---
---Returns self.
---@return Components self
function ComponentsContainer:removeAllComponents()
  self:_buildCache()
  return self
end

---Returns a table of the raw components data the Discord API expects.
---User should never need to use this method.
---You are likely doing something wrong if you are using it directly.
---@return table
function ComponentsContainer:raw()
  local rows, data = self._rows, {}

  -- if we have nothing to do, return empty result
  if rows.rows_count <= 0 then
    return data
  end

  -- iterate all rows to:
  for i = 1, rows.rows_count do
    data[i] = {}
    -- convert each component in the row into its raw representation
    for n = 1, #rows[i] do
      data[i][n] = rows[i][n]:raw()
    end
    -- convert the row into a valid raw action row
    data[i] = {
      type = componentType.actionRow,
      components = data[i],
    }
  end

  return data
end

return ComponentsContainer
