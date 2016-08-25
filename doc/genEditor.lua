-- Running this code from Noteapd++ will transform 
-- PaneAPI.html into Lua comments parseable by LDoc

local SCFIND_DOTMATCHESNL = 0x10000000 -- boost regex specific

npp:DoOpen(npp:GetCurrentDirectory() .. "\\PaneAPI.html")

editor:BeginUndoAction()

-- Remove everything up to <!--++Autogenerated --> and replace it with the header
for m in editor:match([[\A.*<!--\+\+Autogenerated -->\r\n]], SCFIND_REGEXP | SCFIND_DOTMATCHESNL) do m:replace([[--- Scintilla wrapper.
-- This is a straight forward API to directly control Scintilla. This documentation is not intended to fully describe the Scintilla API, but only to give a brief description. The [official Scintilla documentation](http://www.scintilla.org/ScintillaDoc.html) should be consulted for more details. All constants from the official documentation are exposed as Lua globals variables.
--
-- This class cannot be instantiated, rather predefined globals are available to use.
-- 
-- * `editor` - the currently selected editor
-- * `editor1` - the first editor (usually on the left)
-- * `editor2` - the second editor (usually on the right)
-- * `console` - the console output used by LuaScript. Note that since this editor is "read-only" some functionality may not work as expected, e.g. manually adding or removing text.
-- 
-- **Note:** Although the entire Scintilla API is available, a few parts of it should not be used since it would either have unexpected results, or does not make sense to use from Lua. 
-- @classmod Editor

--- Helper Methods
-- @section helpermethods

--- Gets the text within a range
-- @function textrange
-- @tparam int startPos
-- @tparam int endPos
-- @treturn string

--- Finds the next match within the document.
-- See the [Scintilla Documentation](http://www.scintilla.org/ScintillaDoc.html#searchFlags) for the search flags.
-- @function findtext
-- @tparam string search string
-- @tparam[opt] int flags either 0 or a combination of SCFIND constants
-- @tparam[opt] int startPos start of the range to search
-- @tparam[opt] int endPos end of the range to search
-- @return the start and end of the first match, or nil if no match

--- Creates a generator to iterate matches.
-- See the [Scintilla Documentation](http://www.scintilla.org/ScintillaDoc.html#searchFlags) for the search flags.
-- @function match
-- @tparam string search string
-- @tparam[opt] int flags either 0 or a combination of SCFIND constants
-- @tparam[opt] int startPos start of the range to search
-- @treturn Match match object generator
-- @see Match
-- @usage for m in editor:match(text, flags) do ... end

--- Appends text to the end of the document.
-- @function append
-- @tparam string text

-- Inserts text at the specified position.
-- @function insert
-- @tparam int pos position to insert the text
-- @tparam string text text to insert

--- Removes the text in the range
-- @function remove
-- @tparam int startPos
-- @tparam int endPos

]]) end

-- Remove everything after <!----Autogenerated -->
for m in editor:match([[<!----Autogenerated -->.*\z]], SCFIND_REGEXP | SCFIND_DOTMATCHESNL) do m:replace("") end

-- Do a bit of cleanup when properties are "read-only"
for m in editor:match([[ read-only(?=<)]], SCFIND_REGEXP) do m:replace('<span class="comment"> -- read-only</span>') end

-- Replace any h2 headers and make them into doc sections
for m in editor:match([[[ \t]+<h2>(.*?)</h2>]], SCFIND_REGEXP) do
	local t = editor.Tag[1]
	m:replace("--- " .. t .. "\r\n-- @section " .. string.lower(string.gsub(t, "[ ,]", "")) .. "\r\n")
end

-- Do the hard work. Replace any API call with the appropriate documentation
for m in editor:match([[^[ \t]*<p>(.+?)<a.+?#(SCI_[\w_]+)'>(.+?)</a>(.*?)<span class="comment"> -- (.+?)</span></p>]], SCFIND_REGEXP) do
	local rettype = editor.Tag[1]
	local reference = editor.Tag[2]
	local name = editor.Tag[3]
	local parameters = editor.Tag[4]
	local description = editor.Tag[5]
	local t = "--- " .. description .. "\r\n"
	local ch = parameters and string.sub(parameters, 1, 1)

	-- It can either be a function, array, or field
	local mapping = {['(']='function', ['[']='array'}
	local match_type = mapping[ch] or 'field'

	if match_type == 'function' then
		t = t .. "-- @" .. match_type .. " " .. name .. "\r\n"

		-- parameters
		local params = string.sub(parameters, 2, string.len(parameters) - 1)
		for param in string.gmatch(params, "(%w+ %w+)") do
			if param:sub(1,6) == "keymod" then
				t = t .. "-- @tparam int keycode e.g. SCK_LEFT or string.byte(\"A\")\r\n"
				t = t .. "-- @tparam int modifiers e.g. SCMOD_CTRL | SCMOD_SHIFT\r\n"
			else
				t = t .. "-- @tparam " .. param .. "\r\n"
			end
		end

		-- return
		if rettype ~= "editor:" and rettype ~= "editor." then
			t = t .. "-- @treturn " .. string.sub(rettype, 1, string.find(rettype, ' ', 1, true) - 1) .. "\r\n"
		end
	elseif match_type == 'array' then
		t = t .. "-- @" .. match_type .. " " .. name .. "\r\n"

		-- parameters
		local params = string.sub(parameters, 2, string.len(parameters) - 1)
		for param in string.gmatch(params, "(%w+ %w+)") do
			t = t .. "-- @tparam " .. param .. "\r\n"
		end

		-- return
		if rettype ~= "editor:" and rettype ~= "editor." then
			t = t .. "-- @treturn " .. string.sub(rettype, 1, string.find(rettype, ' ', 1, true) - 1) .. "\r\n"
		end
	elseif match_type == 'field' then
		if rettype ~= "editor:" and rettype ~= "editor." then
			t = t .. "-- @tparam " .. string.sub(rettype, 1, string.find(rettype, ' ', 1, true) - 1) .. " " .. name .. "\r\n"
		end
	end
	t = t .. "-- @see " .. reference .. "\r\n"

	m:replace(t)
end

-- Escape underscores (which appear in const names) so that they don't mess up the markdown
for m in editor:match("_") do m:replace("\\_") end
for m in editor:match("@see SCI\\") do m:replace("@see SCI") end

editor:EndUndoAction()
npp:SaveCurrentFileAs(false, npp:GetCurrentDirectory() .. "\\Editor.lua")

-- Find the right spot
editor:GotoPos(editor:findtext("-- @section popupeditmenu"))
editor:LineUp()
editor:LineUp()
editor:NewLine()

-- Open the file and copy it all
npp:DoOpen(npp:GetCurrentDirectory() .. "\\KeyboardCommands.lua")
editor:SelectAll()
editor:Copy()
npp:MenuCommand(IDM_FILE_CLOSE)

-- Make sure we are back in the righ file
npp:SwitchToFile(npp:GetCurrentDirectory() .. "\\Editor.lua")
editor:Paste()
npp:SaveCurrentFile()