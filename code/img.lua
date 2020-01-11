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

-- 拉取源图片
local function request_source(img)
    local imgDir = getFileDir(img)
    local url = ""
    if not is_dir(imgDir) then
        os.execute("mkdir -p " .. imgDir)
    end
    if ngx.var.source_url ~= nil then
        url = ngx.var.source_url
    end
    if url ~= "" then
        local tmp_path = string.sub(img, string.len(ngx.var.root_path) + 1)
        local cmd = "curl -o ".. img .." ".. url .. tmp_path
        os.execute(cmd)
    end
end
--

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
    request_source(ngx.var.img_path)
end
-- 等比缩放
if (existed or file_exists(ngx.var.img_path)) then
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
    ngx.log(ngx.INFO, cmd);
    os.execute(cmd);
    ngx.exec(ngx.var.uri);
else
    ngx.exit(ngx.HTTP_NOT_FOUND);
end
