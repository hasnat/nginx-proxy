local LOG_PATH = "/var/log/nginx/logs/"
local FILE_NAME = "request_headers.log"

local function url_starts_with_on_of(request_uri, urls)
    for i, Start in ipairs(urls) do
        if string.sub(request_uri, 1, string.len(Start)) == Start then
            return true
        end
    end
    return false
end

local function is_valid_url()
    return not url_starts_with_on_of(ngx.var.request_uri, { "/status", "/nginx_status" })
end

local function log_path_prefix()
    return os.date("%Y/%m/%d")
end

local function file_name_suffix()
    return os.date("%Y-%m-%d")
end

local function get_headers()

    local req_headers = {}
    local log_object = {}

    for k, v in pairs(ngx.req.get_headers()) do
        req_headers[k] = v
    end

    req_headers['cookie'] = nil  -- use either this or DAPROPS
    log_object['DAPROPS'] = ngx.var.cookie_DAPROPS

    log_object['time_local'] = ngx.var.time_local
    log_object['status'] = ngx.var.status
    log_object['remote_addr'] = ngx.var.remote_addr
    log_object['remote_user'] = ngx.var.remote_user
    log_object['request_uri'] = ngx.var.request_uri

    log_object['headers'] = req_headers

    return log_object
end

local function write_log_file(file)

    local json = require("/lua/json")

    file:write(json.encode(get_headers()), "\n")
    file:flush()
    file:close()
end

if is_valid_url() then
    local shell = require("resty.shell")

    -- define a table to hold arguments with the following elements:
    --
    -- timeout: timeout for the socket connection
    --
    -- data: STDIN to send to sockproc
    --
    -- socket: either a table containg the elements 'host' and 'port' for tcp connections,
    -- or a string defining a unix socket
    local args = {
        socket = "unix:/tmp/shell.sock",
    }
    local log_path_with_prefix = LOG_PATH .. log_path_prefix()
    --    local status, out, err = shell.execute("mkdir -p " .. log_path_with_prefix, args)
    local status, out, err = shell.execute("mkdir -p " .. log_path_with_prefix, args)

    local file_name_with_suffix = file_name_suffix()  .. "." .. FILE_NAME
    local file, err = io.open(log_path_with_prefix .. "/" .. file_name_with_suffix, "a")

    if file then
        write_log_file(file)
    else
        ngx.log(ngx.STDERR, "Couldn't log to file: " .. err)
    end

end


local LOG_PATH = "/var/log/nginx/logs/"
local FILE_NAME = "request_headers.log"

local function url_starts_with_on_of(request_uri, urls)
    for i, Start in ipairs(urls) do
        if string.sub(request_uri, 1, string.len(Start)) == Start then
            return true
        end
    end
    return false
end

local function is_valid_url()
    return not url_starts_with_on_of(ngx.var.request_uri, { "/status", "/nginx_status" })
end

local function log_path_prefix()
    return os.date("%Y/%m/%d")
end

local function file_name_suffix()
    return os.date("%Y-%m-%d")
end

local function get_headers()

local req_headers = {}

    local req_headers = {}
    local log_object = {}

    for k, v in pairs(ngx.req.get_headers()) do
        req_headers[k] = v
    end

    req_headers['cookie'] = nil  -- not log cookie

    log_object['time_local'] = ngx.var.time_local
    log_object['status'] = ngx.var.status
    log_object['remote_addr'] = ngx.var.remote_addr
    log_object['remote_user'] = ngx.var.remote_user
    log_object['request_uri'] = ngx.var.request_uri

    log_object['headers'] = req_headers

    return log_object
end

local function write_log_file(file)
    local json = require("/lua/lib/lunajson/lunajson.lua")
    file:write(json.encode(get_headers()), "\n")
    file:flush()
    file:close()
end


if is_valid_url() then
    local shell = require("/lua/lib/resty/shell.lua")

    -- define a table to hold arguments with the following elements:
    --
    -- timeout: timeout for the socket connection
    --
    -- data: STDIN to send to sockproc
    --
    -- socket: either a table containg the elements 'host' and 'port' for tcp connections,
    -- or a string defining a unix socket
    local args = {
        socket = "unix:/tmp/shell.sock",
    }
    local log_path_with_prefix = LOG_PATH .. log_path_prefix()
--    local status, out, err = shell.execute("mkdir -p " .. log_path_with_prefix, args)
    local status, out, err = shell.execute("mkdir -p " .. log_path_with_prefix, args)

    local file_name_with_suffix = file_name_suffix()  .. "." .. FILE_NAME
    local file, err = io.open(log_path_with_prefix .. "/" .. file_name_with_suffix, "a")

    if file then
        write_log_file(file)
    else
        ngx.log(ngx.STDERR, "Couldn't log to file: " .. err)
    end

end

