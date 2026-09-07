-- name = "Google search"
-- description = "AIO wrapper for the Google search app widget - open widget settings for options"
-- type = "widget"
-- author = "Theodor Galanis (t.me/TheodorGalanis)"
-- version = "3.0"
-- aio_version = "7.5.0-beta2"
-- foldable = "false"
-- uses_app = "com.google.android.googlequicksearchbox"

local prefs = require "prefs"

local provider = "com.google.android.googlequicksearchbox/com.google.android.googlequicksearchbox.SearchWidgetProvider"
local action_definitions = {
    search = {
        label = "fa:magnifying-glass",
        resource_id = "com.google.android.googlequicksearchbox:id/googleapp_search_widget_ghost_text_search",
        description = "Google search",
    },
    weather = {
        label = "fa:sun-cloud",
        description = "Google weather",
    },
    discover = {
        label = "fa:asterisk",
        resource_id = "com.google.android.googlequicksearchbox:id/googleapp_search_widget_google_logo",
        description = "Google discover",
    },
    voice = {
        label = "fa:microphone",
        resource_id = "com.google.android.googlequicksearchbox:id/googleapp_search_widget_voice_btn",
        description = "Google voice search",
    },
    lens = {
        label = "fa:camera",
        resource_id = "com.google.android.googlequicksearchbox:id/googleapp_search_widget_lens_btn",
        description = "Google Lens",
    },
}
local mode_orders = {
    {"search", "weather", "discover", "voice", "lens"},
    {"search", "discover", "voice", "lens"},
    {"lens", "voice", "discover", "weather", "search"},
    {"lens", "voice", "discover", "search"},
}

local w_bridge = nil
local click_actions = {}
local current_mode = 1

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

local function weather_intent()
    return {
        category = "MAIN",
        package = "com.google.android.googlequicksearchbox",
        component = "com.google.android.googlequicksearchbox/"
            .."com.google.android.apps.search.weather.WeatherExportedActivity",
    }
end

function on_resume()
    if not widgets:bound(prefs.wid) and not setup_app_widget() then
        return
    end

    current_mode = tonumber(prefs.mode) or 1
    if mode_orders[current_mode] == nil then
        current_mode = 1
    end
    widgets:request_updates(prefs.wid, "4x1")
end

function on_app_widget_updated(bridge)
    local snapshot = bridge:snapshot()
    local labels = {}
    local actions = {}

    for _, name in ipairs(mode_orders[current_mode]) do
        local definition = action_definitions[name]
        if name == "weather" then
            table.insert(labels, definition.label)
            table.insert(actions, {name = name})
        else
            local node = find_node(snapshot, definition.resource_id)
            if node ~= nil then
                table.insert(labels, definition.label)
                table.insert(actions, {name = name, handle = node.click_target})
            end
        end
    end

    w_bridge = bridge
    click_actions = actions

    if #labels > 0 then
        ui:show_buttons(labels)
    else
        ui:show_text("Google search unavailable")
    end
end

function on_click(idx)
    local action = click_actions[idx]
    if action == nil then
        return
    end

    if action.name == "weather" then
        intent:start_activity(weather_intent())
    elseif w_bridge ~= nil and action.handle ~= nil then
        w_bridge:click_handle(action.handle)
    end
end

function on_long_click(idx)
    local action = click_actions[idx]
    local definition = action ~= nil and action_definitions[action.name] or nil
    if definition ~= nil then
        ui:show_toast(definition.description)
    end
end

function on_settings()
    dialogs:show_radio_dialog(
        "Select mode",
        {
            "Left-handed mode with weather",
            "Left-handed mode, no weather",
            "Right-handed mode with weather",
            "Right-handed mode, no weather",
        },
        current_mode
    )
end

function on_dialog_action(data)
    if data == nil or data < 1 or mode_orders[data] == nil then
        return
    end

    prefs.mode = data
    current_mode = data
    widgets:request_updates(prefs.wid, "4x1")
end
