--[[
	Name:       lump
	Purpose:    class file
	Licence:    GNU General Public License.
--]]


Lump = 
{
	
	--	static properties
	
	MapLumps = {"THINGS", "LINEDEFS", "SIDEDEFS", "VERTEXES", "SEGS", "SSECTORS", 
				"NODES", "SECTORS", "REJECT", "BLOCKMAP", "BEHAVIOR"}
	,
	Magic = 
	{
		png = string.char(0x89).."PNG",
		jpg = string.char(0xFF)..string.char(0xD8),
		pcx = string.char(0x0A).."."..string.char(0x01)..string.char(0x01),
		-- tga = "", --targa doesn't use a magic identifier
		
		nativesound = string.char(0x03)..string.char(0x00)
	}
	
}

function Lump:New(path, offset, size, name, kind, dataFormat, map)

	local o = {}

	o.Path = path
	o.Offset = offset
	o.Size = size
	o.Name= name
	o.Kind = kind
	o.DataFormat = dataFormat
	o.Map = map
	
	setmetatable(o, self)
	self.__index = self
	
	return o
end

function Lump:Init()

	-- if self.Kind = "" then self:GuessKind() end
	if self.DataFormat = "" then self:GuessFormat() end
	
end

-- try to guess type of lump
function Lump:GuessFormat ()
	local header; 
	local kind = self.Kind
	local file = assert(io.open(self.Path, "rb"))
	
	-- read first 8 bytes of file
	assert(file:seek("set", self.Offset))
	header = file:read(8) 
	file:close()
	
	if string.find (header, Lump.Magic.png) == 1 then kind = kind or "image"; dataFormat = "png"
	elseif string.find (header, Lump.Magic.jpg) == 1 then kind = kind or "image"; dataFormat = "jpg"
	elseif string.find (header, Lump.Magic.pcx) == 1 then kind = kind or "image"; dataFormat = "pcx"
	
	if kind ~= "" then return true end
	

end

function Lump:IsPicture()

	if self.Size < 13 then return false;	-- minimum length of a valid Doom patch

	local file = assert(io.open(self.Path, "rb"))
	
	-- read first 8 bytes of file
	assert(file:seek("set", self.Offset))
	header = file:read(self.Size) 
	file:close()
	
	const patch_t * foo = (const patch_t *)data;
	
	int height = LittleShort(foo->height);
	int width = LittleShort(foo->width);
	
	if (height > 0 && height < 2048 && width > 0 && width <= 2048 && width < file.GetLength()/4)
	{
		// The dimensions seem like they might be valid for a patch, so
		// check the column directory for extra security. At least one
		// column must begin exactly at the end of the column directory,
		// and none of them must point past the end of the patch.
		bool gapAtStart = true;
		int x;
	
		for (x = 0; x < width; ++x)
		{
			DWORD ofs = LittleLong(foo->columnofs[x]);
			if (ofs == (DWORD)width * 4 + 8)
			{
				gapAtStart = false;
			}
			else if (ofs >= (DWORD)(file.GetLength()))	// Need one byte for an empty column (but there's patches that don't know that!)
			{
				delete [] data;
				return false;
			}
		}
		delete [] data;
		return !gapAtStart;
	}
	delete [] data;
	return false;
}

bool FPatchTexture::Check(FileReader & file)
{
	if (file.GetLength() < 13) return false;	// minimum length of a valid Doom patch
	
	BYTE *data = new BYTE[file.GetLength()];
	file.Seek(0, SEEK_SET);
	file.Read(data, file.GetLength());
	
	const patch_t * foo = (const patch_t *)data;
	
	int height = LittleShort(foo->height);
	int width = LittleShort(foo->width);
	
	if (height > 0 && height < 2048 && width > 0 && width <= 2048 && width < file.GetLength()/4)
	{
		// The dimensions seem like they might be valid for a patch, so
		// check the column directory for extra security. At least one
		// column must begin exactly at the end of the column directory,
		// and none of them must point past the end of the patch.
		bool gapAtStart = true;
		int x;
	
		for (x = 0; x < width; ++x)
		{
			DWORD ofs = LittleLong(foo->columnofs[x]);
			if (ofs == (DWORD)width * 4 + 8)
			{
				gapAtStart = false;
			}
			else if (ofs >= (DWORD)(file.GetLength()))	// Need one byte for an empty column (but there's patches that don't know that!)
			{
				delete [] data;
				return false;
			}
		}
		delete [] data;
		return !gapAtStart;
	}
	delete [] data;
	return false;
}
