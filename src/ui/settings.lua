-- The settings page: for each boss with choices, its name, why and how to set
-- them, and a slider per choice; then Data Controls, to reset tracked data.

local choices = require("src/core/choices")
local common = require("src/ui/common")
local layerView = require("src/ui/layer_view")
local tracker = require("src/core/tracker")

local PAD = 14 -- the page's padding
local GAP = 8 -- between a row's controls, the layout's default
local CONTROL_HEIGHT = 30 -- a dropdown's height, which the buttons match
local BUTTON_WIDTH = 96

local page = layerView.New({ padding = PAD })
local chosenKey = nil -- the boss chosen to reset, kept while the plugin runs
local dialog = nil -- the open confirmation, if any

local settings = { Attach = page.Attach, IsOpen = page.IsOpen }

-- A choice's label with its value: "Normal Mode: 2.5".
local function labelFor(choice, value)
    local shown = value % 1 == 0 and string.format("%d", value) or tostring(value)
    return choice.label .. ": " .. shown
end

local function addChoices(host, boss, state)
    host:AddTitle({ text = boss.name })
    for _, paragraph in ipairs(boss.choicesHelp) do
        host:AddText({ text = paragraph })
    end
    local picks = choices.For(boss)
    for _, choice in ipairs(boss.choices) do
        local label = host:AddText({ text = labelFor(choice, picks[choice.key]) })
        host:AddSlider({
            min = choice.min, max = choice.max, step = choice.step,
            value = picks[choice.key],
            onChange = function(_, value)
                label.content = labelFor(choice, value)
                state.onChoose(boss, choice, value)
            end,
        })
    end
end

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
        onCancel = function() dialog = nil end,
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

-- A Reset button on the right of the current row, or of a new one.
local function addResetButton(host, inline, onClick)
    host:AddSimpleButton("Reset", onClick, {
        inline = inline, x = -(PAD + BUTTON_WIDTH), xAnchor = 1.0,
        width = BUTTON_WIDTH, height = CONTROL_HEIGHT,
    })
end

-- Reset every boss, then one boss (at first the one the views show), picked in a
-- dropdown added last so its open list draws over everything else.
local function addDataControls(host, state)
    host:AddTitle({ text = "Data Controls" })
    host:AddText({ text = "Reset clears the kills and drops Boss RNG tracked for this character. "
        .. "Your settings and the game's own counts are kept." })
    local tracked = withTrackedKills(state.list)
    if #tracked == 0 then
        host:AddText({ text = "Nothing tracked yet." })
        return
    end
    host:AddText({ text = "Every boss", height = CONTROL_HEIGHT })
    addResetButton(host, true, function()
        confirm("Reset tracked data for every boss?", state.onResetAll)
    end)
    host:AddText({ text = "One boss" })
    local shownKey = state.selected and state.list[state.selected].boss.key
    local shown = common.IndexOf(tracked, chosenKey) or common.IndexOf(tracked, shownKey) or 1
    local chosen = tracked[shown].boss
    addResetButton(host, false, function()
        confirm("Reset tracked data for " .. chosen.name .. "?", function() state.onReset(chosen) end)
    end)
    common.AddBossPicker(host, tracked, shown, function(boss)
        chosen, chosenKey = boss, boss.key
    end, { inline = true, x = PAD, width = -(2 * PAD + BUTTON_WIDTH + GAP), widthAnchor = 1.0 })
end

function settings.Draw(state)
    local host = page.Fresh()
    for _, boss in ipairs(state.bosses) do
        if boss.choices then
            addChoices(host, boss, state)
        end
    end
    addDataControls(host, state)
end

function settings.ShowError()
    page.Fresh():AddText({ text = "Boss RNG couldn't draw its settings." })
end

function settings.Detach()
    closeDialog()
    page.Detach()
end

return settings
