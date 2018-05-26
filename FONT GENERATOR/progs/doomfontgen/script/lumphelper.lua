--[[
  Title:      "Spidey's ZDoom Font Generator"
  Name:        LumpHelper
  Purpose:    Static class for managing font lump creation dialog.
  Licence:    GNU General Public License.
--]]


LumpHelper = {

  -- properties

  Dialog = nil, 
  ImagePreview = nil,  Bitmap = nil,
  FontChoice = nil, ConvertChoice = nil,
  SourceButton = nil, OutputButton = nil, 
  CloseButton = nil, CreateButton = nil,
  SourceDialog = nil, OutputDialog = nil,
  
  -- methods
  
  Init = function (dialog)
    -- get handle to widgets
    LumpHelper.Dialog = dialog
    LumpHelper.FontChoice = dialog:FindWindow("FontChoice"):DynamicCast("wxChoice")
    LumpHelper.ConvertChoice = dialog:FindWindow("ConvertChoice"):DynamicCast("wxChoice")
    LumpHelper.SourceButton =dialog:FindWindow("SourceButton"):DynamicCast("wxButton")
    LumpHelper.OutputButton = dialog:FindWindow("OutputButton"):DynamicCast("wxButton")
    LumpHelper.ImagePreview = dialog:FindWindow("ImagePreview"):DynamicCast("wxScrolledWindow")
    LumpHelper.CloseButton = dialog:FindWindow("CloseButton"):DynamicCast("wxButton")
    LumpHelper.CreateButton = dialog:FindWindow("CreateButton"):DynamicCast("wxButton")
    --LumpHelper.ConsoleText = dialog:FindWindow("ConsoleText"):DynamicCast("wxTextCtrl")
    
    -- connect widgets to event handlers
    LumpHelper.SourceButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, LumpHelper.HandleSourceButton)
    LumpHelper.OutputButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, LumpHelper.HandleOutputButton)
    LumpHelper.ImagePreview:Connect(wx.wxEVT_PAINT, LumpHelper.DrawPreview)
    LumpHelper.CloseButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, LumpHelper.Hide)
    LumpHelper.CreateButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, LumpHelper.HandleCreateButton)
    LumpHelper.Dialog:Connect(wx.wxEVT_CLOSE_WINDOW, LumpHelper.Hide)
    
    -- other crap
    LumpHelper.SourceDialog = wx.wxFileDialog(dialog, "Select source image", 
              savedFileDir, "", "Image files (png, bmp, pcx, ilbm)|*.png;*.pcx;*.bmp;*.ilbm|All files|*.*",
              wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    LumpHelper.OutputDialog = wx.wxFileDialog(dialog, "Select output file", 
              savedFileDir, "", "Lump file (lmp)|*.lmp",
              wx.wxSAVE + wx.wxOVERWRITE_PROMPT)
    LumpHelper.ImagePreview:SetScrollbars(1, 1, 50, 50)
    
  end
  ,
  Show = function (dialog)
    if not LumpHelper.Dialog then LumpHelper.Init(dialog) end
    LumpHelper.Dialog:ShowModal() 
    LumpHelper.LoadPreview()
  end
  ,
  Hide = function (event)
    if LumpHelper.Bitmap then 
      LumpHelper.Bitmap:delete();  LumpHelper.Bitmap = nil 
    end
    LumpHelper.Dialog:EndModal(0) 
    if event then event:Skip() end  -- pass the event along
  end
  ,
  HandleSourceButton = function (event)
    if LumpHelper.SourceDialog:ShowModal() == wx.wxID_OK then  -- user clicked ok
      LumpHelper.LoadPreview()
      LumpHelper.SourceButton:SetLabel(LumpHelper.SourceDialog:GetFilename())
    end
    if event then event:Skip() end  -- pass the event along
  end
  ,
  HandleOutputButton = function (event)
    if LumpHelper.OutputDialog:ShowModal() == wx.wxID_OK then  -- user clicked ok
      LumpHelper.OutputButton:SetLabel(LumpHelper.OutputDialog:GetFilename())
    end
    if event then event:Skip() end  -- pass the event along
  end
  ,
  LoadPreview = function (event)
    local img = wx.wxImage()
    local p = LumpHelper.SourceDialog:GetPath()
    if p == "" then return end
    if LumpHelper.Bitmap then LumpHelper.Bitmap:delete();  LumpHelper.Bitmap = nil end
    img:LoadFile(p)
    LumpHelper.Bitmap = wx.wxBitmap(img)
    LumpHelper.ImagePreview:SetVirtualSize(wx.wxSize(img:GetWidth(), img:GetHeight()))
    img:delete()
    if event then event:Skip() end  -- pass the event along
  end
  ,
  DrawPreview = function (event)
    -- draw the bitmap to the preview area
    local dc = wx.wxPaintDC(LumpHelper.ImagePreview)
    LumpHelper.ImagePreview:PrepareDC(dc)
    if LumpHelper.Bitmap and LumpHelper.Bitmap:Ok() then
      dc:DrawBitmap(LumpHelper.Bitmap, 0, 0, true)
    end
    dc:delete()
    if event then event:Skip() end  -- pass the event along
  end
  ,
  HandleCreateButton = function(event)
    local mode = LumpHelper.FontChoice:GetCurrentSelection()+1
    local convert = LumpHelper.ConvertChoice:GetCurrentSelection() == 0
    local inpath = LumpHelper.SourceDialog:GetPath()
    local outpath = LumpHelper.OutputDialog:GetPath()
    local retcode = nil; local retmsg = nil

    if inpath == "" or outpath == "" then return end
    
    retcode, retmsg = LumpHelper.MakeLump(mode, convert, inpath, outpath)
    
    if retcode == 0 then --close dialog on success
      LumpHelper.Hide() 
    else
        -- wx.wxMessageBox(retmsg, "Cannot save "..LumpHelper.OutputDialog:GetFilename(), wx.wxOK + wx.wxICON_INFORMATION, frame )
    end  
    
    if event then event:Skip() end  -- pass the event along
  end
  ,
  MakeLump = function(mode, convert, inpath, outpath)
    local ft = ""; local tmp = nil; local retcode = 0; 
    local f = nil; retmsg = nil

    if     mode == 1 then ft = "confont" 
    elseif mode == 2 then ft = "font" 
    elseif mode == 3 then ft = "image" 
    elseif mode == 4 then ft = "xhair"
    end
    
    if inpath == "" or outpath == "" then return end
    
    if convert  then
      local img = wx.wxImage(inpath)
      tmp = os.tmpname()..".pcx"
      ImageHelper.SaveImage(img,tmp,mode)
      inpath = tmp
      if img and img:Ok() then img:delete() end
    end
    
    return  Crap.Run('imgtool '..ft..' '..inpath..' '..outpath)
  end
  ,
}
