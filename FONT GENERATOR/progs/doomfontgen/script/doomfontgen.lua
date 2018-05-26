--[[
  Title:      "Spidey's ZDoom Font Generator"
  Name:        doomfontgen
  Purpose:    Generates bitmap fonts from system fonts.
  Licence:    GNU General Public License.
--]]


--[[---------------------------- includes (not used)  ----------------------------]]
-- add our lib directory to cpath
-- package.cpath = package.cpath..";./lib/?.DLL;./lib/?.so"
-- require "gd"  -- include lua-gd


--[[---------------------------- lua "imports" ----------------------------]]

dofile("../shared/crap.lua")
dofile("./script/imagehelper.lua")
dofile("./script/lumphelper.lua")
dofile("./script/manhelper.lua")

--[[---------------------------- globals  ----------------------------]]

appname = "Spidey's ZDoom Font Generator"
appversion = "0.2.7"

--portId = wx.wxPlatformInfo.Get():GetPortId()
--isGTK = portId == wx.wxPORT_GTK
--isWin = portId == wx.wxPORT_MSW

frame = nil       -- the main wxFrame
panel = nil    -- the panel that holds our xrc
canvas = nil       -- the child wxPanel in the wxFrame to draw on
charsText = nil     -- the multi-line textbox widget holding the characters to draw
xmlResource = nil   -- the XML resource handle
ZoomSlider = nil
BrightSlider = nil
SaveCharsButton = nil
LoadCharsButton = nil
--ColorPicker = nil

font = wx.wxNullFont  -- the selected font
fontdata = wx.wxFontData()  -- font data returned from font dialog
fontmode = 1    -- 1 for console font, 2 for big font
fontDialog = nil   -- wx.wxFontDialog(frame, fontdata)

forceGray = true  -- whether to force grayscale characters (to correct subpixel rendering)

savedFilePath = nil   -- for save dialog
savedFileDir = ""   -- for save dialog
savedFileType = 0   -- for save dialog

zoomLevel = 1    -- zoom amount (power of two)

needRedraw = true  -- redraw the image

-- character position and cell size adjustment values
sizeAdjustX = 0; sizeAdjustY = 0
posAdjustX = 0; posAdjustY = 0

-- size of screen for uncropped bitmap and screen buffer
screenWidth, screenHeight = wx.wxDisplaySize()
--bitmap  = wx.wxBitmap(screenWidth, screenHeight, 24)
--buffer = wx.wxBitmap(screenWidth, screenHeight, 24)
bitmap = ImageHelper.MakeBitmap(screenWidth, screenHeight)
buffer = ImageHelper.MakeBitmap(screenWidth, screenHeight)


--[[------------------------- functions  ----------------------------]]

-- touch file
function Touch(path)
  local r = os.rename(path,path)
  if r == nil then return false else return true end
end


-- redraw bitmap
function Redraw()
  needRedraw  = true
  canvas:Refresh(false)
  -- OnPaint()
  frame:SendSizeEvent()
end


