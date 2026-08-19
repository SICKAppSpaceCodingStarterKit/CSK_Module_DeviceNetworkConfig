---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

-- Load all relevant APIs for this module
--**************************************************************************

local availableAPIs = {}

-- Function to load all default APIs
local function loadAPIs()
  CSK_DeviceNetworkConfig = require 'API.CSK_DeviceNetworkConfig'

  Log = require 'API.Log'
  Log.Handler = require 'API.Log.Handler'
  Log.SharedLogger = require 'API.Log.SharedLogger'

  Container = require 'API.Container'

  Engine = require 'API.Engine'
  File = require 'API.File'
  Object = require 'API.Object'
  Parameters = require 'API.Parameters'
  Timer = require 'API.Timer'

  -- Check if related CSK modules are available to be used
  local appList = Engine.listApps()
  for i = 1, #appList do
    if appList[i] == 'CSK_Module_PersistentData' then
      CSK_PersistentData = require 'API.CSK_PersistentData'
    elseif appList[i] == 'CSK_Module_UserManagement' then
      CSK_UserManagement = require 'API.CSK_UserManagement'
    end
  end
end

-- Function to load specific APIs
local function loadSpecificAPIs()
  -- If you want to check for specific APIs/functions supported on the device the module is running, place relevant APIs here
  Ethernet = require 'API.Ethernet'
  Ethernet.DNS = require 'API.Ethernet.DNS'
  Ethernet.Interface = require 'API.Ethernet.Interface'
end

local function loadBridgeAPI()
  Ethernet.Bridge = require 'API.Ethernet.Bridge'
end

-- Function to load DateTime APIs
local function loadDateTimeAPIs()
  -- If you want to check for specific APIs/functions supported on the device the module is running, place relevant APIs here
  DateTime = require 'API.DateTime'
end

-- Function to check if set features are not available
local function checkSetFunctionsNotSupported()
  local deviceName = Engine.getTypeName()
  local isSIM300 = string.find(deviceName, 'SIG300') or string.find(deviceName, 'SIM300')
  local isSAE = string.find(deviceName, 'AppEngine') or string.find(deviceName, 'Emulator')
  if isSIM300 or isSAE then
    return true
  else
    return false
  end
end

local function loadHTTPAPI()
  HTTPClient = require 'API.HTTPClient'
  HTTPClient.Request = require 'API.HTTPClient.Request'
  HTTPClient.Response = require 'API.HTTPClient.Response'
end

-- Function to spli firmware version
local function splitByDot(input)
  local result = {}
  for part in string.gmatch(input, "([^%.]+)") do
    table.insert(result, part)
  end
  return result
end

-- Function to check if device supports ControlCenter access (so far only SIM2000ST-E support with firmware >=1.18)
local function checkControlCenterAccess()
  local deviceType = Engine.getTypeCode()
  local firmware = Engine.getFirmwareVersion()

  local firmwareVersion = splitByDot(firmware)
  local isSIM2000STE = string.find(deviceType, 'SIM2000%-3')

  if isSIM2000STE then
    if tonumber(firmwareVersion[1]) >= 2 or (tonumber(firmwareVersion[1]) == 1 and tonumber(firmwareVersion[2]) >= 17) then
      availableAPIs.bridge = true
      return true
    else
      return false
    end
  else
    return false
  end
end

availableAPIs.default = xpcall(loadAPIs, debug.traceback) -- TRUE if all default APIs were loaded correctly
availableAPIs.specific = xpcall(loadSpecificAPIs, debug.traceback) -- TRUE if all specific APIs were loaded correctly
availableAPIs.bridge = xpcall(loadBridgeAPI, debug.traceback) -- TRUE if all specific APIs were loaded correctly
availableAPIs.dateTime = xpcall(loadDateTimeAPIs, debug.traceback) -- TRUE if DateTime API was loaded correctly
availableAPIs.noSetSupport = checkSetFunctionsNotSupported() -- TRUE if set function are not supported
availableAPIs.http = xpcall(loadHTTPAPI, debug.traceback) -- TRUE if HTTP API was loaded correctly
availableAPIs.accessCC = checkControlCenterAccess() -- TRUE if device = SIM2000ST-E and firmware >= 1.18

return availableAPIs
--**************************************************************************