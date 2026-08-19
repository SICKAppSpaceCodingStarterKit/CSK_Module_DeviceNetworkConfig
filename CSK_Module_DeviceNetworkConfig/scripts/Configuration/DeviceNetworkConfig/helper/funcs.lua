---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find helper functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

local nameOfModule = 'CSK_DeviceNetworkConfig'

local funcs = {}
-- Default parameters for instances of module
funcs.defaultParameters = require('Configuration/DeviceNetworkConfig/DeviceNetworkConfig_Parameters')
-- Providing standard JSON functions
funcs.json = require('Configuration/DeviceNetworkConfig/helper/Json')

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Convert subnet mask to bit value (e.g. "255.255.255.0" -> 24)
---@param mask string Subnetmask string
---@return int bitValue Subnet mask as bit value
local function maskToBitValue(mask)
    local bitValue = 0
    local binaryMask = ""

    local count = 0

    for octet in string.gmatch(mask, "(%d+)") do
        octet = tonumber(octet)
        count = count + 1

        -- Check range 0–255
        if not octet or octet < 0 or octet > 255 then
            return nil, "Invalid octet value"
        end

        -- Convert octet to 8-bit binary string
        local bin = ""
        for i = 7, 0, -1 do
            if octet >= 2^i then
                bin = bin .. "1"
                octet = octet - 2^i
            else
                bin = bin .. "0"
            end
        end

        binaryMask = binaryMask .. bin
    end

    -- Must have exactly 4 octets
    if count ~= 4 then
        return nil, "Invalid mask format"
    end

    -- Check contiguous ones (valid subnet mask rule)
    -- Must match: 111...1100...00
    if not binaryMask:match("^1*0*$") then
        return nil, "Mask is not contiguous"
    end

    -- Count bits set to 1
    local _, ones = binaryMask:gsub("1", "")
    bitValue = ones

    return bitValue
end
funcs.maskToBitValue = maskToBitValue

-- Convert bit value to subnet mask (e.g. 24 -> "255.255.255.0")
---@param bitValue int Subnet mask as bit value
---@return string mask Subnetmask string
local function bitValueToMask(bitValue)
  assert(type(bitValue) == "number" and bitValue >= 0 and bitValue <= 32, "Invalid Bit value")

  local mask = {}

  for i = 1, 4 do
      if bitValue >= 8 then
          table.insert(mask, "255")
          bitValue = bitValue - 8
      elseif bitValue > 0 then
          local value = 256 - 2^(8 - bitValue)
          table.insert(mask, tostring(math.floor(value)))
          bitValue = 0
      else
          table.insert(mask, "0")
      end
  end

  return table.concat(mask, ".")
end
funcs.bitValueToMask = bitValueToMask

--- Function to check if inserted string is a valid IP
---@param ip string String to check for IP
---@return boolean status Result if IP is valid
local function checkIP(ip)
  if not ip then return false end
  local a,b,c,d=ip:match("^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$")
  a=tonumber(a)
  b=tonumber(b)
  c=tonumber(c)
  d=tonumber(d)
  if not a or not b or not c or not d then return false end
  if a<0 or 255<a then return false end
  if b<0 or 255<b then return false end
  if c<0 or 255<c then return false end
  if d<0 or 255<d then return false end
  return true
end
funcs.checkIP = checkIP

--- Function to sort keys of table
---@param content any[] Table to sort
---@return any[] tableKeys Sorted table
local function getSortedTableKeys(content)
  local tableKeys = {}
  for key,_ in pairs(content) do
    table.insert(tableKeys, key)
  end
  table.sort(tableKeys)
  return tableKeys
end

--- Function to get content list as JSON string
---@param data string[] Table with data entries
---@return string sortedTable Sorted entries as JSON string
local function createJsonList(data)
  local sortedTable = {}
  for _, value in pairs(data) do
    table.insert(sortedTable, value)
  end
  table.sort(sortedTable)
  return funcs.json.encode(sortedTable)
end
funcs.createJsonList = createJsonList

