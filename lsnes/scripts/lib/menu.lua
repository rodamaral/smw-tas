local M = {show_menu = false, current_tab = 'Show/hide options'}

local gui, memory, settings, exec, tostringx = _G.gui, _G.memory, _G.settings, _G.exec, _G.tostringx

local luap = require 'luap'
local draw = require 'draw'
local config = require 'config'
local lsnes = require 'lsnes'
local cheat = require 'cheat'
local lagmeter = require 'lagmeter'
local smw = require 'game.smw'
local tile = require 'game.tile'
local smwdebug = require 'game.smwdebug'

local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LSNES_FONT_WIDTH = config.LSNES_FONT_WIDTH
local controller = lsnes.controller

local fmt = string.format

-- Lateral Paddings (those persist if the script is closed and can be edited under Configure > Settings > Advanced > UI)
function M.adjust_lateral_gaps()
    draw.Font = false
    local left_gap, right_gap = OPTIONS.left_gap, OPTIONS.right_gap
    local top_gap, bottom_gap = OPTIONS.top_gap, OPTIONS.bottom_gap

    -- rectangle the helps to see the padding values
    gui.rectangle(-left_gap, -top_gap, draw.Buffer_width + right_gap + left_gap,
                  draw.Buffer_height + bottom_gap + top_gap, 1,
                  M.show_menu and COLOUR.warning2 or 0xb0808080) -- unlisted color
    draw.button(-draw.Border_left, draw.Buffer_middle_y, '+',
                function() OPTIONS.left_gap = OPTIONS.left_gap + 32 end,
                {always_on_client = true, ref_y = 1.0})
    draw.button(-draw.Border_left, draw.Buffer_middle_y, '-', function()
        if left_gap > 32 then
            OPTIONS.left_gap = OPTIONS.left_gap - 32
        else
            OPTIONS.left_gap = 0
        end
    end, {always_on_client = true})

    draw.button(draw.Buffer_width, draw.Buffer_middle_y, '+',
                function() OPTIONS.right_gap = OPTIONS.right_gap + 32 end,
                {always_on_client = true, ref_y = 1.0})
    draw.button(draw.Buffer_width, draw.Buffer_middle_y, '-', function()
        if right_gap > 32 then
            OPTIONS.right_gap = OPTIONS.right_gap - 32
        else
            OPTIONS.right_gap = 0
        end
    end, {always_on_client = true})

    draw.button(draw.Buffer_middle_x, -draw.Border_top, '+',
                function() OPTIONS.top_gap = OPTIONS.top_gap + 32 end,
                {always_on_client = true, ref_x = 1.0})
    draw.button(draw.Buffer_middle_x, -draw.Border_top, '-', function()
        if top_gap > 32 then
            OPTIONS.top_gap = OPTIONS.top_gap - 32
        else
            OPTIONS.top_gap = 0
        end
    end, {always_on_client = true})

    draw.button(draw.Buffer_middle_x, draw.Buffer_height, '+',
                function() OPTIONS.bottom_gap = OPTIONS.bottom_gap + 32 end,
                {always_on_client = true, ref_x = 1.0})
    draw.button(draw.Buffer_middle_x, draw.Buffer_height, '-', function()
        if bottom_gap > 32 then
            OPTIONS.bottom_gap = OPTIONS.bottom_gap - 32
        else
            OPTIONS.bottom_gap = 0
        end
    end, {always_on_client = true})
end

