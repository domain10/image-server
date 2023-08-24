-- 检测路径是否目录
local function is_dir(path)
    if type(path) ~= "string" then
        return false
    end
    local response = os.execute("test -d " .. path)
    if response == 0 then
        return true
    end
    return false
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

-- 获取文件路径
local function getFileDir(filename)
    return string.match(filename, "(.+)/[^/]*%.%w+$")
end

-- 检查图片文件
local function check_picture(filename)
    local result = nil
    local mime = {["FFD8FF"] = "jpg", ["89504E"] = "png", ["474946"] = "gif"}
    local f = io.open(filename, "rb")
    if f ~= nil then
        local str = f:read(3)
        f:close()
        if str == nil then
            return false
        end

        local iden = "", val
        for _, b in ipairs{string.byte(str, 1, -1)} do
            val = string.format("%02X", b)
            iden = iden..val
        end
        if mime[iden] == nil then
            result = false
            os.remove(filename)
        else
            result = true
        end
    end
	return result
end

-- 拉取源图片
local function request_source(img, isRem)
    local imgDir = getFileDir(img)
    local url = ""
    if not is_dir(imgDir) then
        os.execute("mkdir -p " .. imgDir)
    end
    if ngx.var.source_url ~= nil then
        url = ngx.var.source_url
    end
    if url ~= "" then
        if isRem then
            os.remove(img)
        end
        local tmp_path = string.sub(img, string.len(ngx.var.root_path) + 1)
        local cmd = "curl --connect-timeout 30 -o ".. img .." ".. url .. tmp_path
        os.execute(cmd)
        if string.lower(ngx.var.img_ext) ~= "mp4" and check_picture(img) == false then
            ngx.exit(ngx.HTTP_NOT_FOUND)
        end
    end
end

local function handleVideo()
    local cmd = "ffmpeg -i ".. ngx.var.img_path .." 2>&1 | grep 'Duration' | cut -d ' ' -f 4 | sed s/,//"
    local handle = io.popen(cmd)
    local str = handle:read("*a")
    handle:close()
    local timeArr = {}
    local i = 0
    math.randomseed(tostring(os.time()):reverse():sub(1,7))
    for ma in string.gmatch(str ..":", "(.-):") do
        i = i+1
        if i == 3 then
            ma = tonumber(ma)
            if ma > 30 then
                ma = ma - math.random(3, 6)
            elseif ma > 20 then
                ma = ma - math.random(1, 3)
            elseif ma > 10 then
                ma = ma - 1
            end
        end
        table.insert(timeArr, ma)
    end
    local eTime = table.concat(timeArr, ':')
    local watermark = ''
    if eTime ~= nil then
        eTime = '-t ' .. eTime ..' '
    end
    if (ngx.var.watermark ~= nil) then
        watermark = string.sub(ngx.var.watermark, 2)
    end

    cmd = "ffmpeg -i " .. ngx.var.img_path .. " -vf drawtext=text='".. watermark .."':x=0:y=20:fontsize=1:fontcolor=white -y -c:v libx264 "
    cmd = cmd .. '-ss 00:00:00 '.. eTime
    cmd = cmd .. ngx.var.img_thumb_path
    cmd = cmd .. ' > /dev/null 2>&1'
    local res = os.execute(cmd)
    local args = ngx.req.get_uri_args()

    --ngx.log(ngx.INFO, args["no_return"]);
    --ngx.log(ngx.INFO, cmd);
    if args["no_return"] ~= nil then
        if res ~= 0 then
            ngx.exit(ngx.HTTP_BAD_REQUEST)
        else
            ngx.exit(ngx.HTTP_NO_CONTENT)
        end
    else
        if res ~= 0 then
            ngx.exec(string.sub(ngx.var.img_path, string.len(ngx.var.root_path) + 1))
        else
            ngx.exec(ngx.var.uri)
        end
    end
end
----------------------

local gm_path = 'gm'
-- check image dir
if not is_dir(getFileDir(ngx.var.img_thumb_path)) then
    os.execute("mkdir -p " .. getFileDir(ngx.var.img_thumb_path))
end
-- 先检查下
local existed = false
if file_exists(ngx.var.img_path) then
    existed = true
else
    request_source(ngx.var.img_path,false)
end
-- 等比缩放
if (existed or file_exists(ngx.var.img_path)) then
    if (string.lower(ngx.var.img_ext) == "mp4") then
        -- A --
        return handleVideo()
        -- return ngx.exec(string.sub(ngx.var.img_path, string.len(ngx.var.root_path) + 1))
    end

    local cmd
    cmd = gm_path .. ' convert '
    if (ngx.var.watermark ~= nil) then
        ngx.var.watermark = string.sub(ngx.var.watermark,2)
        local text = " -fill white -pointsize 1 -draw \"text 10,10 '" .. ngx.var.watermark .. "'\" "
        cmd = cmd .. text
    end 
    if (ngx.var.img_ext=="gif" or ngx.var.img_ext=="GIF") and ngx.var.img_ext ~="gif" then
        cmd = cmd .. '\''..ngx.var.img_path..'[0]'..'\''
    else
        cmd = cmd .. ngx.var.img_path .. " "
    end
    if (ngx.var.img_width ~= '') then
        cmd = cmd .." -resize "..ngx.var.img_width.."x" ..ngx.var.img_height..ngx.var.img_resize_type.." +profile \"*\" "
    end
    cmd = cmd .. ngx.var.img_thumb_path
    --ngx.say(cmd);
    --ngx.log(ngx.INFO, cmd);
    local res = os.execute(cmd);
    if existed and res ~= 0 then
        request_source(ngx.var.img_path,true);
        os.execute(cmd);
    end

    --local args = ngx.req.get_uri_args();
    --if args["com_num"] ~= nil then
    --    local composeimg = require "composeimg";
    --    return composeimg:handlePic(ngx.var.img_thumb_path, args["com_num"]);
    --end
    if args["no_return"] ~= nil then
        ngx.exit(ngx.HTTP_NO_CONTENT);
    else
        ngx.exec(ngx.var.uri);
    end
else
    ngx.exit(ngx.HTTP_NOT_FOUND);
end
