-- Module for detecting BizHawk features and specific emulator functions
local biz = {}

biz.is_bizhawk = (tastudio ~= nil)

biz.minimum_supported_version = "1.11.0"

biz.is_old_version = (gui.drawAxis == nil) -- 1.11.0

-- Detect BizHawk features based on the changelog
-- http://tasvideos.org/BizHawk/ReleaseHistory.html
biz.features = {
  backcolor_default_arg = (emu.setislagged == nil), -- < 1.11.5 (should 1.11.4, but there's no way)
  gui_text_backcolor = (gui.DrawFinish == nil), -- < 1.11.7
  support_extra_padding = (client.SetGameExtraPadding ~= nil) and (gui.DrawFinish ~= nil), -- 1.11.7
}

-- Check if the emulator version is supported
function biz.check_emulator()
  if not biz.is_bizhawk then
    if gui.text then
      gui.text(0, 0, "This script works with BizHawk emulator.")
      gui.text(0, 32, "Visit http://tasvideos.org/Bizhawk.html to download the latest version.")
    end

    error("This script works with BizHawk emulator.")

  elseif biz.is_old_version then
    gui.text(0, 0, "This script works with BizHawk " .. biz.minimum_supported_version .. " or superior.")
    gui.text(0, 16, "Your version seems to be older.")
    gui.text(0, 32, "Visit http://tasvideos.org/Bizhawk.html to download the latest version.")
    error("This script works with BizHawk 1.11.0 or superior.")

  end
end

return biz