-- draw new bitmap to memory.
function DrawBitmap(doFolderSave)
  local bmp = nil
  local memDC = wx.wxMemoryDC()  -- create off screen dc to draw on
  local h = 0; local w = 0
  local lastx = 0; local lasty = 0
  local size = nil
  local bitmapHeight = 0; local bitmapWidth = 0
  local charNum = 0; local c = ""
  
  if not sizeAdjustX then sizeAdjustX = 0 end
  if not sizeAdjustY then sizeAdjustY = 0 end
  if not posAdjustX then posAdjustX = 0 end
  if not posAdjustY then posAdjustY = 0 end

  
      
  --initialize big bitmap
  if bitmap then bitmap:delete(); bitmap = nil end
  bitmap = ImageHelper.MakeBitmap(screenWidth, screenHeight)
  
  --initialize memDC
  memDC:SelectObject(bitmap)  -- select our big global bitmap to draw into
  
  memDC:SetBackground(wx.wxTRANSPARENT_BRUSH)  -- used for Clear
  memDC:Clear()  -- set entire bitmap to background color
  
  memDC:SetFont(font)

  -- get width and height for console chars
  w, h = memDC:GetTextExtent("W")  -- get size of character
  w = w + sizeAdjustX+2
  h = h + sizeAdjustY+2
  
  local numLines = charsText:GetNumberOfLines()
  local charsCounted = 0  -- number of characters processed so far
  local maxChars = 512  -- maximum number of characters that can be processed
  local lineNum = 0; local lineLength = 0
  local w2 = 0; local startxpos = 0
  
  while lineNum < numLines and charsCounted <= maxChars do  -- loop through line
    lineLength = charsText:GetLineLength(lineNum)
    lineNum = lineNum + 1
    charNum = 0
    while charNum < lineLength and charsCounted <= maxChars do  -- loop through characters in line
      c = charsText:GetRange(charsCounted,charsCounted+1)
      charNum = charNum + 1; charsCounted = charsCounted + 1
      memDC:SelectObject(wx.wxBitmap())  -- set up our Drawing Context
      startxpos = posAdjustX+1  -- horizontal position of the charater within the cell

      if fontmode == 2 then  -- variable width characters for bigfont
        -- get size of character and set width and height for cell
        -- w, h = memDC:GetTextExtent(c)  
        w = memDC:GetTextExtent(c)  
        _, h = memDC:GetTextExtent("W")  -- get size of character
        w = w + sizeAdjustX+2; h = h + sizeAdjustY+2
      else          -- monospace characters for confont
        -- get size of character and "center" it in cell (really set startxpos for later)
        w2 = memDC:GetTextExtent(c)
        if w ~= w2 then startxpos = startxpos + math.floor( (w - w2) / 2 ) end  
      end
      
      -- local bmp = wx.wxBitmap(w, h, 24)   -- new bmp sized to our character
      
      local bmp = ImageHelper.MakeBitmap(w, h)
      
      
      memDC:SelectObject(bmp)  -- select our little bmp to draw into
      memDC:SetTextBackground(wx.wxBLACK)  -- should not show up
      memDC:SetBackgroundMode(wx.wxTRANSPARENT)
      
      local b = BrightSlider:GetValue()      
      memDC:SetTextForeground(wx.wxColour(b,b,b))
      --memDC:SetTextForeground(ColorPicker:GetColour())
        
      memDC:DrawText(c, startxpos, posAdjustY+1)  -- draw the character to the little bmp
      
      -- force characters to greyscale (to correct subpixel rendering)
      if forceGray == true then
        local img = bmp:ConvertToImage()
        img = img:ConvertToGreyscale()
        
        -- wx.wxQuantize.Quantize(img, img, 2)  -- quantize to (?) colors
        bmp:delete(); bmp = wx.wxBitmap(img)
        img:delete()
        memDC:SelectObject(bmp)
      end
      
      -- save small bitmap to file if we need to (for folder save)
      if doFolderSave == true and c ~= " " then
        local fn = "/STCFN"..string.format("%03d", string.byte(c))
        if savedFileType == 4 then
          ImageHelper.SaveBitmap(bmp,savedFilePath..fn..".png", 3)
        elseif savedFileType == 5 then
          ImageHelper.SaveBitmap(bmp,savedFilePath..fn..".pcx", 3)
        end 
      end

      -- draw a red rectangle around big font characters
      if fontmode == 2 then
        memDC:SetBrush(wx.wxTRANSPARENT_BRUSH)
        memDC:SetPen(wx.wxRED_PEN)
        memDC:DrawRectangle(0, 0, w, h)
      end

      memDC:SelectObject(wx.wxBitmap())  -- always release bitmap
      memDC:SelectObject(bitmap)      -- select our big global bitmap to draw into
      memDC:DrawBitmap(bmp, lastx, lasty, true)  -- draw little bmp into big bitmap
      bmp:delete(); bmp = nil        --clean up little bmp
      lastx = lastx + (w - 1)
      if lastx >  bitmapWidth then bitmapWidth = lastx end  -- expand canvas if needed)

    end  -- end of one line
    
    lastx = 0; lasty = lasty + (h - 1) 

    -- eat line break and carriage return characters
    c = charsText:GetRange(charsCounted,charsCounted+1)
    while string.byte(c) == 10 or string.byte(c) == 13 do
      charNum = charNum + 1; charsCounted = charsCounted + 1
      c = charsText:GetRange(charsCounted,charsCounted+1)
    end

  end  
  bitmapHeight = lasty  -- expand canvas

  if fontmode == 2 then  -- adjust width and height for bounding boxes
    bitmapWidth = bitmapWidth + 4; bitmapHeight = bitmapHeight + 4
  end

  -- draw our big bitmap into a cropped bitmap
   --bmp = wx.wxBitmap(bitmapWidth, bitmapHeight, 24)
  bmp = ImageHelper.MakeBitmap(bitmapWidth, bitmapHeight)
  
  memDC:SelectObject(bmp)
  --memDC:Clear(); 
  
  memDC:DrawBitmap(bitmap, 0, 0, true)   
  
  bitmap:delete(); bitmap = nil -- clean up our big bitmap

  -- draw cropped bitmap back into global bitmap
  --bitmap = wx.wxBitmap(bitmapWidth, bitmapHeight, 24)
  bitmap = ImageHelper.MakeBitmap(bitmapWidth, bitmapHeight)
  
  memDC:SelectObject(bitmap)
  --memDC:Clear()
  memDC:DrawBitmap(bmp, 0, 0, true)   
  
  bmp:delete(); bmp = nil -- clean up our littlebitmap

  memDC:SelectObject(wx.wxBitmap())  -- always release bitmap
  memDC:delete()  -- ALWAYS Delete() any wxDCs created when done

