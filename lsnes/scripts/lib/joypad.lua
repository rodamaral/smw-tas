local M = {}

local input = _G.input

M.keys = {}

function M:getKeys() self.keys = input.joyget(1) end

return M
