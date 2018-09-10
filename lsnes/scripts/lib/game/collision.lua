local M = {}

local memory,
  tostringx = _G.memory, _G.tostringx

local luap = require 'luap'
local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'

local empty = luap.empty_array
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR

-- Private methods
local function check_collision()
  local id = memory.getregister('x')
  local RAM = memory.readregion('WRAM', 0, 8)
  local str =
    string.format(
    'id=%d, Obj 1 (%d, %d) is %dx%d, Obj 2 (%d, %d) is %dx%d',
    id,
    RAM[0],
    RAM[1],
    RAM[2],
    RAM[3],
    RAM[4],
    RAM[5],
    RAM[6],
    RAM[7]
  )

  return str
end

-- Public methods
function M:reset()
  local watch = self.watch
  if watch[1] then
    empty(watch)
  end
end

-- Check for collision
-- TODO: unregisterexec when this option is OFF
function M:display()
  local watch = self.watch
  if OPTIONS.debug_collision_routine and watch[1] then
    draw.Font = false
    local y = draw.Buffer_height

    for _, id in ipairs(watch) do
      draw.text(0, y, 'Collision ' .. tostringx(id), COLOUR.warning, COLOUR.warning_bg)
      y = y + 16
    end
  end
end

-- Check for collision
--OPTIONS.debug_collision_routine_untouch = true -- EDIT
function M:register()
  local watch = self.watch

  memory.registerexec(
    'BUS',
    smw.CHECK_FOR_CONTACT_ROUTINE,
    function()
      if memory.getregister('p') % 2 == 1 then
        watch[#watch + 1] = check_collision()
      end
    end
  )
end

local function init(t)
  t.watch = {}
  t:register()
  t:reset()
end

function M.new()
  local t = {}
  setmetatable(t, {__index = M})
  init(t)
  return t
end

return M
