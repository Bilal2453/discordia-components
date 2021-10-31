--[[
    This code is not injected into Discordia;
      It is identical to the one used in Discordia, only defined here for ease of access.
    Code below is copied from SinisterRectus/Discordia with minor modifications,
      All rights reserved for the original maintainer.
--]]

local fs = require("fs")
local ffi = require("ffi")
local pathjoin = require("pathjoin")
local discordia = require("discordia")

local class = discordia.class
local format = string.format
local concat = table.concat
local insert = table.insert
local remove = table.remove
local istype = ffi.istype
local classes = class.classes
local int64_t = ffi.typeof('int64_t')
local uint64_t = ffi.typeof('uint64_t')
local splitPath = pathjoin.splitPath
local isInstance = class.isInstance
local readFileSync = fs.readFileSync

local Resolver = {}
local TextChannel = {}

-- [[ containers/abstract/TextChannel.lua ]]

local function parseFile(obj, files)
	if type(obj) == 'string' then
		local data, err = readFileSync(obj)
		if not data then
			return nil, err
		end
		files = files or {}
		insert(files, {remove(splitPath(obj)), data})
	elseif type(obj) == 'table' and type(obj[1]) == 'string' and type(obj[2]) == 'string' then
		files = files or {}
		insert(files, obj)
	else
		return nil, 'Invalid file object: ' .. tostring(obj)
	end
	return files
end

local function parseMention(obj, mentions)
	if type(obj) == 'table' and obj.mentionString then
		mentions = mentions or {}
		insert(mentions, obj.mentionString)
	else
		return nil, 'Unmentionable object: ' .. tostring(obj)
	end
	return mentions
end

---@diagnostic disable: undefined-field
function TextChannel:send(content)

	local data, err

	if type(content) == 'table' then

		local tbl = content
		content = tbl.content

		if type(tbl.code) == 'string' then
			content = format('```%s\n%s\n```', tbl.code, content)
		elseif tbl.code == true then
			content = format('```\n%s\n```', content)
		end

		local mentions
		if tbl.mention then
			mentions, err = parseMention(tbl.mention)
			if err then
				return nil, err
			end
		end
		if type(tbl.mentions) == 'table' then
			for _, mention in ipairs(tbl.mentions) do
				mentions, err = parseMention(mention, mentions)
				if err then
					return nil, err
				end
			end
		end

		if mentions then
			insert(mentions, content)
			content = concat(mentions, ' ')
		end

		local files
		if tbl.file then
			files, err = parseFile(tbl.file)
			if err then
				return nil, err
			end
		end
		if type(tbl.files) == 'table' then
			for _, file in ipairs(tbl.files) do
				files, err = parseFile(file, files)
				if err then
					return nil, err
				end
			end
		end

		local refMessage, refMention
		if tbl.reference then
			refMessage = {message_id = Resolver.messageId(tbl.reference.message)}
			refMention = {
				parse = {'users', 'roles', 'everyone'},
				replied_user = not not tbl.reference.mention,
			}
		end

		data, err = self.client._api:createMessage(self._id, {
			tts = tbl.tts,
			nonce = tbl.nonce,
			embed = tbl.embed,
			content = content,
      components = tbl.components, -- [[ Patched Line of Code ]]
			allowed_mentions = refMention,
			message_reference = refMessage,
		}, files)

	else

		data, err = self.client._api:createMessage(self._id, {content = content})

	end

	if data then
		return self._messages:_insert(data)
	else
		return nil, err
	end

end

-- [[ client/Resolver.lua ]]

local function int(obj)
	local t = type(obj)
	if t == 'string' then
		if tonumber(obj) then
			return obj
		end
	elseif t == 'cdata' then
		if istype(int64_t, obj) or istype(uint64_t, obj) then
			return tostring(obj):match('%d*')
		end
	elseif t == 'number' then
		return format('%i', obj)
	elseif isInstance(obj, classes.Date) then
		return obj:toSnowflake()
	end
end

function Resolver.messageId(obj)
	if isInstance(obj, classes.Message) then
		return obj.id
	end
	return int(obj)
end

-- [[ End of Copied Code ]]

return {
  Resolver = Resolver,
  TextChannel = TextChannel,
}