end


-- handler for paint event 
function OnPaint(event)
  local dc = wx.wxPaintDC(canvas)  -- ALWAYS create wxPaintDC in wxEVT_PAINT handler
  local buf = wx.wxMemoryDC()    -- create off screen dc to draw on

  -- need this so windows doesnt goof up and max out cpu
  if bitmap and needRedraw and not bitmap:Ok() then
    bitmap = ImageHelper.MakeBitmap(screenWidth, screenWidth)
    
    return  -- why did i put a return here?
  end

  -- set up our screen buffer
  if needRedraw and bitmap and bitmap:Ok() then
    DrawBitmap(bitmap)
    
    local zoomWidth = bitmap:GetWidth() * zoomLevel
    local zoomHeight = bitmap:GetHeight() * zoomLevel
    
    -- scale bitmap if needed
    local img = bitmap:ConvertToImage()
    if zoomLevel > 1 then
      img:Rescale(zoomWidth, zoomHeight)
    end
    local scaledBmp = wx.wxBitmap(img)
    
    -- delete temporary image
    img:delete()
    
    -- resize buffer to size of scaled bitmap
    buffer:delete()
    --buffer = wx.wxBitmap(zoomWidth, zoomHeight, 24)
    buffer = ImageHelper.MakeBitmap(zoomWidth, zoomHeight)
    
    -- draw scaled bitmap to buffer
    buf:SelectObject(buffer)
    --buf:SetBackground(wx.wxBrush("white",wx.wxBDIAGONAL_HATCH))  -- used for Clear
    --buf:Clear()  -- set entire bitmap to background color
    buf:DrawBitmap(scaledBmp, 0, 0, true)
    buf:SelectObject(wx.wxBitmap())
    -- canvas:SetAutoLayout(false)
    canvas:SetMinSize(wx.wxSize(zoomWidth, zoomHeight))
    scaledBmp:delete()
    needRedraw = false  -- reset since we at least tried to redraw it
  end

  -- draw our buffer to the canvas
  if buffer and buffer:Ok() then
    dc:SetBackground(wx.wxBrush("#bbb",wx.wxBDIAGONAL_HATCH))  -- used for Clear
    dc:Clear()  -- set entire bitmap to background color
    dc:DrawBitmap(buffer, 0, 0, true)
  end
  
  buf:delete()  -- ALWAYS Delete() any wxDCs created when done
  dc:delete()  -- ALWAYS Delete() any wxDCs created when done

  if event then event:Skip() end  -- pass the event along
