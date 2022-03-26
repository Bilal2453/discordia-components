local Component = require("containers/abstract/Component")
local discordia = require("discordia")
local resolver = require("resolver")
local enums = require("enums")
local class = discordia.class
local buttonStyle = enums.buttonStyle
local componentType = enums.componentType

---@alias Button-Resolvable table

---Represents a Component of type Button. Buttons are interactive message components
---that when pressed Discord fires an interactionCreate event. The Button class
---contains methods to retrieve and set different attributes of a Button.
---
---For accepted `data` fields see Button-Resolvable.
---
---General rules you should follow:
---1. Link buttons must have `url`, and cannot have `id`. And vise versa.
---2. Link buttons do not fire `interactionCreate`; meaning you cannot listen to a link button to know when it is pressed.
---3. An Action Row can contain up to 5 buttons only, and a button can never be in the same row as a select menu.
---@class Button: Component
---@type fun(data: Button-Resolvable, actionRow?: number)
---<!tag:interface> <!method-tags:mem>
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
    data.style = buttonStyle.link
  elseif id and not data.style then
    data.style = buttonStyle.primary
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

local eligibilityError = "Cannot have a Button in an Action Row that also contains Select Menu component!"
function Button._eligibilityCheck(c)
  return c.type ~= componentType.selectMenu, eligibilityError
end

---<!ignore>
---Changes the Button instance properties according to provided data.
---@param data table
function Button:_load(data)
  -- TODO: Is there a shortcut to those repetitive checks?
  -- make it as generalized as possible.
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
  -- Load disabled
  if data.disabled then
    self:disable()
  elseif data.disabled == false then
    self:enable()
  end
end

---Sets the `style` attribute of the Button.
---See `buttonStyle` enumeration for acceptable `style` values.
---
---Returns self.
---@param style string|number
---@return Button self
function Button:style(style)
  style = resolver.buttonStyle(style)
  return self:_set("style", style or buttonStyle.primary)
end

---Sets the `label` field of the Button. Must be in the range 0 < `label` < 81.
---
---Returns self.
---@param label string
---@return Button self
function Button:label(label)
  label = tostring(label)
  assert(label and #label <= 80 and #label > 0, "label must be a string in the range 1-80 inclusive")
  return self:_set("label", label)
end

---Sets the `url` for a Link Button. If Button's style was not `link` it will be forcibly changed to that.
---Keep in mind, a Link Button cannot have an `id`.
---
---Returns self.
---@param url string
---@return Button self
function Button:url(url)
  url = tostring(url)
  if self._data.style ~= 5 then self:_set("style", 5) end
  return self:_set("url", url)
end

---@alias Emoji-ID-Resolvable string|userdata

---Sets an `emoji` field for the Button. `emoji` can be a string to indicate emoji name
---in which case `id` and `animated` parameters will be available for use.
---For Unicode emotes you only need to set `name` field to the desired Unicode.
---
---Returns self.
---@param emoji Emoji-Resolvable|string
---@param id? Emoji-ID-Resolvable
---@param animated? boolean
---@return Button self
function Button:emoji(emoji, id, animated)
  emoji = resolver.emoji(emoji, id, animated)
  return self:_set("emoji", emoji)
end

return Button
