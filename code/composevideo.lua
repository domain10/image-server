local cjson = require 'cjson'
--local url = require "socket.url"
local md5 = dofile(ngx.var.libs_path .."/md5.lua");

-- 检测路径是否目录
local function mk_dir(path)
    local response = os.execute("test -d " .. path)
    if response == 0 then
        return true
    end
    os.execute("mkdir -p " .. path)
    return true
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

local function getUrlPath(url)
    local url = string.gsub(url, "//", "", 1)
    local pos = string.find(url, '/')
    return string.sub(url, pos)
end

local function checkHasAudio(file)
    local cmd = "ffmpeg -i ".. file .." 2>&1 | grep 'Audio:'"
    local handle = io.popen(cmd)
    local str = handle:read("*a")
    handle:close()
    if str == '' then
        return false
    else
        return true
    end
end

local function downFile(rurl, spath)
    local _,name,suffix = getDirFileInfo(rurl)
    name = spath .. name .. suffix
    local cmd = "wget -q -O '".. name .."' '".. rurl .."'"
    local res = os.execute(cmd)
    if res ~= 0 then
        name = ''
    end
    return name
end

local function composeVideo()
    ngx.req.read_body();
    local args = cjson.decode(ngx.req.get_body_data())
    local respData = {}
    local fullDir,outDir,cmd,tmpName,outName = '','','','',''
    local osufDir = 'video_multilingual'
    if #args > 5 then
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    for _, data in pairs(args) do
        local uPath = getUrlPath(data["video"])
        local vDir,vName,suffix = getDirFileInfo(uPath)
        fullDir = ngx.var.root_path .. vDir ..'/'
        outDir = ngx.var.root_path ..'/'.. osufDir .. vDir ..'/'
        mk_dir(outDir)
        
        outName = md5.sumhexa(vName .. data["zm"])
        tmpName = fullDir .. outName ..'tmp'.. suffix
        outName = outName .. suffix
        if file_exists(outDir .. outName) then
            respData[data["zm"]] = { ["path"]=osufDir .. vDir ..'/'.. outName }
        else
            local zmName = downFile(data["zm"], fullDir)
            data["audio"] = downFile(data["audio"], fullDir)
            if zmName == '' then
                respData[data["zm"]] = { ["error"]="Failed to obtain subtitles" }
            elseif data["audio"] == '' then
                respData[data["zm"]] = { ["error"]="Failed to obtain audio" }
            else
                cmd = 'ffmpeg -i '.. fullDir .. vName .. suffix .." -i '".. data["audio"] .."'"
                if checkHasAudio(fullDir .. vName .. suffix) then
                    cmd = cmd ..' -filter_complex "[1:a]volume=3[a1];[0:a][a1]amix=inputs=2:duration=first[a]" -map 0:v -map "[a]" -c:v copy -c:a aac -y '
                else
                    cmd = cmd ..' -c:v copy -c:a aac -y '
                end
                cmd = cmd .. tmpName
                cmd = cmd ..' && ffmpeg -i '.. tmpName ..' -vf subtitles="'.. zmName ..'" -y ' .. outDir .. outName
                cmd = cmd ..' > /dev/null 2>&1'
                --ngx.log(ngx.INFO, cmd)
                local res = os.execute(cmd)
                if res ~= 0 then
                    respData[data["zm"]] = { ["error"]="Synthesis failed" }
                else
                    respData[data["zm"]] = { ["path"]=osufDir .. vDir ..'/'.. outName }
                end
                os.remove(tmpName)
                os.remove(zmName)
                os.remove(data["audio"])
            end
        end
    end
    ngx.header['Content-Type'] = 'application/json; charset=utf-8'
    return ngx.print(cjson.encode(respData))
end

composeVideo()
