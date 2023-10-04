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

-- 获取目录文件名后缀
local function getDirFileInfo(filename)
    return string.match(filename, "(.+)/([^/]+)(%.%w+)$")
end