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

-- Function to load DateTime APIs
local function loadDateTimeAPIs()
  -- If you want to check for specific APIs/functions supported on the device the module is running, place relevant APIs here
  DateTime = require 'API.DateTime'
end

availableAPIs.default = xpcall(loadAPIs, debug.traceback) -- TRUE if all default APIs were loaded correctly
availableAPIs.specific = xpcall(loadSpecificAPIs, debug.traceback) -- TRUE if all specific APIs were loaded correctly
availableAPIs.dateTime = xpcall(loadDateTimeAPIs, debug.traceback) -- TRUE if DateTime API was loaded correctly

return availableAPIs
--**************************************************************************