--- Function to create a json string out of a table content
---@param content string[] Content to use
---@param selection int? Currently selected parameter
---@return string jsonstring Json list of entries
local function createSpecificJsonList(content, selection)
  if selection == nil then
    selection = 0
  end
  local contentList = {}
  if content == nil then
    contentList = {
                    {
                      Interface       = '-',
                      IP              = '-',
                      SubnetMask      = '-',
                      DefaultGateway  = '-',
                      DHCP            = '-',
                      MACAddress      = '-',
                      Connected       = '-'
                    },
                  }
  else
      local sortedTableKeys = getSortedTableKeys(content)
      for _, tableKey in ipairs(sortedTableKeys) do
        local isSelected = false
        if tableKey == selection then
          isSelected = true
        end
        table.insert(contentList, 
                      { 
                        Interface       = content[tableKey].interfaceName,
                        IP              = content[tableKey].ipAddress,
                        SubnetMask      = content[tableKey].subnetMask,
                        DefaultGateway  = content[tableKey].defaultGateway,
                        DHCP            = content[tableKey].dhcp,
                        MACAddress      = content[tableKey].macAddress,
                        Connected       = content[tableKey].isLinkActive,
                        selected        = isSelected
                      }
                    )
      end
  end

  local jsonstring = deviceNetworkConfig_Model.helperFuncs.json.encode(contentList)
  return jsonstring
end
funcs.createSpecificJsonList = createSpecificJsonList

--- Function to create a list with numbers
---@param size int Size of the list
---@return string list List of numbers
local function createStringListBySize(size)
  local list = "["
  if size >= 1 then
    list = list .. '"' .. tostring(1) .. '"'
  end
  if size >= 2 then
    for i=2, size do
      list = list .. ', ' .. '"' .. tostring(i) .. '"'
    end
  end
  list = list .. "]"
  return list
end
funcs.createStringListBySize = createStringListBySize

--- Function to convert a table into a Container object
---@param content auto[] Lua Table to convert to Container
---@return Container cont Created Container
local function convertTable2Container(content)
  local cont = Container.create()
  for key, value in pairs(content) do
    if type(value) == 'table' then
      cont:add(key, convertTable2Container(value), nil)
    else
      cont:add(key, value, nil)
    end
  end
  return cont
end
funcs.convertTable2Container = convertTable2Container

--- Function to convert a Container into a table
---@param cont Container Container to convert to Lua table
---@return auto[] data Created Lua table
local function convertContainer2Table(cont)
  local data = {}
  local containerList = Container.list(cont)
  local containerCheck = false
  if tonumber(containerList[1]) then
    containerCheck = true
  end
  for i=1, #containerList do

    local subContainer

    if containerCheck then
      subContainer = Container.get(cont, tostring(i) .. '.00')
    else
      subContainer = Container.get(cont, containerList[i])
    end
    if type(subContainer) == 'userdata' then
      if Object.getType(subContainer) == "Container" then

        if containerCheck then
          table.insert(data, convertContainer2Table(subContainer))
        else
          data[containerList[i]] = convertContainer2Table(subContainer)
        end

      else
        if containerCheck then
          table.insert(data, subContainer)
        else
          data[containerList[i]] = subContainer
        end
      end
    else
      if containerCheck then
        table.insert(data, subContainer)
      else
        data[containerList[i]] = subContainer
      end
    end
  end
  return data
end
funcs.convertContainer2Table = convertContainer2Table

--- Function to compare table content. Optionally will fill missing values within content table with values of defaultTable
---@param content auto Data to check
---@param defaultTable auto Reference data
---@return auto[] content Update of data
local function checkParameters(content, defaultTable)
  for key, value in pairs(defaultTable) do
    if type(value) == 'table' then
      if content[key] == nil then
        _G.logger:info(nameOfModule .. ": Created missing parameters table '" .. tostring(key) .. "'")
        content[key] = {}
      end
      content[key] = checkParameters(content[key], defaultTable[key])
    elseif content[key] == nil then
      _G.logger:info(nameOfModule .. ": Missing parameter '" .. tostring(key) .. "'. Adding default value '" .. tostring(defaultTable[key]) .. "'")
      content[key] = defaultTable[key]
    end
  end
  return content
end
funcs.checkParameters = checkParameters

return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************