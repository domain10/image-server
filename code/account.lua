local function splitName(str, len)
    local count = #str
    local name1 = ''
    local name2 = ''
    if (count > 2*len) then
        len = 2 * len
        for i = 1, count, 1 do
            if (i % 2 == 1 or i > len) then
                name1 = name1 .. string.sub(str, i, i)
            else
                name2 = name2 .. string.sub(str, i, i)
            end
        end
    else 
        len = (count - len) * 2
        for i = 1, count, 1 do
            if (i % 2 == 1 and  i < len) then
                name1 = name1 .. string.sub(str, i, i)
            else
                name2 = name2 .. string.sub(str, i, i)
            end
        end
    end
    return name1,name2
end

local function getPath(str)
    local path = ''
    for i = 1, #str, 1 do
        path = path .. string.sub(str, i, i)
        if (i % 3 == 0) then
            path = path .. '/'
        end
    end
    return path
end
---A---
local function split( str,reps )
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function ( w )
        table.insert(resultStrList,w)
    end)
    return resultStrList
end
local tmpStr = ''
local list = split(ngx.var.account_name,'_')
if (#list > 1) then
    ngx.var.account_name = list[1]
    tmpStr = '_'.. list[2]
end
------
local account_name,id,file_name,path,prefix
account_name,id = splitName(ngx.var.account_name, 6)
_,file_name = splitName(ngx.var.file_name, 32)
prefix = string.sub(account_name, 1, 4)
if (prefix == 'self') then
    path = '/' .. prefix .. '/'
    account_name = string.sub(account_name, 5)
else
    path = '/'
end
---A---
account_name = account_name .. tmpStr
------
path = path .. getPath(id) .. file_name .. ngx.var.tail
if (account_name ~= '') then
    path = path .. '-' .. account_name .. ngx.var.ext
else
    path = path .. ngx.var.ext
end
ngx.var.account_name = nil
ngx.var.file_name = nil
ngx.var.tail = nil
ngx.var.ext = nil
return ngx.exec(path)
