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
--deviceNetworkConfig_Model.showBridgeFeature = false -- Set status to show bridge feature
deviceNetworkConfig_Model.listOfInterfaces = {} -- List of available ethernet interfaces

deviceNetworkConfig_Model.bridge = nil -- Optional ethernet bridge
deviceNetworkConfig_Model.bridgeDelayTimer = Timer.create()
deviceNetworkConfig_Model.bridgeDelayTimer:setPeriodic(false)
deviceNetworkConfig_Model.bridgeTestTimer = Timer.create()
deviceNetworkConfig_Model.bridgeTestTimer:setPeriodic(false)

deviceNetworkConfig_Model.tempBridgeInterfaces = {} -- Preset list of ports to bridge
deviceNetworkConfig_Model.tempBridgeIP = '192.168.0.123' -- Preset IP address of bridge
deviceNetworkConfig_Model.tempBridgeSubnetMask = '255.255.255.0' -- Preset subnet mask of bridge
deviceNetworkConfig_Model.tempBridgeGateway = '0.0.0.0' -- Preset gateway of bridge

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

local function startBridgeTestTimer()
  if deviceNetworkConfig_Model.parameters.bridgeTestTime ~= 0 and deviceNetworkConfig_Model.parameters.bridgeActive then
    deviceNetworkConfig_Model.bridgeTestTimer:setExpirationTime(deviceNetworkConfig_Model.parameters.bridgeTestTime*60000)
    deviceNetworkConfig_Model.bridgeTestTimer:start()
    _G.logger:info(nameOfModule .. ": Start test timer to stop bridge")
  else
    deviceNetworkConfig_Model.bridgeTestTimer:stop()
  end
end
deviceNetworkConfig_Model.startBridgeTestTimer = startBridgeTestTimer

--******************************* START ************************************
--********************** Bridge via ControlCenter **************************
--**************************************************************************

--- Function to provide HTTPClient handle to access ControlCenter
local function createClient()
  local client = HTTPClient.create()
  if not client then
    _G.logger:warning(nameOfModule .. ": Error: Failed to create HTTPClient handle")
    return nil
  end
  -- For local unix socket communication, peer/host verification is not needed.
  client:setPeerVerification(false)
  client:setHostnameVerification(false)
  -- Set to true to see detailed request/response logs from the client.
  client:setVerbose(false)
  return client
end

---  Executes a prepared HTTP request, prints the outcome, and returns the response.
--- @param client (HTTPClient) The client handle to use.
--- @param request (HTTPClient.Request) The request to execute.
--- @param command (string) A descriptive label for the operation, used for logging.
--- @return (HTTPClient.Response|nil) The response object on success, or nil on failure.
local function executeRequest(client, request, command)
  local response = client:execute(request)

  if not response:getSuccess() then
    _G.logger:warning(nameOfModule .. ": Error: Failed to send request: " .. command)
    _G.logger:warning(nameOfModule .. ': Error: ' .. response:getError() .. ' - ' .. response:getErrorDetail())
    return nil
  end

  return response

end
--- Creates a new network bridge with the specified configuration via ControlCenter
--- Corresponds to: POST /api/v1/network/bridges/{name}
--- @param name (string) The name for the new bridge (e.g., 'br-lan').
--- @param members (table) A list of interface names to add as slaves (e.g., {'eth3', 'eth4'}).
--- @param staticAddress (string) The static IP address and subnet in CIDR format (e.g., '192.168.2.50/24').
--- @param gateway (string) The default gateway for the bridge's network (e.g., '192.168.2.1').
--- @return (bool) Success of progress
local function createCCBridge(name, members, staticAddress, gateway)
  local client = createClient()
  if not client then return end

  -- Build the list of member interfaces for the JSON body.
  local memberList = ''
  for i, iface in ipairs(members) do
    if i > 1 then memberList = memberList .. ', ' end
    memberList = memberList .. '"' .. string.lower(iface) .. '"'
  end

  -- Construct the JSON payload using the provided parameters.
  local body = string.format([[{
  "defaultNetworkSettings": {
    "defaultGateway": "%s",
    "dhcpFallbackAddress": "%s",
    "dhcpFallbackGateway": "%s",
    "dhcpFallbackMode": 0,
    "enabled": true,
    "staticAddress": "%s",
    "useDhcp": false
  },
  "memberInterfaces": [%s]
}]], gateway, staticAddress, gateway, staticAddress, memberList)

  local request = HTTPClient.Request.create()
  request:setServiceSocket('CONTROLCENTER')
  request:setURL('http://localhost/api/v1/network/bridges/' .. name)
  request:setMethod('POST')
  request:setContentBuffer(body)
  request:setContentType('application/json')

  local tempResponse = executeRequest(client, request, 'CREATE_BRIDGE')

  if tempResponse then
    local responseCode = tempResponse:getStatusCode()
    if responseCode == 204 then
      return true
    else
      return false
    end
  else
    return false
  end
end

--- Function to delete network bridge.
--- Corresponds to: DELETE /api/v1/network/bridges/{name}
--- @param name (string) The name of the bridge to delete.
local function deleteCCBridge(name)
  local client = createClient()
  if not client then return end

  local request = HTTPClient.Request.create()
  request:setServiceSocket('CONTROLCENTER')
  request:setURL('http://localhost/api/v1/network/bridges/' .. name)
  request:setMethod('DELETE')

  local tempResponse = executeRequest(client, request, 'DELETE_BRIDGE')

  if tempResponse then
    local responseCode = tempResponse:getStatusCode()

    if responseCode == 204 then
      return true
    else
      return false
    end
  else
    return false
  end
end

