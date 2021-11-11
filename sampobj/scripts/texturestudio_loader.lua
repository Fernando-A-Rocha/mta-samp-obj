--[[
    Original creator: gta191977649
    Edited by: Fernando
]]

Buffer ={
    last_object = nil,
    total = 0,
    curr_filepath = "",
    curr_line = 0,
}

function string.trim(str)
    str = string.gsub(str, "%s+", "")
    return str
end
function string.contains(str,key) 
    return string.match(str, key) ~= nil
end
function isComment(line)
    return string.match(line,"//") ~= nil
end
function isCreateObject(line)
    return string.contains(line,"CreateObject") or string.contains(line,"CreateDynamicObject")
end
function isMaterialText(line) 
    return string.contains(line,"SetDynamicObjectMaterialText") or string.contains(line,"SetObjectMaterialText")
end
function isSetMaterial(line)
    if isMaterialText(line) then return false end
    return string.contains(line,"SetObjectMaterial") or string.contains(line,"SetDynamicObjectMaterial")
end
function isWorldObjectRemovel(line)
    return string.contains(line,"RemoveBuildingForPlayer")
end
function isAddSimpleModel(line)
    return string.contains(line, "AddSimpleModel")
end

function parseCreateObject(code)
    -- get rid of unused syntax
    code = string.gsub(code, "%(", "")
    code = string.gsub(code, "%)", "")
    code = string.gsub(code, ";", "")
    code = string.gsub(code, "CreateObject", "")
    code = string.gsub(code, "CreateDynamicObject", "")
    code = string.trim(code)

    -- get object code
    local b = split(code,',')
    local model = tonumber(b[1])
    local x = tonumber(b[2])
    local y = tonumber(b[3])
    local z = tonumber(b[4])
    local rx = tonumber(b[5])
    local ry = tonumber(b[6])
    local rz = tonumber(b[7])
    local streamDis = b[11] ~= nil and tonumber(b[11]) or nil
    return model,x,y,z,rx,ry,rz,streamDis
end
function parseSetObjectMaterial(code)
    --code = string.gsub(code, "%(", "")
    --code = string.gsub(code, "%)", "")
    code = string.gsub(code, ";", "")
    code = string.gsub(code, "SetObjectMaterial", "")
    code = string.gsub(code, "SetDynamicObjectMaterial", "")
    code = string.trim(code)
    -- get info
    local b = split(code,',')
    local matIndex = tonumber(b[2])
    local model = tonumber(b[3])
    local lib = string.gsub(b[4], "\"", "")
    local txd = string.gsub(b[5], "\"", "")
    local color = string.gsub(b[6], "%)", "")
    color = string.gsub(color, "0x", "")
    return matIndex,model,lib,txd,color
end
function parseRemoveBuildingForPlayer(code)
    code = string.gsub(code, "%(", "")
    code = string.gsub(code, "%)", "")
    code = string.gsub(code, ";", "")
    code = string.gsub(code, "RemoveBuildingForPlayer", "")
    code = string.trim(code)
    local b = split(code,',')

    local model = tonumber(b[2])
    local x = tonumber(b[3])
    local y = tonumber(b[4])
    local z = tonumber(b[5])
    local rad = tonumber(b[6])
    return model, x, y, z, rad
end
function parseAddSimpleModel(code)
    code = string.gsub(code, "%(", "")
    code = string.gsub(code, "%)", "")
    code = string.gsub(code, ";", "")
    code = string.gsub(code, "AddSimpleModel", "")
    code = string.trim(code)
    local b = split(code,',')

    local virtualworld = tonumber(b[1])
    local baseid = tonumber(b[2])
    local newid = tonumber(b[3])
    local dffname = string.gsub(b[4], "\"", "")
    local txdname = string.gsub(b[5], "\"", "")
    return virtualworld, baseid, newid, dffname, txdname
end


function loadTextureStudioMap(filename,int,dim) 
    int = int or 0
    dim = dim or 0
    if fileExists(filename) then 
        local f = fileOpen(filename)
        local str = fileRead(f,fileGetSize(f))
        fileClose(f)
        Buffer.curr_filepath = filename

        Lines = split(str,'\n' )
        local lastObjid = -1
        local obj = nil

        for i = 1, #Lines do
            local line = Lines[i]
            Buffer.curr_line = i

            if not isComment(line) then

                local customModelFailed = nil
                if isAddSimpleModel(line) then
                    local virtualworld, baseid, newid, dffname, txdname = parseAddSimpleModel(line)
                    if virtualworld then
                        if not AddSimpleModel(virtualworld, baseid, newid, dffname, txdname) then
                            customModelFailed = newid
                        end
                    end
                end
                if isCreateObject(line) then
                    local b = split(line,"=")
                    local model,x,y,z,rx,ry,rz,stream = parseCreateObject(b[2])
                    if model and (customModelFailed and customModelFailed ~= model) or (not customModelFailed) then
                        Buffer.last_object = createSAMPObject(model,x,y,z,rx,ry,rz)
                        if isElement(Buffer.last_object) then
                            setElementInterior(Buffer.last_object,int)
                            setElementDimension(Buffer.last_object,dim)
                            Buffer.total = Buffer.total + 1
                        end
                    end
                end
                if isSetMaterial(line) then 
                    local index,model,lib,txd,color = parseSetObjectMaterial(line)
                    if isElement(Buffer.last_object) then 
                        setObjectMaterial(Buffer.last_object,index,model,lib,txd,color)
                    else
                        outputConsole(string.format("[OBJ_MAT]: Set %s on Error.",lib))
                    end
                end
                if isWorldObjectRemovel(line) then 
                    local model,x,y,z,radius = parseRemoveBuildingForPlayer(line)
                    removeWorldModel(model,radius,x,y,z,int)
                end
            end
        end
    else
        return false, filename.." doesn't exist"
    end

    Buffer.total = 0
    Buffer.last_object = nil
    Buffer.curr_filepath = ""
    Buffer.curr_line = 0
    return true
end