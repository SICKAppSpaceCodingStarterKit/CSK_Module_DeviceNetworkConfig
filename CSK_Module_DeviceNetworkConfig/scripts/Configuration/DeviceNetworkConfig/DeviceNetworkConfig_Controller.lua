---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the DeviceNetworkConfig_Model
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local NAME_OF_MODULE = 'CSK_DeviceNetworkConfig'

-- Timer to update UI via events after page was loaded
local tmrDeviceNetworkConfig = Timer.create()
tmrDeviceNetworkConfig:setExpirationTime(300)
tmrDeviceNetworkConfig:setPeriodic(false)

-- Currently selected / predefined values for network config
local currentInterfaceName  = '-'
local currentIP             = '-'
local currentSubnet         = '-'
local currentGateway        = '-'
local currentDHCP           = false
local dnsAdd -- DNS that should be added
local dnsRemove -- DNS that should be removed

local interfacesTable = {} -- table to hold available interfaces
local jsonInterfaceListContent -- available interfaces as JSON

-- Reference to global handle
local deviceNetworkConfig_Model

-- ************************ UI Events Start ********************************
Script.serveEvent("CSK_DeviceNetworkConfig.OnNewStatusLoadParameterOnReboot", "DeviceNetworkConfig_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_DeviceNetworkConfig.OnPersistentDataModuleAvailable", "DeviceNetworkConfig_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_DeviceNetworkConfig.OnNewParameterName", "DeviceNetworkConfig_OnNewParameterName")
Script.serveEvent("CSK_DeviceNetworkConfig.OnDataLoadedOnReboot", "DeviceNetworkConfig_OnDataLoadedOnReboot")

Script.serveEvent("CSK_DeviceNetworkConfig.OnNewEthernetConfigStatus", "DeviceNetworkConfig_OnNewEthernetConfigStatus")
Script.serveEvent("CSK_DeviceNetworkConfig.OnNewInterfaceTable", "DeviceNetworkConfig_OnNewInterfaceTable")
Script.serveEvent("CSK_DeviceNetworkConfig.OnNewIP", "DeviceNetworkConfig_OnNewIP")
Script.serveEvent("CSK_DeviceNetworkConfig.OnNewSubnetMask", "DeviceNetworkConfig_OnNewSubnetMask")
Script.serveEvent("CSK_DeviceNetworkConfig.OnNewDefaultGateway", "DeviceNetworkConfig_OnNewDefaultGateway")
Script.serveEvent("CSK_DeviceNetworkConfig.OnNewDHCPStatus", "DeviceNetworkConfig_OnNewDHCPStatus")
Script.serveEvent("CSK_DeviceNetworkConfig.OnIPDisabled", "DeviceNetworkConfig_OnIPDisabled")
Script.serveEvent("CSK_DeviceNetworkConfig.OnSubnetDisabled", "DeviceNetworkConfig_OnSubnetDisabled")
Script.serveEvent("CSK_DeviceNetworkConfig.OnGatewayDisabled", "DeviceNetworkConfig_OnGatewayDisabled")
Script.serveEvent("CSK_DeviceNetworkConfig.OnDHCPDisabled", "DeviceNetworkConfig_OnDHCPDisabled")
Script.serveEvent("CSK_DeviceNetworkConfig.OnIPError", "DeviceNetworkConfig_OnIPError")
Script.serveEvent("CSK_DeviceNetworkConfig.OnSubnetError", "DeviceNetworkConfig_OnSubnetError")
Script.serveEvent("CSK_DeviceNetworkConfig.OnGatewayError", "DeviceNetworkConfig_OnGatewayError")
Script.serveEvent("CSK_DeviceNetworkConfig.OnApplyButtonDisabled", "DeviceNetworkConfig_OnApplyButtonDisabled")
Script.serveEvent("CSK_DeviceNetworkConfig.OnNewInterfaceChoice", "DeviceNetworkConfig_OnNewInterfaceChoice")
Script.serveEvent("CSK_DeviceNetworkConfig.OnNewDNS", "DeviceNetworkConfig_OnNewDNS")
Script.serveEvent("CSK_DeviceNetworkConfig.OnDNSIPError", "DeviceNetworkConfig_OnDNSIPError")

