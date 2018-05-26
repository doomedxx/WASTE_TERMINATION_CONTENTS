--[[
	Name:       RipWad
	Purpose:    Extract images from a WAD file
	Licence:    GNU General Public License.
--]]


-- DS = package.path:match( "(%p)%?%." ) -- directory seperator
-- CWD = wx.wxGetCwd()

Wad = 
{
	
	--	static properties
	
	MapLumps = {"THINGS", "LINEDEFS", "SIDEDEFS", "VERTEXES", "SEGS", "SSECTORS", 
				"NODES", "SECTORS", "REJECT", "BLOCKMAP", "BEHAVIOR"}
	,
	MagicNumbers = 
	{
		png = string.char(0x89).."PNG",
		jpg = string.char(0xFF)..string.char(0xD8),
		tga = "",
		pcx = string.char(0x0A).."?"..string.char(0x01)..string.char(0x01)
	}
	
	
	--	static methods
	
	ReadLongInt = function (file)	-- read little endian 4-byte int from a file
		return 	string.byte(file:read(1)) + string.byte(file:read(1)) * 0x100 + 
				string.byte(file:read(1)) * 0x10000 + string.byte(file:read(1)) * 0x1000
	end
	,
	ReadString = function (file, bytes)	-- read null-padded fixed size string from a file
		local done = false
		local i = 0; local str = ""; local b
		
		while i < bytes do
			i = i + 1; b = file:read(1)
			if string.byte(b) == 0 then done = true end
			if not done  then str = str..b end
		end
		
		return  str
	end
	,
}

function Wad:New(path)

	local o = {}

	o.Path = path or ""
	o.Head = {Magic = "", Lumps = 0, DirOffset = 0}
	o.Dir = {}
	
	
	setmetatable(o, self)
	self.__index = self
	
	return o
end

function Wad:Init ()
	local file = assert(io.open(self.Path, "rb"))
	local offset; local size; local name; local kind; local dataFormat;
	local section = ""; local lastMarker = ""; local map = ""
	local i; local v
	
	-- read wad header
	file:seek("set", 0)
	self.Head.Magic = file:read(4)
	self.Head.Lumps = Wad.ReadLongInt(file)
	self.Head.DirOffset = Wad.ReadLongInt(file)
	
	print(self.Head.Magic)
	print(self.Head.Lumps)
	print(self.Head.DirOffset)
	
	-- read directory entries
	assert(file:seek("set", self.Head.DirOffset))
	while file:read(0) do 
		offset = Wad.ReadLongInt(file)
		size = Wad.ReadLongInt(file)
		name = Wad.ReadString(file, 8) -- file:read(8)
		kind = _ ; dataFormat = _ ; map = _
		
		-- try to guess type of lump
		
		-- identify markers and determine what section we are in
		if size == 0 then
			kind = "marker"; dataFormat = "none"; lastMarker = name
			if name == "S_START" then section = "sprite"
			elseif  name == "P_START" then section = "patch"
			elseif  name == "F_START" then section = "flat"
			elseif  name == "S_END" or name == "P_END" or  name == "F_END" then section = ""
			end
		elseif section ~= "" then  kind = section 
		-- identiy uniquely-named lumps
		elseif name == "PLAYPAL" then kind = "palette"; dataFormat = "raw"
		elseif name == "COLORMAP" then kind = "colormap"; dataFormat = "raw"
		elseif name == "ENDOOM" then kind = "textscreen"; dataFormat = "raw"
		elseif name == "PNAMES" then kind = "patchnames"; dataFormat = "raw"
		elseif name == "GENMIDI" then kind = "genmidi"; dataFormat = "raw"
		elseif name == "DMXGUSC" then kind = "dmxgusc"; dataFormat = "text"
		elseif string.find (name, "DEMO") == 1 then kind = "demo"; dataFormat = "raw"
		elseif string.find (name, "TEXTURE") == 1 then kind = "texture"; dataFormat = "raw"
		else -- check if it is map data
			local i; local v
			for i,v in ipairs(Lump.MapLumps) do 
				if name == v then 
					kind = "mapdata"; dataFormat = "raw"; map = lastMarker
					break; 
				end
			end
		end
		
		table.insert(self.Dir, Lump:New(self.Path, offset, size, name, kind, dataFormat, map))
		print(offset, size, name, kind, dataFormat, map)
	end
	
	-- 
	
	file:close()
end

function Wad:DumpImages (path)
	local i; local v
	local imgtype = ""
       for i,v in ipairs(self.Dir) do 
		
		--print(i,v) 
		--print(v.Name.."\t\t"..v.Size.."\t\t"..v.Offset)
		
       end
	
end

--w = Wad:New("/home/err/Documents/doomcrap/bum/snarboo-beggar.wad")
w = Wad:New("/usr/share/games/doom/doom2.wad")
--w = Wad:New("/usr/share/games/doom/doom.wad")
--w = Wad:New("/home/err/Desktop/DOOM2.WAD")
w:Init()
w:DumpImages ()
