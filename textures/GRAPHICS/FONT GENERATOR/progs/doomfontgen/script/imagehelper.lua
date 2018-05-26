--[[
  Title:    "Spidey's ZDoom Font Generator"
  Name:    ImageHelper
  Purpose:    Static class full of ugly hacks.
  Licence:    GNU General Public License.
--]]


ImageHelper = {

  Dialog = nil, 
  FontChoice = nil, ConvertChoice = nil, SourceButton = nil, OutputButton = nil, 
  ImagePreview = nil, CloseButton = nil, CreateButton = nil, ConsoleText = nil,
  SourceDialog = nil, OutputDialog = nil, Bitmap = nil,
  
  MakeBitmap = (
    function (h,w,transparent)
      
      local img = wx.wxImage(h,w,true)
      local bmp
      
      if transparent then
      
        img:SetMaskColour(0, 0, 0)
        if img:HasAlpha() == false then img:InitAlpha() end
        img:SetMask(false)
      
      end
      
      bmp = wx.wxBitmap(img)
      img:delete()
      
      return bmp
      --return wx.wxBitmap(h,w,24)
    end
  )
  ,
  SaveBitmap = (
    function (bmp,path,fixNum)
      local img = bmp:ConvertToImage()
      ImageHelper.SaveImage(img,path,fixNum)
      img:delete()
    end
  )
  ,
  SaveImage = (
    function (img,path,fixNum)
      local doFixes = false
      
      --[[
      -- set a mask
      img:SetMaskColour(0, 0, 0)
      if img:HasAlpha() == false then img:InitAlpha() end
      img:SetMask(false)
      --]]
      
      -- "fix" pcx 
      if string.sub(path,-4) == ".pcx" then
        doFixes = true
      end
      
      if doFixes then ImageHelper.PreProcess(img,fixNum) end
      img:SaveFile(path)  -- save the final image
      if doFixes then ImageHelper.PostProcess(path,fixNum) end
      -- img:delete()  -- release handle to file
    end
  )
  ,
  PreProcess = (
    function (img,fixNum)
      
      -- add gray palette at top of image
      if fixNum == 1 then 
        ImageHelper.AddGrayPalette(img)
      -- add color palette at top of image
      elseif fixNum == 2 then 
        ImageHelper.AddColorPalette(img)
        wx.wxQuantize.Quantize(img, img, 256,
        wx.wxQUANTIZE_INCLUDE_WINDOWS_COLOURS)  -- quantize to 256 colors
      elseif fixNum == 3 then 
        img:Replace(0,0,0,  0,255,255)
        wx.wxQuantize.Quantize(img, img, 256,
        wx.wxQUANTIZE_INCLUDE_WINDOWS_COLOURS)
      end
      
    end
  )
  ,
  PostProcess = (
    function (path,fixNum)
      
      -- make palette grayscale, gradiating from dark to light (and chop)
      if fixNum == 1 then 
        os.execute('convert -normalize '
        ..'-type Truecolor -type Grayscale -type Palette -chop 0x8  "'
        ..path..'" "'..path..'"')
      -- chop color palette from top of image
      elseif fixNum == 2 then 
        os.execute('convert -chop 0x8 "'..path..'" "'..path..'"')
        
      elseif fixNum == 3 then  -- use palette entry 247 for background color?
         -- os.execute('convert -type Truecolor -type Palette "'..path..'" "'..path..'"') 
      end
      
    end
  )
  ,
  AddColorPalette = (
    function(img)
      local ix = 0; local iy = 1
      local ir = 0; local ig = 0; local ib = 0 
      
      local w = img:GetWidth()
      if w < 128 then w = 128 end
      img:Resize(wx.wxSize(w,img:GetHeight()+8), wx.wxPoint(0,8))
      img:SetRGB(1, 0, 0xFF, 0, 0)
      
      local f = 0;
      -- draw grayscale gradient
      while iy < 2 do
        while ix < 64 do
          img:SetRGB(ix, iy, f*2, f*2, f*2)
          ix = ix + 1
          f = f + 1
        end
        ix = 0; iy = iy + 1
      end
      --[[
      -- draw color gradients, red last
      while iy < 8 do
        if iy == 2 then    ir = 0; ig=1; ib = 1
        elseif iy == 3 then  ir = 1; ig=0; ib = 1
        elseif iy == 4 then  ir = 1; ig=1; ib = 0
        elseif iy == 5 then  ir = 0; ig=0; ib = 1
        elseif iy == 6 then  ir = 0; ig=1; ib = 0
        elseif iy == 7 then  ir = 1; ig=0; ib = 0
        end
        while ix < 128 do
          img:SetRGB(ix, iy, ir*ix*2, ig*ix*2, ib*ix*2)
          ix = ix + 1
        end
        ix = 0; iy = iy + 1
      end
        ]]--
    end
  )
  ,
  AddGrayPalette = (
    function(img)
      local ix = 0; local iy = 0
      
      img:Resize(wx.wxSize(img:GetWidth(), img:GetHeight()+8), wx.wxPoint(0,8))
      
      -- draw grayscale gradient
      while iy < 8 do
        while ix < 32 do
          local f = iy * 32 + ix;
          img:SetRGB(ix, iy, f, f, f)
          ix = ix + 1
        end
        ix = 0; iy = iy + 1
      end
        
    end
  )
  ,  
  
  
  -- stuff for the "lump to image" dialog
  
  Init = function (dialog)
    -- get handle to widgets
    ImageHelper.Dialog = dialog
    ImageHelper.SourceButton =dialog:FindWindow("SourceButton"):DynamicCast("wxButton")
    ImageHelper.OutputButton = dialog:FindWindow("OutputButton"):DynamicCast("wxButton")
    ImageHelper.ImagePreview = dialog:FindWindow("ImagePreview"):DynamicCast("wxScrolledWindow")
    ImageHelper.CloseButton = dialog:FindWindow("CloseButton"):DynamicCast("wxButton")
    ImageHelper.CreateButton = dialog:FindWindow("CreateButton"):DynamicCast("wxButton")
    --ImageHelper.ConsoleText = dialog:FindWindow("ConsoleText"):DynamicCast("wxTextCtrl")
    
    -- connect widgets to event handlers
    ImageHelper.SourceButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, ImageHelper.HandleSourceButton)
    ImageHelper.OutputButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, ImageHelper.HandleOutputButton)
    ImageHelper.ImagePreview:Connect(wx.wxEVT_PAINT, ImageHelper.DrawPreview)
    ImageHelper.CloseButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, ImageHelper.Hide)
    ImageHelper.CreateButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, ImageHelper.HandleCreateButton)
    ImageHelper.Dialog:Connect(wx.wxEVT_CLOSE_WINDOW, ImageHelper.Hide)
    
    -- other crap
    ImageHelper.SourceDialog = wx.wxFileDialog(dialog, "Select source lump", 
              savedFileDir, "", "Lump files (lmp)|*.lmp|All files|*.*",
              wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    ImageHelper.OutputDialog = wx.wxFileDialog(dialog, "Select output image", 
              savedFileDir, "", "Image files|*.png;*.pcx;*.bmp;*.ilbm;*.tga;*.gif;*.xpm;*.jpg;*.jpeg|All files|*.*",
              wx.wxSAVE + wx.wxOVERWRITE_PROMPT)
    ImageHelper.ImagePreview:SetScrollbars(1, 1, 50, 50)
    
  end
  ,
  Show = function (dialog)
    if not ImageHelper.Dialog then ImageHelper.Init(dialog) end
    ImageHelper.Dialog:ShowModal() 
    ImageHelper.LoadPreview()
  end
  ,
  Hide = function (event)
    if ImageHelper.Bitmap then 
      ImageHelper.Bitmap:delete();  ImageHelper.Bitmap = nil 
    end
    ImageHelper.Dialog:EndModal(0) 
    if event then event:Skip() end  -- pass the event along
  end
  ,
  HandleSourceButton = function (event)
    if ImageHelper.SourceDialog:ShowModal() == wx.wxID_OK then  -- user clicked ok
      ImageHelper.LoadPreview()
    end
    if event then event:Skip() end  -- pass the event along
  end
  ,
  HandleOutputButton = function (event)
    if ImageHelper.OutputDialog:ShowModal() == wx.wxID_OK then  -- user clicked ok
      ImageHelper.OutputButton:SetLabel(ImageHelper.OutputDialog:GetFilename())
    end
    if event then event:Skip() end  -- pass the event along
  end
  ,
  LoadPreview = function (event)
    local img = wx.wxImage()
    local p = ImageHelper.SourceDialog:GetPath()
    if p == "" then return end
    if ImageHelper.Bitmap then ImageHelper.Bitmap:delete();  ImageHelper.Bitmap = nil end
    
    local tmp = os.tmpname()
    local isError; local retmsg
    isError, retmsg = Crap.Run('imgtool bmp '..p..' '..tmp..'.bmp')
    if isError == 0 then
      img:LoadFile(tmp..'.bmp')
      os.remove(tmp..'.bmp')
      ImageHelper.Bitmap = wx.wxBitmap(img)
      ImageHelper.ImagePreview:SetVirtualSize(wx.wxSize(img:GetWidth(), img:GetHeight()))
      img:delete()
      ImageHelper.SourceButton:SetLabel(ImageHelper.SourceDialog:GetFilename())
    else
      ImageHelper.SourceButton:SetLabel("(Not a patch)")
    end
    if event then event:Skip() end  -- pass the event along
  end
  ,
  DrawPreview = function (event)
    -- draw the bitmap to the preview area
    local dc = wx.wxPaintDC(ImageHelper.ImagePreview)
    ImageHelper.ImagePreview:PrepareDC(dc)
    if ImageHelper.Bitmap and ImageHelper.Bitmap:Ok() then
      dc:DrawBitmap(ImageHelper.Bitmap, 0, 0, true)
    end
    dc:delete()
    if event then event:Skip() end  -- pass the event along
  end
  ,
  HandleCreateButton = function(event)
    local inpath = ImageHelper.SourceDialog:GetPath()
    local outpath = ImageHelper.OutputDialog:GetPath()
    local retcode = nil

    if inpath == "" or outpath == "" then return end
    
    local tmp = os.tmpname()
    --retcode = os.execute('imgtool bmp '..inpath..' '..tmp..'.bmp')
    retcode, retmsg = Crap.Run('imgtool bmp '..inpath..' '..tmp..'.bmp')
    
    if retcode == 0 then --close dialog on success
      retcode, retmsg = Crap.Run('convert '..tmp..'.bmp '..outpath)
      if retcode == 0 then
        ImageHelper.Hide() 
      else
          wx.wxMessageBox(retmsg, "Cannot create "..ImageHelper.OutputDialog:GetFilename(), wx.wxOK + wx.wxICON_INFORMATION, frame )
      end  
    else
        wx.wxMessageBox(retmsg, "Cannot create "..ImageHelper.OutputDialog:GetFilename(), wx.wxOK + wx.wxICON_INFORMATION, frame )
    end  
    
    os.remove(tmp..'.bmp')
    
    if event then event:Skip() end  -- pass the event along
  end
  ,
}
