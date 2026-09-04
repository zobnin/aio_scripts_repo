-- name = "Текст на день"
-- description = "Показывает ежедневный библейский стих"
-- data_source = "https://vasiley.ru/rss/daily-text-ru.xml"
-- type = "widget"
-- author = "Vasiliy"
-- version = "1.2"
-- foldable = "false"

local api = require 'aio_api'

local daily_text = nil
local loading = true
local error_text = nil

local render
local load_text

local function escape_html(text)
    text = tostring(text or '')
    text = text:gsub('&', '&amp;')
    text = text:gsub('<', '&lt;')
    text = text:gsub('>', '&gt;')
    return text
end

local function decode_html(text)
    text = tostring(text or '')

    text = text:gsub('<!%[CDATA%[', '')
    text = text:gsub('%]%]>', '')

    text = text:gsub('&quot;', '"')
    text = text:gsub('&#34;', '"')
    text = text:gsub('&apos;', "'")
    text = text:gsub('&#39;', "'")
    text = text:gsub('&lt;', '<')
    text = text:gsub('&gt;', '>')
    text = text:gsub('&amp;', '&')

    return text
end

local function open_verse()
    api.intent.open_uri('https://wol.jw.org/ru/wol/h/r2/lp-u')
end

local function copy_verse()
    if daily_text and daily_text ~= '' then
        api.system.to_clipboard(daily_text)
        api.output.show_toast('Текст скопирован')
    end
end

render = function()
    local definition = {}

    table.insert(definition, {
        type = 'icon',
        icon = 'fa:book-open',
        size = 20,
        color = '#ffcc00',
        gravity = 'center_v',
        margin = '0 0 0 4dp',
    })

    table.insert(definition, {
        type = 'text',
        text = '<b>Текст на день</b>',
        size = 18,
        gravity = 'center_v',
        font_padding = false,
        margin = '0 0 0 6dp',
        tap = open_verse,
    })

    table.insert(definition, { type = 'new_line', top = 1 })

    if loading and not daily_text then
        table.insert(definition, {
            type = 'text',
            text = '%%fa-fw:spinner%% Загрузка...',
            color = '#888888',
            font_padding = false,
            margin = '0 0 0 4dp',
        })

        api.layout.render(definition)
        return
    end

    if error_text and not daily_text then
        table.insert(definition, {
            type = 'text',
            text = '%%fa-fw:triangle-exclamation%% ' .. escape_html(error_text),
            color = '#ff5555',
            font_padding = false,
            margin = '0 0 0 4dp',
        })

        api.layout.render(definition)
        return
    end

    if daily_text then
        table.insert(definition, {
            type = 'text',
            text = '<i>' .. escape_html(daily_text) .. '</i>',
            size = 16,
            font_padding = false,
            margin = '2dp 0 0 4dp',
            tap = open_verse,
            long_tap = copy_verse,
        })
    end

    table.insert(definition, { type = 'new_line', top = 2 })

    table.insert(definition, {
        type = 'button',
        text = '%%fa-fw:book-open%% Открыть',
        color = '#3366cc',
        expand = true,
        tap = open_verse,
    })

    table.insert(definition, { type = 'spacer', width = 2 })

    table.insert(definition, {
        type = 'button',
        text = '%%fa-fw:copy%% Копировать',
        tap = copy_verse,
    })

    api.layout.render(definition)
end

load_text = function()
    loading = true
    error_text = nil

    render()

    api.http.get({
        url = 'https://vasiley.ru/rss/daily-text-ru.xml'
    }, function(response, err)

        loading = false

        if err
            or type(response) ~= 'table'
            or response.code < 200
            or response.code >= 300
            or not response.body
            or response.body == ''
        then
            error_text = 'Ошибка обновления'
            render()
            return
        end

        local title = response.body:match('<item>.-<title>(.-)</title>')

        if title then
            daily_text = decode_html(title)
            error_text = nil
        else
            error_text = 'Текст дня не найден'
        end

        render()
    end)
end

function on_alarm()
    load_text()
end

function on_resume()
    load_text()
end
