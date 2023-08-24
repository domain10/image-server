local _M = {};


-- 获取目录文件名后缀
local function _getDirFileInfo(filename)
    return string.match(filename, "(.+)/([^/]+)(%.%w+)$")
end

-- 文件是否存在
local function _file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

-- 分割字符串
local function _split(str, reps, num)
    local result = {}
    local i = 0
    while true do 
        local pos = string.find(str, reps)
        if (not pos) then
      	    table.insert(result,str)
            break
        end
        table.insert(result, string.sub(str, 1, pos-1))
        i = i+1
        if (num~= nil and num>0 and num <= i) then
            table.insert(result,string.sub(str, pos+1))
            break
        end
        str = string.sub(str, pos+1)
    end
    return result
end

-- 获取图片信息
local function _getImageInfo(img)
    local cmd = "gm identify ".. img
    local handle = io.popen(cmd)
    local str = handle:read("*a")
    local result = {}
    local xValue,yValue
    handle:close()

    local list = _split(str, ' ')
    if (#list > 2) then
        xValue = string.match(list[3], '(%d+)x')
        yValue = string.match(list[3], 'x(%d+)%+')
    end
    if xValue ~= nil then
        result[1] = tonumber(xValue)
    end
    if yValue ~= nil then
        result[2] = tonumber(yValue)
    end
    return result
end

--
function _M:handlePic(img, num)
    num = tonumber(num);
    if num == nil or num<2 or num>10 then
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    local xyList = _getImageInfo(img);
    local xValue = '';
    local cmd = 'gm montage +frame +shadow +label ';
    local imgDir,tmpName,suffix = _getDirFileInfo(img);
    local nameOne = tmpName;
    local nameTwo,cStr = '','';
    local nameArr = _split(tmpName, '_', 1);
    if #nameArr>1 then
        nameOne = nameArr[1];
        nameTwo = nameArr[2];
        cStr = '_';
    else
        nameArr = _split(tmpName, '-', 1);
        if #nameArr>1 then
            nameOne = nameArr[1];
            nameTwo = nameArr[2];
            cStr = '-';
        end
    end

    if (num == 2) then
        xValue = math.ceil(xyList[1] / 2)
        cmd = cmd ..'-tile 2x1 -geometry '.. xValue ..'x'.. xyList[2] ..'+0+0 -page '.. xyList[1] ..'x'.. xyList[2]
    	cmd = cmd ..' '.. img ..' '.. img
        nameOne = nameOne ..'02'
    elseif (num == 3) then
        xValue = math.ceil(xyList[1] / 3)
        cmd = cmd ..'-tile 3x1 -geometry '.. xValue ..'x'.. xyList[2] ..'+0+0 -page '.. xyList[1] ..'x'.. xyList[2]
    	cmd = cmd ..' '.. img ..' '.. img ..' '.. img
        nameOne = nameOne ..'03'
    elseif (num == 4) then
        xValue = math.ceil(xyList[1] / 2)
        local yValue = math.ceil(xyList[2] / 2)
        cmd = cmd ..'-tile 2x2 -geometry '.. xValue ..'x'.. yValue ..'+0+0 -page '.. xyList[1] ..'x'.. xyList[2]
    	cmd = cmd ..' '.. img ..' '.. img ..' '.. img ..' '.. img
        nameOne = nameOne ..'04'
    elseif (num == 5) then
        xValue = math.ceil(xyList[1] / 3)
        local yValue = math.ceil(xyList[2] / 2)
        cmd = cmd ..'-tile 3x2 -geometry '.. xValue ..'x'.. yValue ..'+0+0! -page '.. xyList[1] ..'x'.. xyList[2]
    	cmd = cmd ..' '.. img ..' '.. img ..' '.. img ..' '.. img ..' '.. img
        nameOne = nameOne ..'05'
    elseif (num == 6) then
        xValue = math.ceil(xyList[1] / 3)
        local yValue = math.ceil(xyList[2] / 2)
        cmd = cmd ..'-tile 3x2 -geometry '.. xValue ..'x'.. yValue ..'+0+0! -page '.. xyList[1] ..'x'.. xyList[2]
    	cmd = cmd ..' '.. img ..' '.. img ..' '.. img ..' '.. img ..' '.. img ..' '.. img
        nameOne = nameOne ..'06'
    elseif (num == 7) then
        xValue = math.ceil(xyList[1] / 3)
        local yValue = math.ceil(xyList[2] / 3)
        cmd = cmd ..'-tile 3x3 -geometry '.. xValue ..'x'.. yValue ..'+0+0! -page '.. xyList[1] ..'x'.. xyList[2]
    	cmd = cmd ..' '.. img ..' '.. img ..' '.. img ..' NULL:' ..' '.. img
        cmd = cmd ..' NULL:'..' '.. img ..' '.. img ..' '.. img
        nameOne = nameOne ..'07'
    elseif (num == 8) then
        xValue = math.ceil(xyList[1] / 4)
        local yValue = math.ceil(xyList[2] / 2)
        cmd = cmd ..'-tile 4x2 -geometry '.. xValue ..'x'.. yValue ..'+0+0! -page '.. xyList[1] ..'x'.. xyList[2]
    	cmd = cmd ..' '.. img ..' '.. img ..' '.. img ..' '.. img ..' '.. img
        cmd = cmd ..' '.. img ..' '.. img ..' '.. img
        nameOne = nameOne ..'08'
    elseif (num == 9) then
        xValue = math.ceil(xyList[1] / 3)
        local yValue = math.ceil(xyList[2] / 3)
        cmd = cmd ..'-tile 3x3 -geometry '.. xValue ..'x'.. yValue ..'+0+0! -page '.. xyList[1] ..'x'.. xyList[2]
    	cmd = cmd ..' '.. img ..' '.. img ..' '.. img ..' '.. img ..' '.. img
        cmd = cmd ..' '.. img ..' '.. img ..' '.. img ..' '.. img
        nameOne = nameOne ..'09'
    elseif (num == 10) then
        xValue = math.ceil(xyList[1] / 5)
        local yValue = math.ceil(xyList[2] / 2)
        cmd = cmd ..'-tile 5x2 -geometry '.. xValue ..'x'.. yValue ..'+0+0! -page '.. xyList[1] ..'x'.. xyList[2]
        cmd = cmd ..' '.. img ..' '.. img ..' '.. img ..' '.. img ..' '.. img
        cmd = cmd ..' '.. img ..' '.. img ..' '.. img ..' '.. img ..' '.. img
        nameOne = nameOne ..'10'
    else
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    local args = ngx.req.get_uri_args();
    if (args['na'] ~= nil and args['na'] ~= '') then
        nameOne = args['na'];
    end
    tmpName = imgDir .. '/' .. nameOne .. cStr .. nameTwo .. suffix;
    if _file_exists(tmpName) then
        ngx.exit(ngx.HTTP_NO_CONTENT);
    end
    --ngx.log(ngx.INFO, cmd .. ' ' .. tmpName);
    local res = os.execute(cmd .. ' ' .. tmpName);
    if res == 0 then
        ngx.exit(ngx.HTTP_NO_CONTENT);
    else
        ngx.exit(ngx.HTTP_NOT_FOUND);
    end
end

return _M;