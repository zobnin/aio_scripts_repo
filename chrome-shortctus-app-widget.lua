-- name = "Chrome shortcuts"
-- description = "AIO wrapper for the Chrome shortcuts app widget"
-- type = "widget"
-- author = "Evgeny Zobnin (zobnin@gmail.com)"
-- version = "2.0"
-- aio_version = "7.5.0-beta2"
-- foldable = "false"
-- uses_app = "com.android.chrome"

local prefs = require "prefs"
prefs._name = "chrome"

local provider = "com.android.chrome/"
    .."org.chromium.chrome.browser.quickactionsearchwidget."
    .."QuickActionSearchWidgetProvider$QuickActionSearchWidgetProviderSearch"
local actions = {
    {
        label = "fa:magnifying-glass",
        resource_id = "com.android.chrome:id/quick_action_search_widget_search_bar_container",
    },
    {
        label = "fa:microphone",
        resource_id = "com.android.chrome:id/voice_search_quick_action_button",
    },
    {
        label = "fa:hat_cowboy_side",
        resource_id = "com.android.chrome:id/incognito_quick_action_button",
    },
    {
        label = "fa:camera",
        resource_id = "com.android.chrome:id/lens_quick_action_button",
    },
    {
        label = "fa:gamepad",
        resource_id = "com.android.chrome:id/dino_quick_action_button",
    },
}

local w_bridge = nil
local click_targets = {}

local function setup_app_widget()
    local id = widgets:setup(provider)
    if id == nil then
        ui:show_text("Can't add widget")
        return false
    end

    prefs.wid = id
    return true
end

local function find_node(snapshot, resource_id)
    for _, node in ipairs(snapshot.nodes or {}) do
        if node.resource_id == resource_id and node.click_target ~= nil then
            return node
        end
    end
    return nil
end

function on_resume()
    if not widgets:bound(prefs.wid) and not setup_app_widget() then
        return
    end

    widgets:request_updates(prefs.wid, "4x1")
end

function on_app_widget_updated(bridge)
    local snapshot = bridge:snapshot()
    local labels = {}
    local targets = {}

    for _, action in ipairs(actions) do
        local node = find_node(snapshot, action.resource_id)
        if node ~= nil then
            table.insert(labels, action.label)
            table.insert(targets, node.click_target)
        end
    end

    w_bridge = bridge
    click_targets = targets

    if #labels > 0 then
        ui:show_buttons(labels)
    else
        ui:show_text("Chrome shortcuts unavailable")
    end
end

function on_click(idx)
    local handle = click_targets[idx]
    if w_bridge ~= nil and handle ~= nil then
        w_bridge:click_handle(handle)
    end
end
