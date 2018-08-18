local mod = {}

local input = _G.input

mod.keys = {}

function mod:getKeys()
  self.keys = input.joyget(1)
end

return mod