end


-- UpdateChars function - updates the widget containing the font characters
function UpdateChars()  
  local chars = ""

  LoadChars()  -- try to load characters from a config file
  
  if charsText:GetLastPosition() == 0 then
    chars = GenerateChars()  -- generate characters as a last resort
  end
  
  -- put chars into textbox widget if chars has data
  if chars ~= "" then charsText:Clear(); charsText:AppendText(chars) end
  
  --wxTextCtrl appends a blank line on file load, check for it and remove it.
  if charsText:GetLineLength(charsText:GetNumberOfLines()-1) == 0 then
    local len = charsText:GetLastPosition()
    charsText:Remove(len-1,len)
  end
  
  charsText:ShowPosition(0)  -- scroll textbox widget to top
end


--LoadChars function - attempt to load characters from a text file.
function LoadChars()
  local filenames = {}
  local i = 0

  if fontmode == 1 then    -- console font
    filenames ={"./config/confont.charmap","./res/confont.charmap.latin1", "./res/confont.charmap.utf8"}
  else            -- big font
    filenames = {"./config/bigfont.charmap", "./res/bigfont.charmap.latin1", "./res/bigfont.charmap.utf8"}
  end
  
  -- try to load each charmap file until charsText has characters
  charsText:Clear()
  while i < #filenames and charsText:GetLastPosition() == 0 do
    i = i + 1; charsText:Clear(); charsText:LoadFile(filenames[i])
  end

end


-- GenerateChars function - generate characters programmatically
function GenerateChars()
  local i = 0
  local chars = ""

  if fontmode == 1 then    -- console font
    i = 0
    while i < 256 do
      if i % 16 == 0 and i > 0 then 
        chars=chars.."\n"
      end
      if i > 32 and i < 127 then
        chars=chars..string.char(i)
      else
        chars=chars.." "
      end
      i = i + 1
    end
  else            -- big font
    i = 32
    while i < 97 do
      if i % 8 == 0 and i > 32 then 
        chars=chars.."\n"
      end
      chars=chars..string.char(i)
      i = i + 1
    end
  end

  return chars
end

-- save event handler. Calls saveAs if not yet saved.
function save(event)

  if not savedFilePath then 
    saveAs()  -- do "save as" if not saved yet
    return
  end

  if string.sub(savedFilePath,-4) == ".lmp" then savedFileType = 3 end
  
  if savedFileType < 3 then      -- save image to one file
    ImageHelper.SaveBitmap(bitmap,savedFilePath,fontmode)
  elseif savedFileType == 3 then  -- save font lump
    ImageHelper.SaveBitmap(bitmap,savedFilePath..".pcx",fontmode)
    LumpHelper.MakeLump(fontmode, true, savedFilePath..".pcx", savedFilePath)
    os.remove(savedFilePath..".pcx")
  else              -- save folder of seperate image files
    wx.wxMkdir(savedFilePath); DrawBitmap(true)
  end
  
  if Touch(savedFilePath) then
    frame:SetStatusText("Saved "..savedFilePath)
  else
    frame:SetStatusText("Unable to save "..savedFilePath.."!")
  end  
end


