-- The settings page: Data Controls, to reset tracked data.

local common = require("src/ui/common")
local layerView = require("src/ui/layer_view")
local tracker = require("src/core/tracker")

local PAD = 14 -- the page's padding
local GAP = 8 -- between a row's controls, the layout's default
local ROW_HEIGHT = 30 -- a dropdown's height, which the labels and buttons match
local LABEL_WIDTH = 90
local BUTTON_WIDTH = 96

local page = layerView.New({ padding = PAD })
local chosenKey = nil -- the boss chosen to reset, kept while the plugin runs
local dialog = nil -- the open confirmation, if any

local settings = { Attach = page.Attach, IsOpen = page.IsOpen }

local function closeDialog()
    if dialog then
        dialog:Destroy()
        dialog = nil
    end
end

-- Asks before reset() deletes anything.
local function confirm(body, reset)
    closeDialog()
    dialog = prettyui.Confirm.new(common.TopLayer(), {
        title = "Reset data",
        body = body .. " This can't be undone.",
        confirmLabel = "Reset",
        confirmVariant = "negative",
        onConfirm = function()
            dialog = nil
            reset()
        end,
        onCancel = function()
            dialog = nil
        end,
    })
end

-- The views' entries with tracked kills, in their order (by name).
local function withTrackedKills(list)
    local tracked = {}
    for _, entry in ipairs(list) do
        if tracker.Total(entry.tallies.kills) > 0 then
            table.insert(tracked, entry)
        end
    end
    return tracked
end

-- A row's label, in the left column.
local function addLabel(host, text)
    host:AddText({ text = text, width = LABEL_WIDTH, height = ROW_HEIGHT })
end

-- A Reset button at the right of the current row.
local function addResetButton(host, onClick)
    host:AddSimpleButton("Reset", onClick, {
        inline = true,
        x = -(PAD + BUTTON_WIDTH),
        xAnchor = 1.0,
        width = BUTTON_WIDTH,
        height = ROW_HEIGHT,
    })
end

-- Reset every boss, then one boss (at first the one the views show). The dropdown
-- is added last so its open list draws over everything else.
local function addDataControls(host, state)
    host:AddTitle({ text = "Data Controls" })
    host:AddText({
        text = "Reset clears the kills and drops Boss RNG tracked for this character. "
            .. "The game's own counts are kept.",
    })
    local tracked = withTrackedKills(state.list)
    if #tracked == 0 then
        host:AddText({ text = "Nothing tracked yet." })
        return
    end
    host:AddDivider(common.Divider(PAD))

    addLabel(host, "All bosses")
    addResetButton(host, function()
        confirm("Reset tracked data for every boss?", state.onResetAll)
    end)

    addLabel(host, "One boss")
    local shownKey = state.selected and state.list[state.selected].boss.key
    local shown = common.IndexOf(tracked, chosenKey) or common.IndexOf(tracked, shownKey) or 1
    local chosen = tracked[shown].boss
    addResetButton(host, function()
        confirm("Reset tracked data for " .. chosen.name .. "?", function()
            state.onReset(chosen)
        end)
    end)
    local left = PAD + LABEL_WIDTH + GAP
    common.AddBossPicker(host, tracked, shown, function(boss)
        chosen, chosenKey = boss, boss.key
    end, {
        inline = true,
        x = left,
        height = ROW_HEIGHT,
        width = -(left + GAP + BUTTON_WIDTH + PAD),
        widthAnchor = 1.0,
    })
end

function settings.Draw(state)
    addDataControls(page.Fresh(), state)
end

function settings.ShowError()
    page.Fresh():AddText({ text = "Boss RNG couldn't draw its settings." })
end

function settings.Detach()
    closeDialog()
    page.Detach()
end

return settings
