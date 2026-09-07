-- name = "Google Tasks"
-- description = "AIO wrapper for the official Google Tasks app widget"
-- type = "widget"
-- author = "Evgeny Zobnin (zobnin@gmail.com)"
-- version = "2.1"
-- aio_version = "7.5.0-beta2"
-- uses_app = "com.google.android.apps.tasks"

local prefs = require "prefs"
local fmt = require "fmt"

local provider = "com.google.android.apps.tasks/com.google.android.apps.tasks.features.widgetlarge.ListWidgetProvider"
local list_title_id = "com.google.android.apps.tasks:id/list_title"
local add_task_id = "com.google.android.apps.tasks:id/add_task"
local task_title_id = "com.google.android.apps.tasks:id/title"
local task_date_id = "com.google.android.apps.tasks:id/datetime_text"

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

local function node_top(node)
    return node.bounds ~= nil and node.bounds.top or math.huge
end

local function node_left(node)
    return node.bounds ~= nil and node.bounds.left or math.huge
end

local function is_visible_text(node)
    local text = node_text(node)
    return node.visible and node.kind == "text" and text ~= nil and text ~= ""
end

local function find_visible_node(snapshot, resource_id)
    for _, node in ipairs(snapshot.nodes or {}) do
        if node.visible and node.resource_id == resource_id then
            return node
        end
    end
    return nil
end

local function find_list_title(snapshot)
    local named_node = find_visible_node(snapshot, list_title_id)
    if named_node ~= nil then
        return named_node
    end

    local candidate = nil
    for _, node in ipairs(snapshot.nodes or {}) do
        if is_visible_text(node) then
            if candidate == nil or node_top(node) < node_top(candidate)
                or (node_top(node) == node_top(candidate) and node_left(node) < node_left(candidate)) then
                candidate = node
            end
        end
    end
    return candidate
end

local function find_add_task(snapshot)
    local named_node = find_visible_node(snapshot, add_task_id)
    if named_node ~= nil then
        return named_node
    end

    local candidate = nil
    for _, node in ipairs(snapshot.nodes or {}) do
        if node.visible and node.kind == "image" and node.click_target ~= nil
            and node.content_description ~= nil then
            if candidate == nil or node_top(node) < node_top(candidate)
                or (node_top(node) == node_top(candidate) and node_left(node) > node_left(candidate)) then
                candidate = node
            end
        end
    end
    return candidate
end

local function read_tasks(snapshot)
    local tasks = {}
    local max_position = -1
    local has_named_nodes = find_visible_node(snapshot, task_title_id) ~= nil

    for _, node in ipairs(snapshot.nodes or {}) do
        local collection = node.collection
        local is_task_position = collection ~= nil
            and collection.position >= (has_named_nodes and 0 or 1)

        if node.visible and is_task_position then
            local position = collection.position
            local task = tasks[position] or {}

            if has_named_nodes then
                if node.resource_id == task_title_id then
                    task.title = first_line(node_text(node))
                    task.click_target = node.click_target
                elseif node.resource_id == task_date_id then
                    task.date = first_line(node_text(node))
                end
            elseif is_visible_text(node) then
                local text = node_text(node)

                -- Glance rows have no stable resource IDs. Their date is the
                -- semantic text node; the uppermost other text is the title.
                if node.content_description ~= nil then
                    task.date = first_line(text)
                elseif task.title == nil or node_top(node) < task.title_top then
                    task.title = first_line(text)
                    task.title_top = node_top(node)
                    task.click_target = node.click_target
                end
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
    local list_title = find_list_title(snapshot)
    local add_task = find_add_task(snapshot)
    local tasks, max_position = read_tasks(snapshot)
    local header_text = list_title ~= nil and node_text(list_title) or "Google Tasks"
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
