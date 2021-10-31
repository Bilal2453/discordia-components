local Component = require("containers/abstract/Component")
local discordia = require("discordia")
local Resolver = require("Resolver")
local enums = require("enums")
local class = discordia.class
local componentType = enums.componentType

local Button = class("Button", Component)

function Button:__init(data, actionRow)
  -- Validate input into appropriate structure
  data = self._validate(data, actionRow) or {}

  -- At least one of the two fields must be always supplied
  local id, url = data.id, data.url
  if (id and url) or (not id and not url) then
    error("either one of id/url fields must be supplied") -- TODO: Either use assert everywhere or error everywhere
  end

  -- Auto defaulting button style when needed, otherwise resolving it
  if url and not data.style then
    data.style = 5
  elseif id and not data.style then
    data.style = 1
  end

  -- Base constructor initializing
  Component.__init(self, data, componentType.button)

  -- Properly load rest of data
  self:_load(data)
end

function Button._validate(data, actionRow)
  if type(data) ~= "table" then
    data = {id = data}
  end
  if actionRow then
    data.actionRow = actionRow
  end
  return data
end

function Button._eligibilityCheck(c)
  local err = "Cannot have a Button in an Action Row that also contains Select Menu component!"
  return c.type ~= componentType.selectMenu, err
end

function Button:_load(data)
  -- Load style
  if data.style then
    self:style(data.style)
  end
  -- Load label
  if data.label then
    self:label(data.label)
  end
  -- Load emoji
  if data.emoji then
    self:emoji(data.emoji)
  end
  -- Load url
  if data.url then
    self:url(data.url)
  end
end

function Button:disable()
  return self:set("disabled", true)
end

function Button:enable()
  return self:set("disabled", false)
end

function Button:style(style)
  style = Resolver.buttonStyle(style)
  return self:set("style", style or 1)
end

function Button:label(label)
  label = tostring(label)
  assert(label and #label <= 80 and #label > 0, "label must be 1-80 characters long in length")
  return self:set("label", label)
end

function Button:url(url)
  url = tostring(url)
  if self._data.style ~= 5 then self:set("style", 5) end
  return self:set("url", url)
end

function Button:emoji(emoji, name, animated)
  if type(emoji) ~= "table" then
    emoji = {
      id = emoji,
      name = name,
      animated = animated,
    }
  end
  emoji = assert(Resolver.buttonEmoji(emoji), "emoji object must contain the fields name, id and animated at the very least")
  return self:set("emoji", {
    animated = emoji.animated,
    name = emoji.name,
    id = emoji.id,
  })
end

return Button
