-- name = "Todoist"
-- description = "AIO wrapper for the official Todoist app widget"
-- type = "widget"
-- author = "Andey Gavrilov"
-- version = "2.0"
-- aio_version = "7.5.0-beta2"
-- uses_app = "com.todoist"

local prefs = require "prefs"
local fmt = require "fmt"

local provider = "com.todoist/com.todoist.appwidget.provider.ItemListAppWidgetProvider"
local list_title_id = "com.todoist:id/appwidget_toolbar_title"
local add_task_id = "com.todoist:id/appwidget_toolbar_add"
local task_title_id = "com.todoist:id/text"
local task_date_id = "com.todoist:id/due_date"

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

local function node_text(node)
    return node.text or node.value
end

local function first_line(text)
    return text ~= nil and text:match("^[^\r\n]*") or nil
end

local function find_visible_node(snapshot, resource_id)
    for _, node in ipairs(snapshot.nodes or {}) do
        if node.visible and node.resource_id == resource_id then
            return node
        end
    end
    return nil
end

local function read_tasks(snapshot)
    local tasks = {}
    local max_position = -1

    for _, node in ipairs(snapshot.nodes or {}) do
        local collection = node.collection
        if node.visible and collection ~= nil then
            local position = collection.position
            local task = tasks[position] or {}

            if node.resource_id == task_title_id then
                task.title = first_line(node_text(node))
                task.click_target = node.click_target
            elseif node.resource_id == task_date_id then
                task.date = first_line(node_text(node))
            end

            if task.title ~= nil or task.date ~= nil then
                tasks[position] = task
                max_position = math.max(max_position, position)
            end
        end
    end

    return tasks, max_position
end

local function format_task(task)
    local line = task.title
    if task.date ~= nil and task.date ~= "" then
        line = line..fmt.secondary(" — "..task.date)
    end
    return line
end

function on_resume()
    if not widgets:bound(prefs.wid) and not setup_app_widget() then
        return
    end

    widgets:request_updates(prefs.wid)
end

function on_app_widget_updated(bridge)
    local snapshot = bridge:snapshot()
    local lines = {}
    local targets = {}
    local list_title = find_visible_node(snapshot, list_title_id)
    local add_task = find_visible_node(snapshot, add_task_id)
    local tasks, max_position = read_tasks(snapshot)
    local header_text = list_title ~= nil and node_text(list_title) or "Todoist"
    local header = fmt.bold(header_text)
    local header_target = list_title ~= nil and list_title.click_target or false
    local folded_line = nil

    table.insert(lines, header)
    table.insert(targets, header_target)
    targets[0] = header_target

    for position = 0, max_position do
        local task = tasks[position]
        if task ~= nil and task.title ~= nil then
            local line = format_task(task)
            table.insert(lines, line)
            table.insert(targets, task.click_target or false)

            if folded_line == nil then
                folded_line = line
                targets[0] = task.click_target or false
            end
        end
    end

    table.insert(lines, fmt.secondary("Add task"))
    table.insert(targets, add_task ~= nil and add_task.click_target or false)

    w_bridge = bridge
    click_targets = targets
    ui:show_lines(lines, nil, folded_line or header)
end

function on_click(idx)
    local handle = click_targets[idx]
    if w_bridge ~= nil and handle then
        w_bridge:click_handle(handle)
    end
end
