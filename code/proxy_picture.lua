--
local cjson_safe = require 'cjson';
local http = require 'resty.http';

-- http请求
local function my_http(url, request_body)
	local hc = http:new()
	local ok, code, headers, status, body  = hc:request {
        url = url,
    --- proxy = "http://127.0.0.1:8888",
    --- timeout = 3000,
	--- scheme = 'https',
        method = "POST",
        headers = {["Content-Type"] = "application/x-www-form-urlencoded",["Content-Length"] = #request_body},
        body = request_body,
    }
    if body then
        return body
    else
        ngx.say(code)
        ngx.exit(ngx.HTTP_OK)
    end
end

-- 获取token
local function get_tokens()
	local tokens = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOjEsImV4cCI6MTU1ODE2ODM5MiwiYXVkIjoiIiwibmJmIjoxNTU4MDgxOTkyLCJpYXQiOjE1NTgwODE5OTIsImp0aSI6IjVjZGU3MWM4ZTA0NWY3LjM2OTMwODI5IiwidXNlcl9pZCI6NTAwNSwicmVhbG5hbWUiOiJcdTgwNDJcdTViOTdcdTVmYjciLCJ1c2VybmFtZSI6Im56ZDU2NTgiLCJzZXJ2ZXJfdHlwZSI6IiJ9.c07662e028bef3cc3bec38018eb8efb70f6748556bbc7e238ea94cc63c4a3ac6"
	---
	local token_url = "https://127.0.0.1/post?url=automationLoginUser"
	--login_account
    return tokens
end

-- 获取代理服务
local function get_proxy(shop_id)
	local proxy_url = "https://127.0.0.1/post?url=accountProxy&referer=shop_proxy"
	--local data = 'tokens='.. tokens ..'&shop_id='.. shop_id
	local data = "code=shop_proxy&shop_id=".. shop_id
    return my_http(proxy_url,data)
end

-- 文件是否存在
local function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
         io.close(f)
         return true
    else
        return false
    end
end

--
local function echo_image(file, ext)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    ngx.header.content_type = "image/".. ext
    ngx.print(content)
    ngx.exit(ngx.HTTP_OK)
end
--

local args = ngx.var.args
local data,cmd,pic_path_name
if args then
	args = ngx.unescape_uri(args)
	data = ngx.decode_args(args)
	--token = get_tokens()
	if(data['id'] and data['url']) then
		local pic_name = ngx.md5(data['url'])--string.match(data['url'], ".+/([^/]*%.%w+)$")
		local ext_name = string.match(data['url'], ".+%.(%w+)$")
		pic_path_name = ngx.var.pic_path ..'/'.. pic_name ..'.'.. ext_name
		if file_exists(pic_path_name) then
			echo_image(pic_path_name, ext_name)
		else
			proxy_data = get_proxy(data['id'])
			if proxy_data then
				local tmp = cjson_safe.decode(proxy_data)
				if tmp['account'] and tmp['account']['proxy_ip'] then
					cmd = 'curl -x '.. tmp['account']['proxy_ip'] ..':'.. tmp['account']['proxy_port'] ..' -U '.. tmp['account']['proxy_user_name'] ..':'.. tmp['account']['proxy_user_password'] ..' -A "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1500.55 Safari/537.36"'
					cmd = cmd .. ' -o '.. pic_path_name ..' '.. data['url']
					---
					--ngx.say(cmd)
					--ngx.exit(ngx.HTTP_OK)
					---
					os.execute(cmd)
					------
					echo_image(pic_path_name, ext_name)
				else
					ngx.header.content_type = "text/html"
					ngx.say(proxy_data)
				end
			else
				ngx.header.content_type = "text/html"
				ngx.say("Error acquiring proxy information")
			end
		end
	else
		ngx.exit(ngx.HTTP_NOT_FOUND)
	end
else
    ngx.exit(ngx.HTTP_NOT_FOUND)
end