--save as event handler
function saveAs(event)
  -- save options for dialog box
  local filters = "Determine file type from extension|*.*|"..
        "PNG, full color (*.png) - recommended for editing |*.png|"..
        "PCX, indexed (*.pcx) - recommended for imagetool|*.pcx|"..
        "Lump (*.lmp) - for direct import into wad|*.lmp|"..
        "Folder of PNG, full color (STCFN*.png)|*.*|"..
        "Folder of PCX, indexed (STCFN*.pcx)|*.*"
  local exts = {"*", "png", "pcx", "lmp"}  -- for lookup use
  local filterIndex = 0
  local fileName = ""
  local filePath = ""
  if savedFilePath then
    filePath = savedFilePath
  end
  local fileDialog = wx.wxFileDialog(frame, "Save Image", savedFileDir, filePath, filters,
              wx.wxSAVE + wx.wxOVERWRITE_PROMPT)
  fileDialog:SetDirectory(savedFileDir)
  if fileDialog:ShowModal() == wx.wxID_OK then  -- user clicked ok
    fileName = fileDialog:GetFilename()
    filePath = fileDialog:GetPath()
    filterIndex = fileDialog:GetFilterIndex()
    savedFileType = filterIndex
    -- if user left off extension, add it
    if filterIndex > 0 and filterIndex < 4
    and not string.find(fileName, '[\.]'..exts[filterIndex+1]..'$') then
      filePath = filePath.."."..exts[filterIndex+1] 
    end
    -- save the image
    savedFilePath = filePath  -- for save dialog
    savedFileDir = fileDialog:GetDirectory()
    save(event)
  end

  fileDialog:Destroy()
end


-- zoom slider event handler
function handleZoom(event)
  local ZoomText = panel:FindWindow("ZoomText"):DynamicCast("wxStaticText")
  local oz = zoomLevel
  zoomLevel = 2 ^ ZoomSlider:GetValue()
  if zoomLevel ~= oz then
    ZoomText:SetLabel(zoomLevel.."x")
    Redraw()   -- redraw the image
  end
end


