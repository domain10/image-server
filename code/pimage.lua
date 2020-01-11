-- 检测路径是否目录
local function is_dir(path)
    if type(path) ~= "string" then
        return false
     end
    local response = os.execute("cd " .. path)
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

local gm_path = 'gm '
-- check image dir
if not is_dir(getFileDir(ngx.var.img_thumb_path)) then
    os.execute("mkdir -p " .. getFileDir(ngx.var.img_thumb_path))
end
-- 等比缩放
if (file_exists(ngx.var.img_path)) then
    local cmd,mode,logo_url
    mode = string.sub(ngx.var.p_image,1,1)
    logo_url = getFileDir(ngx.var.img_path) .. '/' .. string.sub(ngx.var.p_image,2) .. '.'.. ngx.var.img_ext
    if ('l'==mode) then
        cmd = gm_path .. 'composite -geometry 100x100+10+10 -dissolve 50 ' .. logo_url ..' '
    elseif ('b'==mode) then
        if (ngx.var.img_ext=="gif" or ngx.var.img_ext=="GIF") then
            logo_url = '"'.. logo_url ..'[0]"'
        end
        cmd = gm_path .. 'composite -geometry 100x100% -dissolve 10 ' .. logo_url .. ' '
    else
        ngx.exit(ngx.HTTP_NOT_FOUND)
    end
    cmd = cmd .. ngx.var.img_path .. ' '
    cmd = cmd .. ngx.var.img_thumb_path
    --ngx.say(cmd)
    ngx.log(ngx.INFO, cmd);
    os.execute(cmd)
    ---A---
    cmd = gm_path ..'convert '
    if (ngx.var.watermark ~= nil) then
        cmd = cmd .."-fill white -pointsize 1 -draw \"text 10,10 '" .. ngx.var.watermark .. "'\" "
    end
    cmd = cmd .. ngx.var.img_thumb_path .. ' '
    if (ngx.var.img_width ~= '') then
        cmd = cmd ..'-resize '.. ngx.var.img_width ..'x'.. ngx.var.img_height .. ngx.var.img_resize_type ..' +profile "*" '
    end
    cmd = cmd .. ngx.var.img_thumb_path
    ngx.log(ngx.INFO, cmd);
    os.execute(cmd)
    ------
    ngx.exec(ngx.var.uri)
else
    ngx.exit(ngx.HTTP_NOT_FOUND)
end