--- Functio to check current status of bridge configuration within ControlCenter
local function checkCCBridge()
  local client = createClient()
  if not client then return end

  local request = HTTPClient.Request.create()
  request:setServiceSocket('CONTROLCENTER')
  request:setURL('http://localhost/api/v1/network/bridges')
  request:setMethod('GET')

  local tempResponse = executeRequest(client, request, 'CHECK_BRIDGE')

  if tempResponse then
    local responseContent = tempResponse:getContent()

    local tempBridgeInterfaceList = deviceNetworkConfig_Model.helperFuncs.json.decode(responseContent)
    if #tempBridgeInterfaceList.bridges >= 1 then
      --deviceNetworkConfig_Model.showBridgeFeature = true
      deviceNetworkConfig_Model.parameters.bridgeActive = true
      deviceNetworkConfig_Model.parameters.bridgeGateway = tempBridgeInterfaceList.bridges[1]['bridge']['defaultNetworkSettings']['defaultGateway']

      deviceNetworkConfig_Model.parameters.bridgeInterfaces = {}
      for _, value in pairs(tempBridgeInterfaceList.bridges[1]['bridge']['status']['members']) do
        table.insert(deviceNetworkConfig_Model.parameters.bridgeInterfaces, string.upper(value['name']))
      end

      local tempIP = string.find(tempBridgeInterfaceList.bridges[1]['bridge']['defaultNetworkSettings']['staticAddress'], '%/')
      if tempIP then
        deviceNetworkConfig_Model.parameters.bridgeIP = string.sub(tempBridgeInterfaceList.bridges[1]['bridge']['defaultNetworkSettings']['staticAddress'], 1, tempIP-1)
        deviceNetworkConfig_Model.parameters.bridgeSubnetMask = deviceNetworkConfig_Model.helperFuncs.bitValueToMask(tonumber(string.sub(tempBridgeInterfaceList.bridges[1]['bridge']['defaultNetworkSettings']['staticAddress'], tempIP+1)))
      end
      startBridgeTestTimer()
    else
      deviceNetworkConfig_Model.parameters.bridgeActive = false -- Set status to activate ethernet bridge
      deviceNetworkConfig_Model.parameters.bridgeInterfaces = {}
    end
  else
    -- Request didn't work
  end
end
deviceNetworkConfig_Model.checkCCBridge = checkCCBridge

if availableAPIs.http and availableAPIs.accessCC then
  checkCCBridge()
end

--******************************** END *************************************
--********************** Bridge via ControlCenter **************************
--**************************************************************************
-- Timer to hide message on UI after 5 seconds
local tmrCallPage = Timer.create()
tmrCallPage:setExpirationTime(5000)
tmrCallPage:setPeriodic(false)

local function handleOnExpired()
  CSK_DeviceNetworkConfig.pageCalled()
end
Timer.register(tmrCallPage, 'OnExpired', handleOnExpired)

local function createBridge()
  _G.logger:info(nameOfModule .. ": Activate bridge.")

  if availableAPIs.accessCC then
    -- Will automatically reboot
    local success = createCCBridge('bridge', deviceNetworkConfig_Model.parameters.bridgeInterfaces, deviceNetworkConfig_Model.parameters.bridgeIP .. '/' .. deviceNetworkConfig_Model.helperFuncs.maskToBitValue(deviceNetworkConfig_Model.parameters.bridgeSubnetMask), deviceNetworkConfig_Model.parameters.bridgeGateway)
    if success then
      Script.notifyEvent("DeviceNetworkConfig_OnNewEthernetConfigStatus", 'Restart')
      Engine.reboot("Reboot with new ethernet setup.")
    else
      tmrCallPage:start()
      return false
    end
  else
    startBridgeTestTimer()
    deviceNetworkConfig_Model.bridge = Ethernet.Bridge.create('EthBridge')
    deviceNetworkConfig_Model.bridge:setStaticAddress(deviceNetworkConfig_Model.parameters.bridgeIP, deviceNetworkConfig_Model.parameters.bridgeSubnetMask, deviceNetworkConfig_Model.parameters.bridgeGateway)
    deviceNetworkConfig_Model.bridge:setInterfaces(deviceNetworkConfig_Model.parameters.bridgeInterfaces)
    local suc = deviceNetworkConfig_Model.bridge:enable()
  end
  CSK_DeviceNetworkConfig.pageCalled()
  return true
end
deviceNetworkConfig_Model.createBridge = createBridge
Timer.register(deviceNetworkConfig_Model.bridgeDelayTimer, 'OnExpired', createBridge)

local function deleteBridge()
  _G.logger:info(nameOfModule .. ": Delete bridge.")
  deviceNetworkConfig_Model.parameters.bridgeActive = false

  if availableAPIs.accessCC then
    local success = deleteCCBridge('bridge')
    if success then
      Script.notifyEvent("DeviceNetworkConfig_OnNewEthernetConfigStatus", 'Restart')
      Engine.reboot("Reboot with new ethernet setup.")
    else
      CSK_DeviceNetworkConfig.pageCalled()
      return false
    end
  else
    if deviceNetworkConfig_Model.bridge then
      deviceNetworkConfig_Model.bridge:disable()
    end
    deviceNetworkConfig_Model.bridge = nil
    collectgarbage()
  end

  Script.notifyEvent("DeviceNetworkConfig_OnNewStatusBridgeActive", deviceNetworkConfig_Model.parameters.bridgeActive)
  CSK_DeviceNetworkConfig.pageCalled()
  return true
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
    local isBridged

    if availableAPIs.http and availableAPIs.accessCC then
      isBridged = false
      for key, value in pairs(deviceNetworkConfig_Model.parameters.bridgeInterfaces) do
        if enum == value then
          isBridged = true
        end
      end
    elseif availableAPIs.bridge then
      isBridged = Ethernet.Interface.isBridged(enum)
    end
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
