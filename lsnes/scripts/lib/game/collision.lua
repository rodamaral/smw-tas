local M = {}

local memory = _G.memory

local luap = require 'luap'
local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'

local empty = luap.empty_array
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR

-- Private methods
local function check_collision()
  local slot = memory.getregister('x')
  local target = memory.getregister('y')
  local RAM = memory.readregion('WRAM', 0, 8)
  local str =
    string.format(
    '#%x vs #%x, Obj 1 (%d, %d) is %dx%d, Obj 2 (%d, %d) is %dx%d',
    slot,
    target,
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

local function register(t)
  local watch = t.watch

  memory.registerexec(
    'BUS',
    smw.CHECK_FOR_CONTACT_ROUTINE,
    function()
      local flag = memory.getregister('p') % 2 == 1

      if flag or OPTIONS.display_collision_routine_fail then
        watch[#watch + 1] = {
          text = check_collision(),
          collision_flag = flag
        }
      end
    end
  )
end

local function init(t)
  t.watch = {}
  register(t)
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
    draw.Font = 'Uzebox8x12'
    local y = draw.Buffer_height
    local height = draw.font_height()

    draw.text(0, y, 'Collisions')
    y = y + height

    for _, id in ipairs(watch) do
      local text = id.text
      local flag = id.collision_flag
      local color = flag and COLOUR.warning or COLOUR.very_weak
      draw.text(0, y, text, color)
      y = y + height
    end
  end
end

function M.new()
  local t = {}
  setmetatable(t, {__index = M})
  init(t)
  return t
end

return M
