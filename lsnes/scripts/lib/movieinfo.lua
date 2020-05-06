local M = {}

local gui = _G.gui

local config = require('config')
local draw = require('draw')
local lsnes = require('lsnes')
-- local Timer = require('timer')

local fmt = string.format
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LSNES_FONT_HEIGHT = config.LSNES_FONT_HEIGHT
local LSNES_FONT_WIDTH = config.LSNES_FONT_WIDTH

-- Private
local is_lagged = nil

-- Public
function M.get_lagged() return is_lagged end

function M.set_lagged(value) is_lagged = value end

function M.display()
    if not OPTIONS.display_movie_info then return end

    -- Font
    draw.Font = false
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0

    local y_text = -draw.Border_top
    local x_text = 0
    local width = draw.font_width()

    local rec_color = lsnes.Readonly and COLOUR.text or COLOUR.warning
    local recording_bg = lsnes.Readonly and COLOUR.background or COLOUR.warning_bg

    -- Read-only or read-write?
    local movie_type = lsnes.Readonly and 'Movie ' or 'REC '
    draw.alert_text(x_text, y_text, movie_type, rec_color, recording_bg)

    -- Frame count
    x_text = x_text + width * #(movie_type)
    local movie_info
    if lsnes.Readonly then
        movie_info = string.format('%d/%d', lsnes.Lastframe_emulated, lsnes.Framecount)
    else
        movie_info = string.format('%d', lsnes.Lastframe_emulated) -- delete string.format
    end
    draw.text(x_text, y_text, movie_info) -- Shows the latest frame emulated, not the frame being run now

    -- Rerecord count
    x_text = x_text + width * #(movie_info)
    local rr_info = string.format('|%d ', lsnes.Rerecords)
    draw.text(x_text, y_text, rr_info, COLOUR.weak)

    -- Lag count
    x_text = x_text + width * #(rr_info)
    draw.text(x_text, y_text, lsnes.Lagcount, COLOUR.warning)
    x_text = x_text + width * string.len(lsnes.Lagcount)

    -- lsnes run mode
    if lsnes.is_special_runmode then
        local runmode = ' ' .. lsnes.runmode
        draw.text(x_text, y_text, runmode, lsnes.runmode_color)
        x_text = x_text + width * (#runmode)
    end

    -- emulator speed
    if lsnes.Lsnes_speed == 'turbo' then
        draw.text(x_text, y_text, ' (' .. lsnes.Lsnes_speed .. ')', COLOUR.weak)
    elseif lsnes.Lsnes_speed ~= 1 then
        draw.text(x_text, y_text, fmt(' (%.0f%%)', 100 * lsnes.Lsnes_speed), COLOUR.weak)
    end

    local str = lsnes.frame_time(lsnes.Lastframe_emulated) -- Shows the latest frame emulated, not the frame being run now
    draw.alert_text(draw.Buffer_width, draw.Buffer_height, str, COLOUR.text, recording_bg, false,
                    1.0, 1.0)

    if is_lagged then
        gui.textHV(draw.Buffer_middle_x - 3 * LSNES_FONT_WIDTH, 2 * LSNES_FONT_HEIGHT, 'Lag',
                   COLOUR.warning,
                   draw.change_transparency(COLOUR.warning_bg, draw.Background_max_opacity))

        -- Timer.registerfunction(1000000, function()
        --     if not is_lagged then
        --         gui.textHV(draw.Buffer_middle_x - 3 * LSNES_FONT_WIDTH, 2 * LSNES_FONT_HEIGHT,
        --                    'Lag', COLOUR.warning,
        --                    draw.change_transparency(COLOUR.background, draw.Background_max_opacity))
        --     end
        -- end, 'Was lagged')
    end
end

return M
