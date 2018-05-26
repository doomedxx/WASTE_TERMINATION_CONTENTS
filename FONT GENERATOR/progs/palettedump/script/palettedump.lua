--[[
	Title:		"Spidey's Palette Dump Tool"
	Name:		palettedump
	Purpose:		Dump palette to binary format.
	Licence:		GNU General Public License.
--]]


--[[---------------------------- globals	----------------------------]]

xmlResource = nil 	-- the XML resource handle
Frame = nil   		-- the main wxFrame
Picker = nil   		-- the file picker control
Preview = nil   		-- the child wxPanel in the wxFrame to draw on
CancelButton = nil
DumpButton = nil

bitmap = nil
savedFilePath = nil 	-- for save dialog
savedFileDir = "" 	-- for save dialog

--[[------------------------- functions	----------------------------]]

function SavePalette(path)
	if not bitmap or not bitmap:Ok() then return end

	local img = bitmap:ConvertToImage()
	local w = img:GetWidth()
	local h = img:GetHeight()
	local xres = w/16
	local yres = h/16
	local x = xres/2; local y = yres/2;
	local r; local g; local b
	
	os.remove(path)
	local out = assert(io.open(path, "wb"))

	while y < h do
		while x < w do
			r = string.char(img:GetRed(x, y))
			g = string.char(img:GetGreen(x, y))
			b = string.char(img:GetBlue(x, y))
			out:write(r);out:write(g);out:write(b)
			x = x + xres
		end
		y = y + yres
		x = xres/2
	end
	
	img:delete()
	assert(out:close())
	
end

LoadPreview = function (event)
	local img = wx.wxImage()
	local p = Picker:GetFilePath()
	
	if p == "" then return end
	
	img:LoadFile(p)
	if img and img:Ok() then
		if bitmap then bitmap:delete();  bitmap = nil end
		bitmap = wx.wxBitmap(img)
		Preview:SetVirtualSize(wx.wxSize(img:GetWidth(), img:GetHeight()))
		Preview:Scroll(0,0)
		DrawPreview()
		-- Frame:SendSizeEvent() -- probably not needed
    	Preview:Refresh() -- needed for msw
	end
	img:delete()
	if event then event:Skip() end	-- pass the event along
end

DrawPreview = function (event)
	-- draw the bitmap to the preview area
	if bitmap and bitmap:Ok() then
		local dc = wx.wxPaintDC(Preview)
		Preview:PrepareDC(dc)
		dc:Clear()
		dc:DrawBitmap(bitmap, 0, 0, true)
		dc:delete()
	end
	if event then event:Skip() end	-- pass the event along
end

--save event handler
function save(event)
	if not bitmap or not bitmap:Ok() then return end
	
	-- save options for dialog box
	local filters = "Adobe Palette (*.act)|*.act|"
				--.."Adobe Palette (*.act)|*.act|"
	local exts = {"act", "pcx", "lmp"}	-- for lookup use
	local filterIndex = 0
	local fileName = ""
	local filePath = ""
	if savedFilePath then
		filePath = savedFilePath
	end
	local fileDialog = wx.wxFileDialog(Frame, "Save Image", savedFileDir, filePath, filters,
							wx.wxSAVE + wx.wxOVERWRITE_PROMPT)
	fileDialog:SetDirectory(savedFileDir)
	if fileDialog:ShowModal() == wx.wxID_OK then	-- user clicked ok
		fileName = fileDialog:GetFilename()
		filePath = fileDialog:GetPath()
		filterIndex = fileDialog:GetFilterIndex()
		-- if user left off extension, add it
		if not string.find(fileName, '[\.]'..exts[filterIndex+1]..'$') then
			filePath = filePath.."."..exts[filterIndex+1] 
		end
		-- save the image
		savedFilePath = filePath	-- for save dialog
		savedFileDir = fileDialog:GetDirectory()
		SavePalette(savedFilePath)
	end

	fileDialog:Destroy()
end


-- main - entry point to this application
function main()

	-- declare main window
	Frame = wx.wxFrame()

	-- load xml resource
	xmlResource = wx.wxXmlResource()
	xmlResource:InitAllHandlers()
	local xrcFilename = "./res/palettedump.xrc"	-- wx.wxGetCwd()..

	if not xmlResource:Load(xrcFilename) then
		return	-- quit program
	end	
	
	if not xmlResource:LoadFrame(Frame, wx.NULL, "Frame") then
		return	-- quit program
	end

	-- set up some global widgets
	Picker = Frame:FindWindow("Picker"):DynamicCast("wxGenericDirCtrl")
	Preview = Frame:FindWindow("Preview"):DynamicCast("wxScrolledWindow")
	CancelButton = Frame:FindWindow("CancelButton"):DynamicCast("wxButton")
	DumpButton = Frame:FindWindow("DumpButton"):DynamicCast("wxButton")
	
	Preview:SetScrollbars(1, 1, 50, 50)
	
	-- handle dump button
	Frame:Connect(xmlResource.GetXRCID("DumpButton"), wx.wxEVT_COMMAND_BUTTON_CLICKED, save)

	-- handle cancel button
	Frame:Connect(xmlResource.GetXRCID("CancelButton"), wx.wxEVT_COMMAND_BUTTON_CLICKED,
			function (event)	
				Frame:Close(true)
			end )
			
	--close event
	Frame:Connect(wx.wxEVT_CLOSE_WINDOW,
			function (event)
				-- clean up global stuff
				if bitmap then bitmap:delete() end
				bitmap = nil
				event:Skip()	-- ensure the event is passed on so that it is handled
			end )
			
			
	Picker:Connect(wx.wxEVT_COMMAND_TREE_SEL_CHANGED, LoadPreview)
	Preview:Connect(wx.wxEVT_PAINT, DrawPreview)

	Frame:SetSize(wx.wxSize(400,300))
	Frame:SetMinSize(wx.wxSize(400,300))
	Frame:Show(true)	--show the main window

end


main()	-- call main ;)

