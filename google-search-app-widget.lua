-- name = "Google search"
-- description = "AIO wrapper for the Google search app widget"
-- type = "widget"
-- author = "Theodor Galanis"
-- version = "1.0"
-- foldable = "false"
-- uses_app: "com.google.android.googlequicksearchbox""

local prefs = require "prefs"

local buttons_labels = {"GOOGLE", "fa:magnifying-glass", "fa:microphone", "fa:camera"}
local buttons_targets = {"image_3", "image_2", "image_5", "image_6"}
local w_bridge = nil

function on_resume()
    if not widgets:bound(prefs.wid) then
        setup_app_widget()
    end

    widgets:request_updates(prefs.wid)
end

function on_app_widget_updated(bridge)
    w_bridge = bridge
    ui:show_buttons(buttons_labels)
end

function on_click(idx)
    w_bridge:click(buttons_targets[idx])
end

function setup_app_widget()
    local id = widgets:setup("com.google.android.googlequicksearchbox/com.google.android.googlequicksearchbox.SearchWidgetProvider")

    if (id ~= nil) then
        prefs.wid = id
    else
        ui:show_text("Can't add widget")
        return
    end
end