-- main - entry point to this application
function main()

  -- declare main window
  frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, appname, wx.wxDefaultPosition, 
          wx.wxSize(600, 480), wx.wxDEFAULT_FRAME_STYLE, "doomfontgen")

  fontDialog = wx.wxFontDialog(frame, fontdata)  -- a font selection dialog box
  
  -- Create the menubar
  local fileMenu = wx.wxMenu()
  fileMenu:Append(wx.wxID_NEW, "Start &Over", "Destroy all changes and start from scratch")
  fileMenu:AppendSeparator()
  fileMenu:Append(wx.wxID_SAVE, "&Save image", "Save the current image")
  fileMenu:Append(wx.wxID_SAVEAS, "Save image &as...", "Save the current image to a new file")
  fileMenu:AppendSeparator()
  fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")

  local toolsMenu = wx.wxMenu()
  toolsMenu:Append(666, "Create &lump from image", "Convert an image file to a lump using ImageTool")
  toolsMenu:Append(667, "Create &image from lump", "Convert a lump to an image file using ImageTool")
  
  local helpMenu = wx.wxMenu()
  helpMenu:Append(wx.wxID_HELP, "View &Manual", "View the doomfontgen manual")
  helpMenu:Append(wx.wxID_ABOUT, "&About...", "About this program")

  local menuBar = wx.wxMenuBar()
  menuBar:Append(fileMenu, "&File")
  menuBar:Append(toolsMenu, "&Tools")
  menuBar:Append(helpMenu, "&Help")
  frame:SetMenuBar(menuBar)

  -- Create the statusbar
  local statusBar = frame:CreateStatusBar(2)
  --local status_width = statusBar:GetTextExtent("88888, 88888")
  frame:SetStatusWidths({ -1, 164 })
  frame:SetStatusText("Welcome to "..appname..".")
  --frame:SetStatusText("next slot", 1)

  -- Create a wxPanel and load our xrc into it
  panel = wx.wxPanel(frame, wx.wxID_ANY)

  xmlResource = wx.wxXmlResource()
  xmlResource:InitAllHandlers()
  local xrcFilename = "./res/doomfontgen.xrc"  -- wx.wxGetCwd()..

  if not xmlResource:Load(xrcFilename) then
    return  -- quit program
  end  
  
  local lumpDialog = xmlResource:LoadDialog(frame, "LumpDialog")
  local imageDialog = xmlResource:LoadDialog(frame, "ImageDialog")
  local manDialog = xmlResource:LoadDialog(frame, "ManDialog")
  
  if not xmlResource:LoadPanel(panel, wx.NULL, "MainPanel") then
    return  -- quit program
  end

  -- set up some global widgets
  canvas = panel:FindWindow("CanvasPanel")  -- :DynamicCast("wxPanel")
  local ScrollPanel = panel:FindWindow("ScrollPanel"):DynamicCast("wxScrolledWindow")
  local ControlPanel = panel:FindWindow("ControlPanel"):DynamicCast("wxPanel")
  charsText = panel:FindWindow("CharsText"):DynamicCast("wxTextCtrl")
  ZoomSlider = panel:FindWindow("ZoomSlider"):DynamicCast("wxSlider")
  BrightSlider = panel:FindWindow("BrightSlider"):DynamicCast("wxSlider")
  SaveCharsButton = panel:FindWindow("SaveCharsButton"):DynamicCast("wxButton")
  LoadCharsButton = panel:FindWindow("LoadCharsButton"):DynamicCast("wxButton")
  --ColorPicker = panel:FindWindow("ColorPicker"):DynamicCast("wxColourPickerCtrl")

  
  ScrollPanel:SetScrollbars(1, 1, 50, 50)

  UpdateChars()  

  -- handle paint events (draw our bitmap)
  canvas:Connect(wx.wxEVT_PAINT, OnPaint)
  
  local ModeChoice = panel:FindWindow("ModeChoice"):DynamicCast("wxChoice")
  -- enable mode choice widget
  frame:Connect(xmlResource.GetXRCID("ModeChoice"), wx.wxEVT_COMMAND_CHOICE_SELECTED,
      function (event)
        fontmode = event:GetSelection() + 1
        UpdateChars()
        Redraw()
      end )

  -- show font dialog and change selected font when font button is clicked
  frame:Connect(xmlResource.GetXRCID("FontButton"), wx.wxEVT_COMMAND_BUTTON_CLICKED,
      function (event)  
        if fontDialog:ShowModal() == wx.wxID_OK then
          fontdata = fontDialog:GetFontData()
          font = fontdata:GetChosenFont()
          panel:FindWindow("FontButton"):SetFont(font)
          panel:FindWindow("FontButton"):SetLabel(font:GetFaceName())
          Redraw()
        end
      end )
      
  -- frame:Connect(xmlResource.GetXRCID("ColorPicker"), wx.wxEVT_COMMAND_COLOURPICKER_CHANGED, function (event) Redraw() end )
  
  -- handle size and position adjustment
  local PosXText = panel:FindWindow("PosXText"):DynamicCast("wxTextCtrl")
  local PosYText = panel:FindWindow("PosYText"):DynamicCast("wxTextCtrl")
  local CellWText = panel:FindWindow("CellWText"):DynamicCast("wxTextCtrl")
  local CellHText = panel:FindWindow("CellHText"):DynamicCast("wxTextCtrl")

  local PosXSpin = panel:FindWindow("PosXSpin"):DynamicCast("wxSpinButton")
  local PosYSpin = panel:FindWindow("PosYSpin"):DynamicCast("wxSpinButton")
  local CellWSpin = panel:FindWindow("CellWSpin"):DynamicCast("wxSpinButton")
  local CellHSpin = panel:FindWindow("CellHSpin"):DynamicCast("wxSpinButton")

  PosXSpin:SetRange(-20,20); PosYSpin:SetRange(-20,20);
  CellWSpin:SetRange(-20,20); CellHSpin:SetRange(-20,20);
  
  frame:Connect(xmlResource.GetXRCID("PosXText"),wx.wxEVT_COMMAND_TEXT_UPDATED,
      function (event)
        local t = PosXText
        posAdjustX = tonumber(t:GetValue())
        if posAdjustX then
          PosXSpin:SetValue(posAdjustX)
        end
        Redraw()   -- redraw the image
      end )
  frame:Connect(xmlResource.GetXRCID("PosYText"), wx.wxEVT_COMMAND_TEXT_UPDATED,
      function (event)
        local t = PosYText
        posAdjustY = tonumber(t:GetValue())
        if posAdjustY then
          PosYSpin:SetValue(posAdjustY)
        end
        Redraw()   -- redraw the image
      end )
  frame:Connect(xmlResource.GetXRCID("CellWText"), wx.wxEVT_COMMAND_TEXT_UPDATED,
      function (event)
        local t = CellWText
        sizeAdjustX = tonumber(t:GetValue())
        if sizeAdjustX then
          CellWSpin:SetValue(sizeAdjustX)
        end
        Redraw()   -- redraw the image
      end )
  frame:Connect(xmlResource.GetXRCID("CellHText"), wx.wxEVT_COMMAND_TEXT_UPDATED,
      function (event)
        local t = CellHText
        sizeAdjustY = tonumber(t:GetValue())
        if sizeAdjustY then
          CellHSpin:SetValue(sizeAdjustY)
        end
        Redraw()   -- redraw the image
      end )

  frame:Connect(xmlResource.GetXRCID("PosXSpin"), wx.wxEVT_SCROLL_THUMBTRACK, 
      function (event)
        local v = PosXSpin:GetValue()
        PosXText:SetValue(tostring(v))
        posAdjustX = tonumber(v)
        Redraw()
      end )
  frame:Connect(xmlResource.GetXRCID("PosYSpin"), wx.wxEVT_SCROLL_THUMBTRACK, 
      function (event)
        local v = PosYSpin:GetValue()
        PosYText:SetValue(tostring(v))
        posAdjustY = tonumber(v)
        Redraw()
      end )
  frame:Connect(xmlResource.GetXRCID("CellWSpin"), wx.wxEVT_SCROLL_THUMBTRACK, 
      function (event)
        local v = CellWSpin:GetValue()
        CellWText:SetValue(tostring(v))
        sizeAdjustX = tonumber(v)
        Redraw()
      end )
  frame:Connect(xmlResource.GetXRCID("CellHSpin"), wx.wxEVT_SCROLL_THUMBTRACK, 
      function (event)
        local v = CellHSpin:GetValue()
        CellHText:SetValue(tostring(v))
        sizeAdjustY = tonumber(v)
        Redraw()
      end )

  -- handle chars text
  frame:Connect(xmlResource.GetXRCID("CharsText"), wx.wxEVT_COMMAND_TEXT_UPDATED,
      function (event)
        Redraw()   -- redraw the image
      end )
      
  -- handle zoom slider
  frame:Connect(xmlResource.GetXRCID("ZoomSlider"), wx.wxEVT_SCROLL_THUMBTRACK, handleZoom)
  frame:Connect(xmlResource.GetXRCID("ZoomSlider"), wx.wxEVT_SCROLL_CHANGED, handleZoom)  

  -- handle brightness slider
  frame:Connect(xmlResource.GetXRCID("BrightSlider"), wx.wxEVT_SCROLL_THUMBTRACK, Redraw)
  frame:Connect(xmlResource.GetXRCID("BrightSlider"), wx.wxEVT_SCROLL_CHANGED, Redraw)  
  
  -- handle load chars button
  frame:Connect(xmlResource.GetXRCID("LoadCharsButton"), wx.wxEVT_COMMAND_BUTTON_CLICKED,
      function (event)
        local fileDialog = wx.wxFileDialog(frame, "Load characters from file",
                    savedFileDir, "", "All files|*.*", wx.wxOPEN)
        fileDialog:SetDirectory(savedFileDir)
        if fileDialog:ShowModal() == wx.wxID_OK then  -- user clicked ok
          charsText:LoadFile(fileDialog:GetPath())
        end
      end )
      
  -- handle save chars button
  frame:Connect(xmlResource.GetXRCID("SaveCharsButton"), wx.wxEVT_COMMAND_BUTTON_CLICKED,
      function (event)
        local fileDialog = wx.wxFileDialog(frame, "Save characters to file",
                    savedFileDir, "", "All files|*.*",
                    wx.wxSAVE + wx.wxOVERWRITE_PROMPT)
        fileDialog:SetDirectory(savedFileDir)
        if fileDialog:ShowModal() == wx.wxID_OK then  -- user clicked ok
          charsText:SaveFile(fileDialog:GetPath())
        end
      end )

  -- Connect menu events

  -- Start over 
  frame:Connect(wx.wxID_NEW, wx.wxEVT_COMMAND_MENU_SELECTED,
      function (event)     
        -- reset font mode
        ModeChoice:Select(0)
        fontmode = 1  -- 1 for console font, 2 for big font
        UpdateChars()
        --reset font
        font = wx.wxNullFont  -- the selected font
        fontdata = wx.wxFontData()  -- font data returned from font dialog
        fontDialog:Destroy()
        fontDialog = wx.wxFontDialog(frame, fontdata)
        panel:FindWindow("FontButton"):SetFont(wx.wxNullFont)
        panel:FindWindow("FontButton"):SetLabel("Choose Font...")
        --reset bitmap
        screenWidth, screenHeight = wx.wxDisplaySize()
        bitmap:delete(); bitmap = nil
        --bitmap  = wx.wxBitmap(screenWidth, screenHeight, 24)
        bitmap = ImageHelper.MakeBitmap(screenWidth, screenHeight, true)
        --reset adjustment values
        PosXText:SetValue("0"); PosYText:SetValue("0")
        CellWText:SetValue("0"); CellHText:SetValue("0")
        PosXSpin:SetValue(0); PosYSpin:SetValue(0)
        CellWSpin:SetValue(0); CellHSpin:SetValue(0)
        sizeAdjustX = 0; sizeAdjustY = 0
        posAdjustX = 0; posAdjustY = 0
        ZoomSlider:SetValue(0); handleZoom()
        -- panel:Refresh()
        Redraw()
      end )

  --save menu commands
  frame:Connect(wx.wxID_SAVE, wx.wxEVT_COMMAND_MENU_SELECTED, save)
  frame:Connect(wx.wxID_SAVEAS, wx.wxEVT_COMMAND_MENU_SELECTED, saveAs)

  -- "create lump" dialog
  frame:Connect(666, wx.wxEVT_COMMAND_MENU_SELECTED, 
      function (event) LumpHelper.Show(lumpDialog) end )
      
  -- "create image" dialog
  frame:Connect(667, wx.wxEVT_COMMAND_MENU_SELECTED, 
      function (event) ImageHelper.Show(imageDialog) end )
  
  -- readme dialog
  frame:Connect(wx.wxID_HELP, wx.wxEVT_COMMAND_MENU_SELECTED,
      function (event) ManHelper.Show(manDialog) end )
      
  -- about dialog
  frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
      function (event)
        local m = appname..' '..appversion..' \n'..
            'Distributed under the GNU GPL. \n\n'..
            'Spidey thanks the following people: \n\n'..
            'Randy & Graf'..'\t\t\t'..'(g)zdoom \n'..
            'Janis'..'\t\t\t\t'..'vavoom \n'..
            'Nash'..'\t\t\t\t'..'beta testing \n'..
            'Wildweasel'..'\t\t\t'..'beta testing \n'

            -- .."\nUsing "..wxlua.wxLUA_VERSION_STRING.." ("..wx.wxVERSION_STRING..")."
        wx.wxMessageBox(m, "About...", wx.wxOK + wx.wxICON_INFORMATION, frame )
      end )

  -- exit command
  frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
      function (event)
        frame:Close(true)
      end )

  --close event
  frame:Connect(wx.wxEVT_CLOSE_WINDOW,
      function (event)
        -- clean up global stuff
        if bitmap then bitmap:delete() end
        bitmap = nil
        if buffer then buffer:delete() end
        buffer = nil
        fontDialog:Destroy()
        if LumpHelper.SourceDialog then
          LumpHelper.SourceDialog:Destroy()
          LumpHelper.OutputDialog:Destroy()
        end
        event:Skip()  -- ensure the event is passed on so that it is handled
      end )

  ControlPanel:SetMinSize(wx.wxSize(160,-1))
  frame:SetMinSize(wx.wxSize(420,420))
  frame:Show(true)  --show the main window

end


main()  -- call main ;)

