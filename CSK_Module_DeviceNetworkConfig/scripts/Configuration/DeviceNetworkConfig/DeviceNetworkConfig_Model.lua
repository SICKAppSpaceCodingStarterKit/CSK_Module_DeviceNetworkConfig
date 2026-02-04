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

-- Default values for persistent data
-- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
deviceNetworkConfig_Model.parametersName = 'CSK_DeviceNetworkConfig_Parameter' -- name of parameter dataset to be used for this module
deviceNetworkConfig_Model.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

-- Load script to communicate with the DeviceNetworkConfig_Model interface and give access
-- to the DeviceNetworkConfig_Model object.
-- Check / edit this script to see/edit functions which communicate with the UI
local setDeviceNetworkConfig_ModelHandle = require('Configuration/DeviceNetworkConfig/DeviceNetworkConfig_Controller')
setDeviceNetworkConfig_ModelHandle(deviceNetworkConfig_Model)

--Loading helper functions if needed
deviceNetworkConfig_Model.helperFuncs = require('Configuration/DeviceNetworkConfig/helper/funcs')

deviceNetworkConfig_Model.interfacesTable = {} -- table to hold setup of available ethernet interfaces
deviceNetworkConfig_Model.ping_ip_adress = "" -- IP address to check for ping
deviceNetworkConfig_Model.showBridgeFeature = false -- Set status to show bridge feature
deviceNetworkConfig_Model.listOfInterfaces = {} -- List of available ethernet interfaces

deviceNetworkConfig_Model.bridge = nil -- Optional ethernet bridge
deviceNetworkConfig_Model.bridgeDelayTimer = Timer.create()
deviceNetworkConfig_Model.bridgeDelayTimer:setPeriodic(false)
deviceNetworkConfig_Model.bridgeTestTimer = Timer.create()
deviceNetworkConfig_Model.bridgeTestTimer:setPeriodic(false)

for key, value in pairs(Ethernet.Interface.getInterfaces()) do
  table.insert(deviceNetworkConfig_Model.listOfInterfaces, value)
end

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
deviceNetworkConfig_Model.parameters = deviceNetworkConfig_Model.helperFuncs.defaultParameters.getParameters() -- Load default parameters

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

local function createBridge()
  if deviceNetworkConfig_Model.parameters.bridgeTestTime ~= 0 then
    deviceNetworkConfig_Model.bridgeTestTimer:setExpirationTime(deviceNetworkConfig_Model.parameters.bridgeTestTime*60000)
    deviceNetworkConfig_Model.bridgeTestTimer:start()
    _G.logger:info(nameOfModule .. ": Start test timer to stop bridge")
  else
    deviceNetworkConfig_Model.bridgeTestTimer:stop()
  end

  _G.logger:info(nameOfModule .. ": Activate bridge.")

  deviceNetworkConfig_Model.bridge = Ethernet.Bridge.create('EthBridge')
  deviceNetworkConfig_Model.bridge:setStaticAddress(deviceNetworkConfig_Model.parameters.bridgeIP, deviceNetworkConfig_Model.parameters.bridgeSubnetMask, deviceNetworkConfig_Model.parameters.bridgeGateway)
  deviceNetworkConfig_Model.bridge:setInterfaces(deviceNetworkConfig_Model.parameters.bridgeInterfaces)
  local suc = deviceNetworkConfig_Model.bridge:enable()
  CSK_DeviceNetworkConfig.pageCalled()
end
deviceNetworkConfig_Model.createBridge = createBridge
Timer.register(deviceNetworkConfig_Model.bridgeDelayTimer, 'OnExpired', createBridge)

local function deleteBridge()
  _G.logger:info(nameOfModule .. ": Delete bridge.")
  deviceNetworkConfig_Model.parameters.bridgeActive = false

  if deviceNetworkConfig_Model.bridge then
    deviceNetworkConfig_Model.bridge:disable()
  end
  deviceNetworkConfig_Model.bridge = nil
  collectgarbage()

  Script.notifyEvent("DeviceNetworkConfig_OnNewStatusBridgeActive", deviceNetworkConfig_Model.parameters.bridgeActive)
  CSK_DeviceNetworkConfig.pageCalled()
end
deviceNetworkConfig_Model.deleteBridge = deleteBridge
Timer.register(deviceNetworkConfig_Model.bridgeTestTimer, 'OnExpired', deleteBridge)

---Function to get current setting of ethernet interfaces
local function refreshInterfaces()
  deviceNetworkConfig_Model.interfacesTable = {}
  for _, enum in pairs(Ethernet.Interface.getInterfaces()) do
    local dhcpEnabled, ipAddress, subnetMask, gateway = Ethernet.Interface.getAddressConfig(enum)
    local isLinkActive = Ethernet.Interface.isLinkActive(enum)
    local macAddress = Ethernet.Interface.getMACAddress(enum)
    local isBridged = Ethernet.Interface.isBridged(enum)
    local interfaceConfig = {}

    if isBridged then
      interfaceConfig.interfaceName     = enum
      interfaceConfig.dhcp              = false
      interfaceConfig.macAddress        = 'see Bridge'
      interfaceConfig.isLinkActive      = 'see Bridge'
      interfaceConfig.ipAddress         = 'see Bridge'
      interfaceConfig.subnetMask        = 'see Bridge'
      interfaceConfig.defaultGateway    = 'see Bridge'
    else
      interfaceConfig.interfaceName     = enum
      interfaceConfig.dhcp              = dhcpEnabled
      interfaceConfig.macAddress        = macAddress
      interfaceConfig.isLinkActive      = isLinkActive
      interfaceConfig.ipAddress         = ipAddress
      interfaceConfig.subnetMask        = subnetMask
      interfaceConfig.defaultGateway    = gateway
    end
    deviceNetworkConfig_Model.interfacesTable[enum] = interfaceConfig
  end
  return deviceNetworkConfig_Model.interfacesTable
end
deviceNetworkConfig_Model.refreshInterfaces = refreshInterfaces
refreshInterfaces()

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
