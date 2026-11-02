-- The ribbon panel: one boss's essentials and a "View details" button. It
-- scrolls if the panel is small.

local common = require("src/ui/common")
local format = require("src/ui/format")
local layerView = require("src/ui/layer_view")
local safe = require("src/utils/safe")

local PAD = 8
local page = layerView.New({ startY = 46, padding = PAD }) -- below the dropdown

local panel = { Attach = page.Attach, IsOpen = page.IsOpen, Detach = page.Detach }

function panel.Draw(state)
    local host = page.Fresh()
    if not state.selected then
        host:AddText({ text = "No boss kills yet. Kill a supported boss to start.", y = PAD })
        return
    end
    local result = state.list[state.selected].stats
    host:AddTitle({ text = format.Luck(result) })
    if format.IsTracked(result) then
        for _, line in ipairs({ format.TrackedShort(result), format.Dry(result) }) do
            if line ~= "" then
                host:AddText({ text = line })
            end
        end
    end
    -- Full width, rounded down to 8 px.
    local width = (page.layer.width - 2 * PAD) // 8 * 8
    host:AddSimpleButton("View details", function()
        safe.Call("opening the window", state.onDetails)
    end, { marginTop = 8, width = width, height = 32 })
    common.AddBossPicker(host, state.list, state.selected, state.onPick, { y = PAD })
end

function panel.ShowError()
    page.Fresh():AddText({ text = "Boss RNG couldn't draw this panel.", y = PAD })
end

return panel
