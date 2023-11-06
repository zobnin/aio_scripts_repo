-- name = "Quick Actions"
-- description = "Launcher selected actions widget"
-- type = "widget"
-- author = "Theodor Galanis"
-- version = "1.0"

md_colors = require "md_colors"

function on_resume()
    actions_names = { "fa:pen", "fa:edit", "fa:indent", "fa:bars", "fa:sliders-h", "fa:search", "fa:bring-forward", "fa:tools"}
    actions_colors = { md_colors.purple_800, md_colors.purple_600, md_colors.amber_900, md_colors.orange_900, md_colors.blue_900, md_colors.red_900, md_colors.green_900, md_colors.blue_800}
    actions = { "quick_menu", "quick_apps_menu", "apps_menu", "headers", "settings", "search", "notify", "quick_settings"}

    ui:show_buttons(actions_names, actions_colors)
end

function on_click(idx)
    aio:do_action(actions[idx])
end