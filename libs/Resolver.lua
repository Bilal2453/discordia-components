--[[
  This is not injected into Discordia, and only used by the modules in this tree.
--]]

local discordia = require("discordia")
local enums = require("enums")
local class = discordia.class
local classes = class.classes
local buttonStyle = enums.buttonStyle
local componentType = enums.componentType

local isInstance = class.isInstance

local Resolver = {}

function Resolver.buttonStyle(style)
  local t = type(style)
  if t == "string" then
    return buttonStyle[style]
  elseif t == "number" then
    return style
  end
end

function Resolver.buttonEmoji(emoji) -- Partial emoji object
  if type(emoji) == "table" and emoji.name then
    return {
      animated = emoji.animated,
      name = emoji.name,
      id = emoji.id
    }
  end
end

function Resolver.rawComponents(comp)
  if isInstance(comp, classes.Components) then
    return comp:raw()
  elseif isInstance(comp, classes.Component) then
    return { -- Auto-wrap the component in an Action Row
      {
        type = componentType.actionRow,
        components = {comp:raw()}
      }
    }
  elseif #comp > 0 then
    return comp -- Assume raw array of raw Action Rows
  end
end

function Resolver.objComponents(data)
  local bases = {nil, classes.Button, classes.SelectMenu}
  local nd, cell = classes.Components(), nil
  for c = 1, #data do
    cell = data[c]
    if type(cell) ~= "table" then return end -- definitely an invalid component
    cell.type = type(cell.type) == "number" and cell.type or componentType[cell.type]
    if bases[cell.type] then
      nd:_buildComponent(bases[cell.type], cell)
    end
  end
  return nd
end

return Resolver