function M.print_help()
    print('\n')
    print(' - - - TIPS - - - ')
    print('MOUSE:')
    print('Use the left click to draw blocks and to see the Map16 properties.')
    print('Use the right click to toogle the hitbox mode of Mario and sprites.')
    print('\n')

    print('CHEATS(better turn off while recording a movie):')
    print('L+R+up: stop gravity for Mario fly / L+R+down to cancel')
    print('Use the mouse to drag and drop sprites')
    print('While paused: B+select to get out of the level')
    print('          X+select to beat the level (main exit)')
    print('          A+select to get the secret exit (don\'t use it if there isn\'t one)')
    print('Command cheats(use lsnes:Messages and type the commands, that are cAse-SENSitiVE):')
    print('score <value>:  set the score to <value>.')
    print('coin <value>:   set the coin number to <value>.')
    print('powerup <value>: set the powerup number to <value>.')

    print('\n')
    print('OTHERS:')
    print(fmt('Press "%s" for more and "%s" for less opacity.', OPTIONS.hotkey_increase_opacity,
              OPTIONS.hotkey_decrease_opacity))
    print('If performance suffers, disable some options that are not needed at the moment.')
    print('', '(input display and sprites are the ones that slow down the most).')
    print('It\'s better to play without the mouse over the game window.')
    print(' - - - end of tips - - - ')
end

