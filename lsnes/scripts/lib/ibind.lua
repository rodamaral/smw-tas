local M = {}

local commands = require('commands')

local function bind(cmd, name)
  name = name or cmd

  if not commands[cmd] then
    print('Warning: command ' .. cmd .. ' is not from smw-tas.')
  end

  M[cmd] = create_ibind('smw-tas-' .. name, cmd)
end

bind('toggle_decimal_hex_display')

return M
