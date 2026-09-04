-- name = "Текст на день"
-- description = "Показывает ежедневный библейский стих"
-- data_source = "https://vasiley.ru/rss/daily-text-ru.xml"
-- type = "widget"
-- lang = "ru"
-- author = "Vasiliy"
-- version = "1.4"
-- foldable = "false"

local feed_url = "https://vasiley.ru/rss/daily-text-ru.xml"
local wol_url = "https://wol.jw.org/ru/wol/h/r2/lp-u"

local daily_text = nil
local stale = false

local function decode_html(text)
    text = tostring(text or "")
    text = text:gsub("<!%[CDATA%[", "")
    text = text:gsub("%]%]>", "")
    text = text:gsub("&quot;", '"')
    text = text:gsub("&#34;", '"')
    text = text:gsub("&apos;", "'")
    text = text:gsub("&#39;", "'")
    text = text:gsub("&lt;", "<")
    text = text:gsub("&gt;", ">")
    text = text:gsub("&amp;", "&")
    return text
end

local function escape_html(text)
    text = tostring(text or "")
    text = text:gsub("&", "&amp;")
    text = text:gsub("<", "&lt;")
    text = text:gsub(">", "&gt;")
    return text
end

local function draw()
    if daily_text ~= nil and daily_text ~= "" then
        local text = "<i>" .. escape_html(daily_text) .. "</i>"
        if stale then
            text = "<font color=\"#ff9800\">⚠ Не удалось обновить данные. Показан последний полученный текст.</font>\n" .. text
        end
        ui:show_text(text)
    elseif stale then
        ui:show_text("⚠ Не удалось получить текст на день")
    else
        ui:show_text("Загрузка...")
    end
end

local function load_text()
    http:get(feed_url)
end

function on_alarm()
    load_text()
end

function on_resume()
    load_text()
end

function on_network_result(result, code)
    if code >= 200 and code < 300 and result ~= nil and result ~= "" then
        local title = result:match("<item>.-<title>(.-)</title>")
        if title ~= nil and title ~= "" then
            daily_text = decode_html(title)
            stale = false
            draw()
            return
        end
    end

    stale = true
    draw()
end

function on_network_error(error)
    stale = true
    draw()
end

function on_click()
    system:open_browser(wol_url)
end

function on_long_click()
    if daily_text ~= nil and daily_text ~= "" then
        system:to_clipboard(daily_text)
        ui:show_toast("Текст скопирован")
    end
    return true
end