Script.serveEvent("CSK_DeviceNetworkConfig.OnUserLevelOperatorActive", "DeviceNetworkConfig_OnUserLevelOperatorActive")
Script.serveEvent("CSK_DeviceNetworkConfig.OnUserLevelMaintenanceActive", "DeviceNetworkConfig_OnUserLevelMaintenanceActive")
Script.serveEvent("CSK_DeviceNetworkConfig.OnUserLevelServiceActive", "DeviceNetworkConfig_OnUserLevelServiceActive")
Script.serveEvent("CSK_DeviceNetworkConfig.OnUserLevelAdminActive", "DeviceNetworkConfig_OnUserLevelAdminActive")

Script.serveEvent("CSK_DeviceNetworkConfig.OnNewPingResult", "DeviceNetworkConfig_OnNewPingResult")
Script.serveEvent("CSK_DeviceNetworkConfig.OnNewPingDetails", "DeviceNetworkConfig_OnNewPingDetails")

-- ************************ UI Events End **********************************

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

-- Functions to forward logged in user roles via CSK_UserManagement module (if available)
-- ***********************************************
--- Function to react on status change of Operator user level
---@param status boolean Status if Operator level is active
local function handleOnUserLevelOperatorActive(status)
  Script.notifyEvent("DeviceNetworkConfig_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("DeviceNetworkConfig_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("DeviceNetworkConfig_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("DeviceNetworkConfig_OnUserLevelAdminActive", status)
end

--- Function to check what options should be adjustable in UI
local function checkWhatToDisable()
  if currentDHCP == true or (deviceNetworkConfig_Model.helperFuncs.checkIP(currentIP) and deviceNetworkConfig_Model.helperFuncs.checkIP(currentSubnet) and (deviceNetworkConfig_Model.helperFuncs.checkIP(currentGateway) or currentGateway == '')) then
    Script.notifyEvent("DeviceNetworkConfig_OnApplyButtonDisabled", false)
  else
    Script.notifyEvent("DeviceNetworkConfig_OnApplyButtonDisabled", true)
  end
  if currentInterfaceName == '-' or nil then
    Script.notifyEvent("DeviceNetworkConfig_OnIPDisabled",        true)
    Script.notifyEvent("DeviceNetworkConfig_OnSubnetDisabled",    true)
    Script.notifyEvent("DeviceNetworkConfig_OnGatewayDisabled",   true)
    Script.notifyEvent("DeviceNetworkConfig_OnDHCPDisabled",      true)
  else
    Script.notifyEvent("DeviceNetworkConfig_OnDHCPDisabled",      false)
    if currentDHCP == true then -- when DHCP is ON, the rest of the fields are empty and can't be edited
      Script.notifyEvent("DeviceNetworkConfig_OnIPError",           false)
      Script.notifyEvent("DeviceNetworkConfig_OnSubnetError",       false)
      Script.notifyEvent("DeviceNetworkConfig_OnGatewayError",      false)
      Script.notifyEvent("DeviceNetworkConfig_OnNewIP",             '-')
      Script.notifyEvent("DeviceNetworkConfig_OnNewSubnetMask",     '-')
      Script.notifyEvent("DeviceNetworkConfig_OnNewDefaultGateway", '-')
      Script.notifyEvent("DeviceNetworkConfig_OnIPDisabled",        true)
      Script.notifyEvent("DeviceNetworkConfig_OnSubnetDisabled",    true)
      Script.notifyEvent("DeviceNetworkConfig_OnGatewayDisabled",   true)
    else
      Script.notifyEvent("DeviceNetworkConfig_OnIPDisabled",        false)
      Script.notifyEvent("DeviceNetworkConfig_OnSubnetDisabled",    false)
      Script.notifyEvent("DeviceNetworkConfig_OnGatewayDisabled",   false)
    end
  end
end

--- Function to get access to the deviceNetworkConfig_Model object
---@param handle handle Handle of deviceNetworkConfig_Model object
local function setDeviceNetworkConfig_Model_Handle(handle)
  deviceNetworkConfig_Model = handle
  if deviceNetworkConfig_Model.userManagementModuleAvailable then
    -- Register on events of CSK_UserManagement module if available
    Script.register('CSK_UserManagement.OnUserLevelOperatorActive', handleOnUserLevelOperatorActive)
    Script.register('CSK_UserManagement.OnUserLevelMaintenanceActive', handleOnUserLevelMaintenanceActive)
    Script.register('CSK_UserManagement.OnUserLevelServiceActive', handleOnUserLevelServiceActive)
    Script.register('CSK_UserManagement.OnUserLevelAdminActive', handleOnUserLevelAdminActive)
  end
  Script.releaseObject(handle)
end

-- ********************* UI Setting / Submit Functions Start ********************

local function refresh()
  interfacesTable = deviceNetworkConfig_Model.refreshInterfaces()
  jsonInterfaceListContent = deviceNetworkConfig_Model.helperFuncs.createJsonList(interfacesTable)
  Script.notifyEvent("DeviceNetworkConfig_OnNewInterfaceTable", jsonInterfaceListContent)
  checkWhatToDisable()
end
Script.serveFunction("CSK_DeviceNetworkConfig.refresh", refresh)

--- Function to update user levels
local function updateUserLevel()
  if deviceNetworkConfig_Model.userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    CSK_UserManagement.pageCalled()
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("DeviceNetworkConfig_OnUserLevelOperatorActive", true)
    Script.notifyEvent("DeviceNetworkConfig_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("DeviceNetworkConfig_OnUserLevelServiceActive", true)
    Script.notifyEvent("DeviceNetworkConfig_OnUserLevelAdminActive", true)
  end
end

-- Get a list of all configured nameservers
local function getNameserverList()
  local retValue = {}
  for _,v in pairs(Ethernet.DNS.getNameservers()) do
    -- To enable the display in the dynamic table using the keyword "dns"
    ---@diagnostic disable-next-line: param-type-mismatch
    table.insert(retValue, {dns= v})
  end

  -- If only 127.0.0.1 is use, hide it
  if #retValue == 1 then
    if retValue[1].dns == "127.0.0.1" then
      retValue = {}
    end
  end

  return retValue
end

-- Update nameserver configuration
---@param nameserverList string[] List of nameservers
local function updateNameservers(nameserverList)
  -- Remove duplicate entries in the list
  local l_hashList = {}
  local l_cleanedList = {}
  for _,ip in ipairs(nameserverList) do
    if (not l_hashList[ip]) then
      l_cleanedList[#l_cleanedList + 1] = ip
      l_hashList[ip] = true
    end
  end

  if #l_cleanedList <= 3 then
    -- Set nameservers
    Ethernet.DNS.setNameservers(l_cleanedList)
    deviceNetworkConfig_Model.parameters.nameservers = l_cleanedList
  else
    deviceNetworkConfig_Model.parameters.nameservers = Ethernet.DNS.getNameservers()
    return
  end

  -- Check if duplicate nameservers configured, this can happen when additional nameservers are added automatically via DHCP
  local l_configuredDns = {}
  local l_duplicateElements = false

  for _,v in pairs(getNameserverList()) do
    if l_configuredDns[v.dns] == nil then
      l_configuredDns[v.dns] = 1
    else
      -- Duplicate DNS entry detected
      l_configuredDns[v.dns] = l_configuredDns[v.dns] + 1
      l_duplicateElements = true
    end
  end

  -- Remove duplicated DNS
  if l_duplicateElements then
    l_cleanedList = {}
    for ip,number in pairs(l_configuredDns) do
      if number == 1 then
        table.insert(l_cleanedList, ip)
      end
    end

    -- Set name server list again without duplicates added by DHCP
    Ethernet.DNS.setNameservers(l_cleanedList)
    deviceNetworkConfig_Model.parameters.nameservers = l_cleanedList
  end

  -- Status print out
  local l_statusOutput = ""
  for _,ip in pairs(l_cleanedList) do
    l_statusOutput = l_statusOutput .. ip .. " "
  end
  _G.logger:info(NAME_OF_MODULE .. ": Added nameservers (" .. l_statusOutput ..")")

  -- Store nameserver entries permanently
  CSK_DeviceNetworkConfig.sendParameters()

  -- Update DNS UI table
  Script.notifyEvent("DeviceNetworkConfig_OnNewDNS", deviceNetworkConfig_Model.helperFuncs.json.encode(getNameserverList()))
end

local function addDNS()
  if dnsAdd ~= nil and dnsAdd ~= "" then
    local l_nameservers = {}
    for _,ip in pairs(getNameserverList()) do
      if ip ~= dnsAdd then
        -- Add already added nameservers
        table.insert(l_nameservers, ip.dns)
      end
    end

    -- Add nameserver
    table.insert(l_nameservers, dnsAdd)

    -- Update DNS table
    updateNameservers(l_nameservers)
  end
end
Script.serveFunction('CSK_DeviceNetworkConfig.addDNS', addDNS)

local function removeDNS()
  if dnsRemove ~= nil and dnsRemove ~= "" then
    local l_nameservers = {}
    for _,v in pairs(getNameserverList()) do
      if v.dns ~= dnsRemove then
        table.insert(l_nameservers, v.dns)
      end
    end

    updateNameservers(l_nameservers)
  end
end
Script.serveFunction('CSK_DeviceNetworkConfig.removeDNS', removeDNS)

local function setDNS(nameserver)
  if deviceNetworkConfig_Model.helperFuncs.checkIP(nameserver) then
    Script.notifyEvent("DeviceNetworkConfig_OnDNSIPError", false)
    dnsAdd = nameserver
  else
    Script.notifyEvent("DeviceNetworkConfig_OnDNSIPError", true)
    dnsAdd = nil
  end
end
Script.serveFunction('CSK_DeviceNetworkConfig.setDNS', setDNS)

local function selectDNSViaUI(selectedRow)
  if selectedRow ~= "" then
    local l_data = deviceNetworkConfig_Model.helperFuncs.json.decode(selectedRow)
    for _,v in pairs(getNameserverList()) do
      if v.dns == l_data.dns then
        dnsRemove = v.dns
        break
      end
    end
  end

  -- Workaround to reset the selection of the DNS in the UI table
  Script.sleep(100)
  Script.notifyEvent("DeviceNetworkConfig_OnNewDNS", deviceNetworkConfig_Model.helperFuncs.json.encode(getNameserverList()))
end
Script.serveFunction('CSK_DeviceNetworkConfig.selectDNSViaUI', selectDNSViaUI)

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrDeviceNetworkConfig()
  updateUserLevel()

  refresh()
  currentInterfaceName  = '-'
  currentIP             = '-'
  currentSubnet         = '-'
  currentGateway        = '-'
  currentDHCP           = false
  Script.notifyEvent("DeviceNetworkConfig_OnNewDHCPStatus",     false)
  Script.notifyEvent("DeviceNetworkConfig_OnNewIP",             '-')
  Script.notifyEvent("DeviceNetworkConfig_OnNewSubnetMask",     '-')
  Script.notifyEvent("DeviceNetworkConfig_OnNewDefaultGateway", '-')
  Script.notifyEvent("DeviceNetworkConfig_OnNewInterfaceChoice",'-')
  Script.notifyEvent("DeviceNetworkConfig_OnNewEthernetConfigStatus", 'empty')
  Script.notifyEvent("DeviceNetworkConfig_OnNewDNS", deviceNetworkConfig_Model.helperFuncs.json.encode(getNameserverList()))

  Script.notifyEvent("DeviceNetworkConfig_OnNewStatusLoadParameterOnReboot", deviceNetworkConfig_Model.parameterLoadOnReboot)
  Script.notifyEvent("DeviceNetworkConfig_OnPersistentDataModuleAvailable", deviceNetworkConfig_Model.persistentModuleAvailable)
  Script.notifyEvent("DeviceNetworkConfig_OnNewParameterName", deviceNetworkConfig_Model.parametersName)

  checkWhatToDisable()
end
Timer.register(tmrDeviceNetworkConfig, "OnExpired", handleOnExpiredTmrDeviceNetworkConfig)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  tmrDeviceNetworkConfig:start()
  return ''
end
Script.serveFunction("CSK_DeviceNetworkConfig.pageCalled", pageCalled)

local function selectInterface(row_selected)
  Script.notifyEvent("DeviceNetworkConfig_OnNewEthernetConfigStatus", 'empty')
  Script.notifyEvent("DeviceNetworkConfig_OnIPError", false)
  Script.notifyEvent("DeviceNetworkConfig_OnSubnetError", false)
  Script.notifyEvent("DeviceNetworkConfig_OnGatewayError", false)
  local _, pos1 = string.find(row_selected, '"Interface":"')
  local pos2, _ = string.find(row_selected, '"', pos1+1)
  local selectedInterfaceName = string.sub(row_selected, pos1+1, pos2-1)
  if selectedInterfaceName ~= '-' and selectedInterfaceName ~= '' then
    currentIP             = interfacesTable[selectedInterfaceName].ipAddress
    currentSubnet         = interfacesTable[selectedInterfaceName].subnetMask
    currentGateway        = interfacesTable[selectedInterfaceName].defaultGateway
    currentDHCP           = interfacesTable[selectedInterfaceName].dhcp
    currentInterfaceName  = selectedInterfaceName
    Script.notifyEvent("DeviceNetworkConfig_OnNewIP",             currentIP)
    Script.notifyEvent("DeviceNetworkConfig_OnNewSubnetMask",     currentSubnet)
    Script.notifyEvent("DeviceNetworkConfig_OnNewDefaultGateway", currentGateway)
    Script.notifyEvent("DeviceNetworkConfig_OnNewDHCPStatus",     currentDHCP)
    Script.notifyEvent("DeviceNetworkConfig_OnNewInterfaceChoice",currentInterfaceName)
  end
  if currentDHCP == true then
    Script.notifyEvent("DeviceNetworkConfig_OnIPDisabled", true)
    Script.notifyEvent("DeviceNetworkConfig_OnSubnetDisabled", true)
    Script.notifyEvent("DeviceNetworkConfig_OnGatewayDisabled", true)
  end
  Script.sleep(100)
  Script.notifyEvent("DeviceNetworkConfig_OnNewInterfaceTable", jsonInterfaceListContent)
  checkWhatToDisable()
end
Script.serveFunction("CSK_DeviceNetworkConfig.selectInterface", selectInterface)

local function setInterfaceIP(newIP)
  currentIP = newIP
  if deviceNetworkConfig_Model.helperFuncs.checkIP(newIP) then
    Script.notifyEvent("DeviceNetworkConfig_OnIPError", false)
  else
    Script.notifyEvent("DeviceNetworkConfig_OnIPError", true)
  end
  checkWhatToDisable()
end
Script.serveFunction("CSK_DeviceNetworkConfig.setInterfaceIP", setInterfaceIP)

local function setSubnetMask(newSubnetMask)
  currentSubnet = newSubnetMask
  if deviceNetworkConfig_Model.helperFuncs.checkIP(newSubnetMask) then
    Script.notifyEvent("DeviceNetworkConfig_OnSubnetError", false)
  else
    Script.notifyEvent("DeviceNetworkConfig_OnSubnetError", true)
  end
  checkWhatToDisable()
end
Script.serveFunction("CSK_DeviceNetworkConfig.setSubnetMask", setSubnetMask)

local function setDefaultGateway(newDefaultGateway)
  currentGateway = newDefaultGateway
  if newDefaultGateway == '' or deviceNetworkConfig_Model.helperFuncs.checkIP(newDefaultGateway) then
    Script.notifyEvent("DeviceNetworkConfig_OnGatewayError", false)
  else
    Script.notifyEvent("DeviceNetworkConfig_OnGatewayError", true)
  end
  checkWhatToDisable()
end
Script.serveFunction("CSK_DeviceNetworkConfig.setDefaultGateway", setDefaultGateway)

local function setDHCPState(newDHCPState)
  currentDHCP = newDHCPState
  if newDHCPState == false then
    if currentIP == '-' then currentIP = '192.168.0.1' end
    if currentSubnet == '-' then currentSubnet = '255.255.255.0' end
    if currentGateway == '-' then currentGateway = '0.0.0.0' end
    Script.notifyEvent("DeviceNetworkConfig_OnNewIP",             currentIP)
    Script.notifyEvent("DeviceNetworkConfig_OnNewSubnetMask",     currentSubnet)
    Script.notifyEvent("DeviceNetworkConfig_OnNewDefaultGateway", currentGateway)
  end
  checkWhatToDisable()
end
Script.serveFunction("CSK_DeviceNetworkConfig.setDHCPState", setDHCPState)

local function setPingIPAddress(ping_ip)
  deviceNetworkConfig_Model.ping_ip_adress = ping_ip
end
Script.serveFunction("CSK_DeviceNetworkConfig.setPingIPAddress", setPingIPAddress)

local function ping()
  local succes, time = Ethernet.ping(deviceNetworkConfig_Model.ping_ip_adress)
  Script.notifyEvent("DeviceNetworkConfig_OnNewPingResult", succes)
  if (time) then
    Script.notifyEvent("DeviceNetworkConfig_OnNewPingDetails", tostring(time).." ms")
  else
    Script.notifyEvent("DeviceNetworkConfig_OnNewPingDetails", "No Connection")
  end
end
Script.serveFunction("CSK_DeviceNetworkConfig.ping", ping)

local function applyConfig()
  if deviceNetworkConfig_Model.helperFuncs.checkIP(currentIP) and deviceNetworkConfig_Model.helperFuncs.checkIP(currentSubnet) and deviceNetworkConfig_Model.helperFuncs.checkIP(currentGateway) or currentGateway == '' then
    Script.notifyEvent("DeviceNetworkConfig_OnNewEthernetConfigStatus", 'processing')
    if currentDHCP == true then
      _G.logger:info(NAME_OF_MODULE .. ": Applying device's Ethernet config: \n  Interface " .. currentInterfaceName .. " \n  DHCP: " .. tostring(currentDHCP))
      deviceNetworkConfig_Model.applyEthernetConfig(currentInterfaceName, currentDHCP, nil, nil, nil)
    else
      _G.logger:info(NAME_OF_MODULE .. ": Applying device's Ethernet config: \n  Interface " .. currentInterfaceName .. " \n  DHCP: " .. tostring(currentDHCP) .. " \n  IP: " .. currentIP.. " \n  Subnet: " .. currentSubnet .. " \n  Gateway: " .. currentGateway)
      deviceNetworkConfig_Model.applyEthernetConfig(currentInterfaceName, currentDHCP, currentIP, currentSubnet, currentGateway)
    end
    refresh()
    Script.notifyEvent("DeviceNetworkConfig_OnNewEthernetConfigStatus", 'success')
  else
    Script.notifyEvent("DeviceNetworkConfig_OnNewEthernetConfigStatus", 'error')
  end
  _G.logger:info(NAME_OF_MODULE .. ": Applying device's Ethernet config finished")
end
Script.serveFunction("CSK_DeviceNetworkConfig.applyConfig", applyConfig)

--- Function to react 'Ethernet.Interface.OnLinkActiveChanged' event
local function handleOnLinkActiveChanged(ifName, linkActive)
  refresh()
  _G.logger:info(NAME_OF_MODULE .. ': New link status = ' .. tostring(linkActive) .. ' on interface ' .. ifName)
end
Script.register("Ethernet.Interface.OnLinkActiveChanged", handleOnLinkActiveChanged)

-- **********************************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- **********************************************************************************

local function setParameterName(name)
  _G.logger:info(NAME_OF_MODULE .. ": Set parameter name: " .. tostring(name))
  deviceNetworkConfig_Model.parametersName = tostring(name)
end
Script.serveFunction("CSK_DeviceNetworkConfig.setParameterName", setParameterName)

local function sendParameters()
  if deviceNetworkConfig_Model.persistentModuleAvailable then
    CSK_PersistentData.addParameter(deviceNetworkConfig_Model.helperFuncs.convertTable2Container(deviceNetworkConfig_Model.parameters), deviceNetworkConfig_Model.parametersName)
    CSK_PersistentData.setModuleParameterName(NAME_OF_MODULE, deviceNetworkConfig_Model.parametersName, deviceNetworkConfig_Model.parameterLoadOnReboot)
    _G.logger:info(NAME_OF_MODULE .. ": Send DeviceNetworkConfig parameters with name '" .. deviceNetworkConfig_Model.parametersName .. "' to CSK_PersistentData module.")
    CSK_PersistentData.saveData()
  else
    _G.logger:warning(NAME_OF_MODULE .. ": CSK_PersistentData Module not available.")
  end
end
Script.serveFunction("CSK_DeviceNetworkConfig.sendParameters", sendParameters)

local function loadParameters()
  if deviceNetworkConfig_Model.persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(deviceNetworkConfig_Model.parametersName)
    if data then
      _G.logger:info(NAME_OF_MODULE .. ": Loaded parameters from CSK_PersistentData module.")
      deviceNetworkConfig_Model.parameters = deviceNetworkConfig_Model.helperFuncs.convertContainer2Table(data)

      -- Load nameservers
      updateNameservers(deviceNetworkConfig_Model.parameters.nameservers)

      CSK_DeviceNetworkConfig.pageCalled()
    else
      _G.logger:warning(NAME_OF_MODULE .. ": Loading parameters from CSK_PersistentData module did not work.")
    end
  else
    _G.logger:warning(NAME_OF_MODULE .. ": CSK_PersistentData Module not available.")
  end
end
Script.serveFunction("CSK_DeviceNetworkConfig.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  deviceNetworkConfig_Model.parameterLoadOnReboot = status
  _G.logger:info(NAME_OF_MODULE .. ": Set new status to load setting on reboot: " .. tostring(status))
end
Script.serveFunction("CSK_DeviceNetworkConfig.setLoadOnReboot", setLoadOnReboot)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()

  if string.sub(CSK_PersistentData.getVersion(), 1, 1) == '1' then

    _G.logger:warning(NAME_OF_MODULE .. ': CSK_PersistentData module is too old and will not work. Please update CSK_PersistentData module.')

    deviceNetworkConfig_Model.persistentModuleAvailable = false
  else

    local parameterName, loadOnReboot = CSK_PersistentData.getModuleParameterName(NAME_OF_MODULE)

    if parameterName then
      deviceNetworkConfig_Model.parametersName = parameterName
      deviceNetworkConfig_Model.parameterLoadOnReboot = loadOnReboot
    end

    if deviceNetworkConfig_Model.parameterLoadOnReboot then
      loadParameters()
    end
    Script.notifyEvent('DeviceNetworkConfig_OnDataLoadedOnReboot')
  end
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

-- *************************************************
-- END of functions for CSK_PersistentData module usage
-- *************************************************

return setDeviceNetworkConfig_Model_Handle

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************
