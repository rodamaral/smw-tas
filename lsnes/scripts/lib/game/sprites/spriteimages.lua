local M = {}

local gui, GLOBAL_SMW_TAS_PARENT_DIR = _G.gui, _G.GLOBAL_SMW_TAS_PARENT_DIR

for id = 0, 0xff do
    local a = gui.image.load_png(
        string.format('sprite_%.2X.png', id),
        GLOBAL_SMW_TAS_PARENT_DIR .. 'images/sprites/'
    )
    M[id] = a
end

function M:draw_sprite(x, y, id, invertX, invertY)
    local image = self[id]
    if image then
        local xdraw, ydraw = x, y
        local w, h = image:size()

        if invertX then
            xdraw = xdraw - w
        end
        if invertY then
            ydraw = ydraw - h
        end

        image:draw(xdraw, ydraw)
    end
end

return M
