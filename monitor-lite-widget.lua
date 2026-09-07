-- name = "Monitor"
-- description = "One line monitor widget"
-- type = "widget"
-- foldable = "false"
-- author = "Evgeny Zobnin (zobnin@gmail.com)"
-- version = "1.0"

local fmt = require "fmt"
local good_color = aio:colors().progress_good
local bad_color = aio:colors().progress_bad

function on_tick(n)
    -- Update every ten seconds
    if n % 10 == 0 then
        update()
    end
end

function update()
    local batt = system:battery_info() or {}
    local sys = system:system_info() or {}
    local batt_percent = batt.percent
    local is_charging = batt.charging
    local mem_total = sys.mem_total
    local mem_available = sys.mem_available or "?"
    local storage_total = sys.storage_total
    local storage_available = sys.storage_available or "?"

    if (is_charging) then
        batt_percent = fmt.colored((batt_percent or "?").."%", good_color)
    elseif (type(batt_percent) == "number" and batt_percent <= 15) then
        batt_percent = fmt.colored(batt_percent.."%", bad_color)
    else
        batt_percent = (batt_percent or "?").."%"
    end

    ui:show_text(
        "BATT: "..batt_percent..fmt.space(4)..
        "RAM: "..mem_available..fmt.space(4)..
        "NAND: "..storage_available
    )
end