function M.display()
    if not M.show_menu then return end

    -- Pauses emulator and draws the background
    if lsnes.runmode == 'normal' then exec('pause-emulator') end
    gui.rectangle(0, 0, draw.Buffer_width, draw.Buffer_height, 2, COLOUR.mainmenu_outline,
                  COLOUR.mainmenu_bg)

    -- Font stuff
    draw.Font = false
    local delta_x = draw.font_width()
    local delta_y = draw.font_height() + 4
    local x_pos, y_pos = 4, 4
    local tmp

    -- Exit menu button
    gui.solidrectangle(0, 0, draw.Buffer_width, delta_y, 0xa0ffffff) -- tab's shadow / unlisted color
    draw.button(draw.Buffer_width, 0, ' X ', function() M.show_menu = false end,
                {always_on_game = true})

    -- External buttons
    tmp = OPTIONS.display_controller_input and 'Hide Input' or 'Show Input'
    draw.button(0, 0, tmp, function()
        OPTIONS.display_controller_input = not OPTIONS.display_controller_input
    end, {always_on_client = true, ref_x = 1.0, ref_y = 1.0})

    tmp = cheat.allow_cheats and 'Cheats: allowed' or 'Cheats: blocked'
    draw.button(-draw.Border_left, draw.Buffer_height, tmp, function()
        cheat.allow_cheats = not cheat.allow_cheats
        draw.message('Cheats ' .. (cheat.allow_cheats and 'allowed.' or 'blocked.'))
    end, {always_on_client = true, ref_y = 1.0})

    draw.button(draw.Buffer_width + draw.Border_right, draw.Buffer_height, 'Erase Tiles',
                function()
        tile.layer1 = {}
        tile.layer2 = {}
    end, {always_on_client = true, ref_y = 1.0})

    -- Tabs
    draw.button(x_pos, y_pos, 'Show/hide', function() M.current_tab = 'Show/hide options' end,
                {button_pressed = M.current_tab == 'Show/hide options'})
    x_pos = x_pos + 9 * delta_x + 2

    draw.button(x_pos, y_pos, 'Settings', function() M.current_tab = 'Misc options' end,
                {button_pressed = M.current_tab == 'Misc options'})
    x_pos = x_pos + 8 * delta_x + 2

    draw.button(x_pos, y_pos, 'Lag', function() M.current_tab = 'Lag options' end,
                {button_pressed = M.current_tab == 'Lag options'})
    x_pos = x_pos + 3 * delta_x + 2

    draw.button(x_pos, y_pos, 'Debug info', function() M.current_tab = 'Debug info' end,
                {button_pressed = M.current_tab == 'Debug info'})
    x_pos = x_pos + 10 * delta_x + 2

    draw.button(x_pos, y_pos, 'Sprite tables',
                function() M.current_tab = 'Sprite miscellaneous tables' end,
                {button_pressed = M.current_tab == 'Sprite miscellaneous tables'})
    -- x_pos = x_pos + 13*delta_x + 2

    x_pos, y_pos = 4, y_pos + delta_y + 8

    if M.current_tab == 'Show/hide options' then
        tmp = OPTIONS.display_movie_info and true or ' '
        draw.button(x_pos, y_pos, tmp,
                    function() OPTIONS.display_movie_info = not OPTIONS.display_movie_info end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Display Movie Info?')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.display_misc_info and true or ' '
        draw.button(x_pos, y_pos, tmp,
                    function() OPTIONS.display_misc_info = not OPTIONS.display_misc_info end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Display Misc Info?')
        x_pos = x_pos + 20 * delta_x + 8

        tmp = OPTIONS.display_RNG_info and true or ' '
        draw.button(x_pos, y_pos, tmp,
                    function() OPTIONS.display_RNG_info = not OPTIONS.display_RNG_info end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Display RNG?')
        x_pos = 4
        y_pos = y_pos + delta_y + 8

        -- Player properties
        gui.text(x_pos, y_pos, 'Player:')
        x_pos = x_pos + 8 * delta_x
        tmp = OPTIONS.display_player_info and true or ' '
        draw.button(x_pos, y_pos, tmp,
                    function() OPTIONS.display_player_info = not OPTIONS.display_player_info end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Info')
        x_pos = x_pos + 5 * delta_x
        tmp = OPTIONS.display_player_hitbox and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_player_hitbox = not OPTIONS.display_player_hitbox
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Hitbox')
        x_pos = x_pos + 7 * delta_x
        tmp = OPTIONS.display_interaction_points and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_interaction_points = not OPTIONS.display_interaction_points
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Clipping')
        x_pos = x_pos + 9 * delta_x
        tmp = OPTIONS.display_cape_hitbox and true or ' '
        draw.button(x_pos, y_pos, tmp,
                    function() OPTIONS.display_cape_hitbox = not OPTIONS.display_cape_hitbox end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Cape')
        x_pos = x_pos + 5 * delta_x
        tmp = OPTIONS.display_debug_player_extra and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_debug_player_extra = not OPTIONS.display_debug_player_extra
        end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Extra')
        x_pos, y_pos = 4, y_pos + delta_y + 8 -- reset

        -- Sprites properties
        gui.text(x_pos, y_pos, 'Sprites:')
        x_pos = x_pos + 9 * delta_x
        tmp = OPTIONS.display_sprite_info and true or ' '
        draw.button(x_pos, y_pos, tmp,
                    function() OPTIONS.display_sprite_info = not OPTIONS.display_sprite_info end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Info')
        x_pos = x_pos + 5 * delta_x
        tmp = OPTIONS.display_sprite_hitbox and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_sprite_hitbox = not OPTIONS.display_sprite_hitbox
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Hitbox')
        x_pos = x_pos + 7 * delta_x
        tmp = OPTIONS.display_sprite_vs_sprite_hitbox and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_sprite_vs_sprite_hitbox = not OPTIONS.display_sprite_vs_sprite_hitbox
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'vs sprites')
        x_pos = x_pos + 11 * delta_x
        tmp = OPTIONS.display_debug_sprite_tweakers and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_debug_sprite_tweakers = not OPTIONS.display_debug_sprite_tweakers
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Tweakers')
        x_pos = x_pos + 9 * delta_x
        tmp = OPTIONS.display_debug_sprite_extra and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_debug_sprite_extra = not OPTIONS.display_debug_sprite_extra
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Extra')
        x_pos, y_pos = 4, y_pos + delta_y + 8 -- reset

        -- Extended sprites properties
        gui.text(x_pos, y_pos, 'Extended sprites:')
        x_pos = x_pos + 18 * delta_x
        tmp = OPTIONS.display_extended_sprite_info and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_extended_sprite_info = not OPTIONS.display_extended_sprite_info
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Info')
        x_pos = x_pos + 5 * delta_x
        tmp = OPTIONS.display_extended_sprite_hitbox and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_extended_sprite_hitbox = not OPTIONS.display_extended_sprite_hitbox
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Hitbox')
        x_pos = x_pos + 7 * delta_x
        tmp = OPTIONS.display_debug_extended_sprite and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_debug_extended_sprite = not OPTIONS.display_debug_extended_sprite
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Extra')
        x_pos, y_pos = 4, y_pos + delta_y + 8 -- reset

        -- Cluster sprites properties
        gui.text(x_pos, y_pos, 'Cluster sprites:')
        x_pos = x_pos + 17 * delta_x
        tmp = OPTIONS.display_cluster_sprite_info and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_cluster_sprite_info = not OPTIONS.display_cluster_sprite_info
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Info')
        x_pos = x_pos + 5 * delta_x
        tmp = OPTIONS.display_cluster_sprite_hitbox and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_cluster_sprite_hitbox = not OPTIONS.display_cluster_sprite_hitbox
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Hitbox')
        x_pos = x_pos + 7 * delta_x
        tmp = OPTIONS.display_debug_cluster_sprite and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_debug_cluster_sprite = not OPTIONS.display_debug_cluster_sprite
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Extra')
        x_pos, y_pos = 4, y_pos + delta_y + 8 -- reset

        -- Minor extended sprites properties
        gui.text(x_pos, y_pos, 'Minor ext. sprites:')
        x_pos = x_pos + 20 * delta_x
        tmp = OPTIONS.display_minor_extended_sprite_info and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_minor_extended_sprite_info =
            not OPTIONS.display_minor_extended_sprite_info
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Info')
        x_pos = x_pos + 5 * delta_x
        tmp = OPTIONS.display_minor_extended_sprite_hitbox and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_minor_extended_sprite_hitbox =
            not OPTIONS.display_minor_extended_sprite_hitbox
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Hitbox')
        x_pos = x_pos + 7 * delta_x
        tmp = OPTIONS.display_debug_minor_extended_sprite and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_debug_minor_extended_sprite =
            not OPTIONS.display_debug_minor_extended_sprite
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Extra')
        x_pos, y_pos = 4, y_pos + delta_y + 8 -- reset

        -- Bounce sprites properties
        gui.text(x_pos, y_pos, 'Bounce sprites:')
        x_pos = x_pos + 16 * delta_x
        tmp = OPTIONS.display_bounce_sprite_info and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_bounce_sprite_info = not OPTIONS.display_bounce_sprite_info
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Info')

        x_pos = x_pos + 5 * delta_x
        tmp = OPTIONS.display_quake_sprite_info and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_quake_sprite_info = not OPTIONS.display_quake_sprite_info
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Quake')

        x_pos = x_pos + 6 * delta_x
        tmp = OPTIONS.display_debug_bounce_sprite and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_debug_bounce_sprite = not OPTIONS.display_debug_bounce_sprite
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Extra')
        x_pos, y_pos = 4, y_pos + delta_y + 8 -- reset

        -- Generator sprites
        gui.text(x_pos, y_pos, 'Generators:')
        x_pos = x_pos + 11 * delta_x + 3

        tmp = OPTIONS.display_generator_info and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_generator_info = not OPTIONS.display_generator_info
        end)
        x_pos = x_pos + delta_x + 16

        -- Shooter sprites
        gui.text(x_pos, y_pos, 'Shooters:')
        x_pos = x_pos + 9 * delta_x + 3

        tmp = OPTIONS.display_shooter_sprite_info and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_shooter_sprite_info = not OPTIONS.display_shooter_sprite_info
        end)
        x_pos, y_pos = 4, y_pos + delta_y + 8 -- reset

        -- Coin sprites
        gui.text(x_pos, y_pos, 'Coin sprites:')
        x_pos = x_pos + 13 * delta_x + 3

        tmp = OPTIONS.display_coin_sprite_info and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_coin_sprite_info = not OPTIONS.display_coin_sprite_info
        end)
        x_pos = x_pos + delta_x + 16

        -- Score sprites
        gui.text(x_pos, y_pos, 'Score sprites:')
        x_pos = x_pos + 14 * delta_x + 3

        tmp = OPTIONS.display_score_sprite_info and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_score_sprite_info = not OPTIONS.display_score_sprite_info
        end)
        x_pos = x_pos + delta_x + 16

        -- Smoke sprites
        gui.text(x_pos, y_pos, 'Smoke sprites:')
        x_pos = x_pos + 14 * delta_x + 3

        tmp = OPTIONS.display_smoke_sprite_info and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_smoke_sprite_info = not OPTIONS.display_smoke_sprite_info
        end)
        x_pos, y_pos = 4, y_pos + delta_y + 8 -- reset

        -- Level boundaries
        gui.text(x_pos, y_pos, 'Level boundary:')
        x_pos = x_pos + 16 * delta_x

        tmp = OPTIONS.display_level_boundary_always and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_level_boundary_always = not OPTIONS.display_level_boundary_always
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Always')
        x_pos = x_pos + 7 * delta_x

        tmp = OPTIONS.display_sprite_vanish_area and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_sprite_vanish_area = not OPTIONS.display_sprite_vanish_area
        end)
        x_pos = x_pos + delta_x + 3
        gui.text(x_pos, y_pos, 'Sprites')
        x_pos, y_pos = 4, y_pos + delta_y + 8

        tmp = OPTIONS.display_level_info and true or ' '
        draw.button(x_pos, y_pos, tmp,
                    function() OPTIONS.display_level_info = not OPTIONS.display_level_info end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Show Level Info?')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.display_yoshi_info and true or ' '
        draw.button(x_pos, y_pos, tmp,
                    function() OPTIONS.display_yoshi_info = not OPTIONS.display_yoshi_info end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Show Yoshi Info?')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.display_counters and true or ' '
        draw.button(x_pos, y_pos, tmp,
                    function() OPTIONS.display_counters = not OPTIONS.display_counters end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Show Counters Info?')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.display_static_camera_region and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_static_camera_region = not OPTIONS.display_static_camera_region
        end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Show Camera Region?')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.use_block_duplication_predictor and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.use_block_duplication_predictor = not OPTIONS.use_block_duplication_predictor
        end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Use block duplication predictor?')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.register_player_position_changes
        if tmp == 'simple' then
            tmp = ' simple '
        elseif (not tmp) then
            tmp = 'disabled'
        end
        draw.button(x_pos, y_pos, tmp, function()
            if OPTIONS.register_player_position_changes == 'simple' then
                OPTIONS.register_player_position_changes = 'complete'
            elseif OPTIONS.register_player_position_changes == 'complete' then
                OPTIONS.register_player_position_changes = false
            else
                OPTIONS.register_player_position_changes = 'simple'
            end
        end)
        gui.text(x_pos + 8 * delta_x + 3, y_pos, 'Register player position changes between frames?')
    elseif M.current_tab == 'Misc options' then
        tmp = OPTIONS.register_ACE_debug_callback and true or ' '
        draw.button(x_pos, y_pos, tmp, function() smwdebug.register_debug_callback(true) end)
        gui.text(x_pos + delta_x + 3, y_pos,
                 'Detect arbitrary code execution for some addresses? (ACE)')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.draw_tiles_with_click and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.draw_tiles_with_click = not OPTIONS.draw_tiles_with_click
        end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Draw tiles with left click?')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.use_custom_fonts and true or ' '
        draw.button(x_pos, y_pos, tmp,
                    function() OPTIONS.use_custom_fonts = not OPTIONS.use_custom_fonts end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Use custom fonts?')
        y_pos = y_pos + delta_y

        tmp = 'Background:'
        draw.button(x_pos, y_pos, tmp, function()
            if OPTIONS.text_background_type == 'automatic' then
                OPTIONS.text_background_type = 'full'
            elseif OPTIONS.text_background_type == 'full' then
                OPTIONS.text_background_type = 'outline'
            else
                OPTIONS.text_background_type = 'automatic'
            end
        end)
        draw.Font = 'Uzebox6x8'
        tmp = draw.text(x_pos + 11 * delta_x + 6, y_pos, tostringx(OPTIONS.text_background_type),
                        COLOUR.warning, COLOUR.warning_bg)
        draw.Font = false
        draw.text(tmp + 3, y_pos, tostringx(OPTIONS.text_background_type), COLOUR.warning,
                  COLOUR.warning_bg)
        y_pos = y_pos + delta_y

        tmp = OPTIONS.is_simple_comparison_ghost_loaded and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            if not OPTIONS.is_simple_comparison_ghost_loaded then
                Ghost_player = require 'ghost' -- FIXME:
                Ghost_player.init()
            else
                luap.unrequire 'ghost'
                Ghost_player = nil
            end
            OPTIONS.is_simple_comparison_ghost_loaded =
            not OPTIONS.is_simple_comparison_ghost_loaded
        end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Load comparison ghost?')
        y_pos = y_pos + delta_y

        -- Manage opacity / filter
        x_pos, y_pos = 4, y_pos + delta_y
        gui.text(x_pos, y_pos, 'Opacity:')
        y_pos = y_pos + delta_y
        draw.button(x_pos, y_pos, '-', function()
            if OPTIONS.filter_opacity >= 1 then
                OPTIONS.filter_opacity = OPTIONS.filter_opacity - 1
            end
            COLOUR.filter_color = draw.change_transparency(COLOUR.filter_tonality,
                                                           OPTIONS.filter_opacity / 10)
        end)
        draw.button(x_pos + delta_x + 2, y_pos, '+', function()
            if OPTIONS.filter_opacity <= 9 then
                OPTIONS.filter_opacity = OPTIONS.filter_opacity + 1
            end
            COLOUR.filter_color = draw.change_transparency(COLOUR.filter_tonality,
                                                           OPTIONS.filter_opacity / 10)
        end)
        gui.text(x_pos + 2 * delta_x + 5, y_pos,
                 'Change filter opacity (' .. 10 * OPTIONS.filter_opacity .. '%)')
        y_pos = y_pos + delta_y

        draw.button(x_pos, y_pos, '-', draw.decrease_opacity)
        draw.button(x_pos + delta_x + 2, y_pos, '+', draw.increase_opacity)
        gui.text(x_pos + 2 * delta_x + 5, y_pos,
                 fmt('Text opacity: (%.0f%%, %.0f%%)', 100 * draw.Text_max_opacity,
                     100 * draw.Background_max_opacity))
        y_pos = y_pos + delta_y
        gui.text(x_pos, y_pos,
                 fmt('\'%s\' and \'%s\' are hotkeys for this.', OPTIONS.hotkey_decrease_opacity,
                     OPTIONS.hotkey_increase_opacity), COLOUR.weak)
        y_pos = y_pos + delta_y

        -- Video and AVI settings
        y_pos = y_pos + delta_y
        gui.text(x_pos, y_pos, 'Video settings:')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.make_lua_drawings_on_video and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.make_lua_drawings_on_video = not OPTIONS.make_lua_drawings_on_video
        end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Make lua drawings on video?')
        y_pos = y_pos + delta_y

        -- Others
        y_pos = y_pos + delta_y
        gui.text(x_pos, y_pos, 'Help:')
        y_pos = y_pos + delta_y
        draw.button(x_pos, y_pos, 'Reset Permanent Lateral Paddings', function()
            settings.set('left-border', '0')
            settings.set('right-border', '0')
            settings.set('top-border', '0')
            settings.set('bottom-border', '0')
        end)
        y_pos = y_pos + delta_y

        draw.button(x_pos, y_pos, 'Reset Lateral Gaps', function()
            OPTIONS.left_gap = LSNES_FONT_WIDTH * (controller.total_width + 6)
            OPTIONS.right_gap = config.DEFAULT_OPTIONS.right_gap
            OPTIONS.top_gap = config.DEFAULT_OPTIONS.top_gap
            OPTIONS.bottom_gap = config.DEFAULT_OPTIONS.bottom_gap
        end)
        y_pos = y_pos + delta_y

        draw.button(x_pos, y_pos, 'Show tips in lsnes: Messages', M.print_help)
    elseif M.current_tab == 'Lag options' then
        tmp = OPTIONS.use_lagmeter_tool and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.use_lagmeter_tool = not OPTIONS.use_lagmeter_tool
            local task = OPTIONS.use_lagmeter_tool and 'registerexec' or 'unregisterexec'
            memory[task]('BUS', 0x8075, lagmeter.get_master_cycles) -- unlisted ROM
        end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Lagmeter tool? (experimental/for SMW only)')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.use_custom_lag_detector and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.use_custom_lag_detector = not OPTIONS.use_custom_lag_detector
        end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Use custom lag detector?')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.use_custom_lagcount and true or ' '
        draw.button(x_pos, y_pos, tmp,
                    function() OPTIONS.use_custom_lagcount = not OPTIONS.use_custom_lagcount end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Use custom lag count?')
        y_pos = y_pos + delta_y

        tmp = 'Print help'
        draw.button(x_pos, y_pos, tmp, function()
            print('\nLagmeter tool:\n' ..
                  'This tool displays almost exactly how laggy the last frame has been.\n' ..
                  'Only works well for SMW(NTSC) and inside the level, where it usually matters.\n' ..
                  'Anything below 100% is not lagged, otherwise the game lagged.\n' ..
                  '\nCustom lag detector:\n' ..
                  'On some games, lsnes has false positives for lag.\n' ..
                  'This custom detector only checks if the game polled input and if WRAM $10 is zero.\n' ..
                  'For SMW, this also detects lag 1 frame sooner, which is useful.\n' ..
                  'By letting the lag count obey this custom detector, the number will persist ' ..
                  'even after the script is finished.\n')
        end)
    elseif M.current_tab == 'Debug info' then
        tmp = OPTIONS.display_debug_controller_data and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_debug_controller_data = not OPTIONS.display_debug_controller_data
        end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Controller data (freezes the lag counter!)')
        y_pos = y_pos + delta_y

        tmp = OPTIONS.debug_collision_routine and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.debug_collision_routine = not OPTIONS.debug_collision_routine
        end)
        gui.text(x_pos + delta_x + 3, y_pos, fmt(
                 'Debug collision routine 1 ($%.6x). May not work in ROMhacks',
                 smw.CHECK_FOR_CONTACT_ROUTINE))
        y_pos = y_pos + delta_y

        if OPTIONS.debug_collision_routine then
            tmp = OPTIONS.display_collision_routine_fail and true or ' '
            draw.button(x_pos + 16, y_pos, tmp, function()
                OPTIONS.display_collision_routine_fail = not OPTIONS.display_collision_routine_fail
            end)
            gui.text(x_pos + delta_x + 3 + 16, y_pos, 'Show collision checks without contact?')
        end
    elseif M.current_tab == 'Sprite miscellaneous tables' then
        tmp = OPTIONS.display_miscellaneous_sprite_table and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_miscellaneous_sprite_table =
            not OPTIONS.display_miscellaneous_sprite_table
        end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Show Miscellaneous Sprite Table?')

        x_pos = 4
        y_pos = y_pos + delta_y
        tmp = OPTIONS.display_sprite_load_status and true or ' '
        draw.button(x_pos, y_pos, tmp, function()
            OPTIONS.display_sprite_load_status = not OPTIONS.display_sprite_load_status
        end)
        gui.text(x_pos + delta_x + 3, y_pos, 'Show sprite load status within level?')
    end

    -- Lateral Paddings
    M.adjust_lateral_gaps()

    return true
end

return M
