--[[
  Title:      "Spidey's ZDoom Font Generator"
  Name:        ManHelper
  Purpose:    Manages manual (readme) dialog
  Licence:    GNU General Public License.
--]]


ManHelper = {

  -- properties

  
  Dialog = nil, CloseButton = nil, ManHtml = nil,
  BackButton = nil, ForwardButton = nil, HomeButton = nil, TopButton = nil,
  
  Homepage = nil,
  
  -- methods
  
  Init = function (dialog)
    -- get handle to widgets
    ManHelper.Dialog = dialog
    ManHelper.CloseButton = dialog:FindWindow("CloseButton"):DynamicCast("wxButton")
    ManHelper.ManHtml = dialog:FindWindow("ManHtml"):DynamicCast("wxHtmlWindow")
    ManHelper.BackButton = dialog:FindWindow("BackButton"):DynamicCast("wxButton")
    ManHelper.ForwardButton = dialog:FindWindow("ForwardButton"):DynamicCast("wxButton")
    ManHelper.HomeButton = dialog:FindWindow("HomeButton"):DynamicCast("wxButton")
    ManHelper.TopButton = dialog:FindWindow("TopButton"):DynamicCast("wxButton")
    
    -- connect widgets to event handlers
    ManHelper.CloseButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, ManHelper.Hide)
    ManHelper.Dialog:Connect(wx.wxEVT_CLOSE_WINDOW, ManHelper.Hide)
    
    ManHelper.BackButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, 
      function (event)
        ManHelper.ManHtml:HistoryBack()
        event:Skip()
      end)
    ManHelper.ForwardButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, 
      function (event)
        ManHelper.ManHtml:HistoryForward()
        event:Skip()
      end)
    ManHelper.HomeButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, 
      function (event)
        ManHelper.ManHtml:LoadPage(ManHelper.Homepage)
        event:Skip()
      end)
    ManHelper.TopButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, 
      function (event)
        ManHelper.ManHtml:Scroll(0,0)
        event:Skip()
      end)
      
    -- other crap
    ManHelper.Homepage = "./doc/manual/index.html"
  end
  ,
  Show = function (dialog)
    if not ManHelper.Dialog then ManHelper.Init(dialog) end
    ManHelper.ManHtml:LoadPage(ManHelper.Homepage)
    ManHelper.Dialog:ShowModal() 
  end
  ,
  Hide = function (event)
    ManHelper.Dialog:EndModal(0) 
    if event then event:Skip() end  -- pass the event along
  end
}
