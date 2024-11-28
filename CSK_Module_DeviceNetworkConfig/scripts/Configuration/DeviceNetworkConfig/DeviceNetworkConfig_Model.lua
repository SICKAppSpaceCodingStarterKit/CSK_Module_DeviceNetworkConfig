---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the module definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_DeviceNetworkConfig'

local deviceNetworkConfig_Model = {}

-- Check if CSK_UserManagement features can be used if wanted
deviceNetworkConfig_Model.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

-- Check if DataPersistent module can be used if wanted
deviceNetworkConfig_Model.persistentModuleAvailable = CSK_PersistentData ~= nil or false

-- Load script to communicate with the DeviceNetworkConfig_Model interface and give access
-- to the DeviceNetworkConfig_Model object.
-- Check / edit this script to see/edit functions which communicate with the UI
local setDeviceNetworkConfig_ModelHandle = require('Configuration/DeviceNetworkConfig/DeviceNetworkConfig_Controller')
setDeviceNetworkConfig_ModelHandle(deviceNetworkConfig_Model)

--Loading helper functions if needed
deviceNetworkConfig_Model.helperFuncs = require('Configuration/DeviceNetworkConfig/helper/funcs')

deviceNetworkConfig_Model.interfacesTable = {} -- table to hold setup of available ethernet interfaces
deviceNetworkConfig_Model.ping_ip_adress = "" -- IP address to check for ping

deviceNetworkConfig_Model.styleForUI = 'None' -- Optional parameter to set UI style
deviceNetworkConfig_Model.version = Engine.getCurrentAppVersion() -- Version of module

-- Get device type
local typeName = Engine.getTypeName()
if typeName == 'AppStudioEmulator' or typeName == 'SICK AppEngine' then
  deviceNetworkConfig_Model.deviceType = 'AppEngine'
else
  deviceNetworkConfig_Model.deviceType = string.sub(typeName, 1, 7)
end

deviceNetworkConfig_Model.parameters = {}
deviceNetworkConfig_Model.parameters.nameservers = {}; -- Name servers (DNS)

-- Default values for persistent data
-- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
deviceNetworkConfig_Model.parametersName = 'CSK_DeviceNetworkConfig_Parameter' -- name of parameter dataset to be used for this module
deviceNetworkConfig_Model.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to react on UI style change
local function handleOnStyleChanged(theme)
  deviceNetworkConfig_Model.styleForUI = theme
  Script.notifyEvent("DeviceNetworkConfig_OnNewStatusCSKStyle", deviceNetworkConfig_Model.styleForUI)
end
Script.register('CSK_PersistentData.OnNewStatusCSKStyle', handleOnStyleChanged)

---Function to get current setting of ethernet interfaces
local function refreshInterfaces()
  deviceNetworkConfig_Model.interfacesTable = {}
  for _, enum in pairs(Ethernet.Interface.getInterfaces()) do
    local dhcpEnabled, ipAddress, subnetMask, gateway = Ethernet.Interface.getAddressConfig(enum)
    local isLinkActive = Ethernet.Interface.isLinkActive(enum)
    local macAddress = Ethernet.Interface.getMACAddress(enum)
    local interfaceConfig = {}
    interfaceConfig.interfaceName     = enum
    interfaceConfig.dhcp              = dhcpEnabled
    interfaceConfig.macAddress        = macAddress
    interfaceConfig.isLinkActive      = isLinkActive
    interfaceConfig.ipAddress         = ipAddress
    interfaceConfig.subnetMask        = subnetMask
    interfaceConfig.defaultGateway    = gateway
    deviceNetworkConfig_Model.interfacesTable[enum] = interfaceConfig
  end
  return deviceNetworkConfig_Model.interfacesTable
end
deviceNetworkConfig_Model.refreshInterfaces = refreshInterfaces

local function getNetworkDescription()
  if deviceNetworkConfig_Model.interfacesTable ~= {} then
    local jsonInterfacesTable = deviceNetworkConfig_Model.helperFuncs.json.encode(deviceNetworkConfig_Model.interfacesTable)
    return jsonInterfacesTable
  else
    return nil
  end
end
Script.serveFunction("CSK_DeviceNetworkConfig.getNetworkDescription", getNetworkDescription)

local function applyEthernetConfig(interfaceName, dhcpEnabled, ipAddress, subnetMask, gateway)
  if gateway == '' then gateway = nil end
  Ethernet.Interface.setAddressConfig(interfaceName, dhcpEnabled, ipAddress, subnetMask, gateway)
  Ethernet.Interface.applyAddressConfig(interfaceName)
  Parameters.savePermanent()
end
Script.serveFunction("CSK_DeviceNetworkConfig.applyEthernetConfig", applyEthernetConfig)
deviceNetworkConfig_Model.applyEthernetConfig = applyEthernetConfig

--*************************************************************************
--********************** End Function Scope *******************************
--*************************************************************************

return deviceNetworkConfig_Model
