local M = {}

local memory = _G.memory

local luap = require 'luap'
local config = require 'config'
local draw = require 'draw'
local widget = require 'widget'
local smw = require 'game.smw'

local empty = luap.empty_array
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR

-- Private methods
local function check_collision()
    local slot = memory.getregister('x')
    local target = memory.getregister('y')
    local RAM = memory.readregion('WRAM', 0, 0xC)
    local str = string.format('#%x vs #%x, (%d, %d) is %dx%d vs (%d, %d) is %dx%d', slot,
                              target, 0x100 * RAM[8] + RAM[0], 0x100 * RAM[9] + RAM[1], RAM[2], RAM[3],
                              0x100 * RAM[0xA] + RAM[4], 0x100 * RAM[0xB] + RAM[5], RAM[6], RAM[7])

    return str
end

local function register(t)
    local watch = t.watch

    memory.registerexec('BUS', smw.CHECK_FOR_CONTACT_ROUTINE, function()
        local flag = memory.getregister('p') % 2 == 1

        if flag or OPTIONS.display_collision_routine_fail then
            watch[#watch + 1] = {text = check_collision(), collision_flag = flag}
        end
    end)
end

-- Public methods
function M:init()
    self.watch = {}
    register(self)
end

function M:reset()
    local watch = self.watch
    if watch[1] then empty(watch) end
end

-- Check for collision
-- TODO: unregisterexec when this option is OFF
function M:display()
    draw.Font = 'Uzebox8x12'
    local height = draw.font_height()
    local x = draw.AR_x * widget:get_property('collision', 'x')
    local y = draw.AR_y * widget:get_property('collision', 'y')
    local watch = self.watch
    local do_display = OPTIONS.debug_collision_routine

    draw.text(x, y, 'Collisions', do_display and COLOUR.text or COLOUR.very_weak)
    y = y + height
    if do_display and watch[1] then
        for _, id in ipairs(watch) do
            local text = id.text
            local flag = id.collision_flag
            local color = flag and COLOUR.warning or COLOUR.weak
            draw.text(x, y, text, color)
            y = y + height
        end
    end
end

function M.new()
    local t = {}
    setmetatable(t, {__index = M})
    t:init()
    widget:new('collision', 0, 224)
    widget:set_property('collision', 'display_flag', true)

    return t
end

return M
