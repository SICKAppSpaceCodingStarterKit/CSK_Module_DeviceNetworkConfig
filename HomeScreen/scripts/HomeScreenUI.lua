local ui = {}

ui.getAppListAsJson = function()
  assert(false, "HomeScreenUI implementation error: app list function needed")
end

ui.selectedApp = ""

local function setSelectedApp(selectedApp)
  --print("setSelectedApp: " .. selectedApp)
  local appNameKeyText = "\"appName\":\""
  local appNameInd = selectedApp:find(appNameKeyText)
  local appNameStart = appNameInd + appNameKeyText:len()
  local appNameEnd = selectedApp:find("\"", appNameStart + 1) - 1
  ui.selectedApp = selectedApp:sub(appNameStart, appNameEnd)
end

local function getSelectedApp() -- currently not used, but probably in future
  --print("getSelectedApp")
  return ui.selectedApp
end

local function getCurrentApps()
  local currentApps = ui.getAppListAsJson()
  --print("getCurrentApps: " .. currentApps)
  return currentApps
end

local function openApp() -- currently not used, but probably in future to re-act if clicking in table
  print("openApp")
end

ui.notifyAppList = function(appListJson)
  Script.notifyEvent("AppsChanged", appListJson)
end

ui.serveBindings = function()
  Script.serveFunction(_APPNAME .. ".setSelectedApp", setSelectedApp)
  Script.serveFunction(_APPNAME .. ".getSelectedApp", getSelectedApp)

  Script.serveFunction(_APPNAME .. ".getCurrentApps", getCurrentApps)
  Script.serveEvent(_APPNAME .. ".AppsChanged", "AppsChanged")
  
  Script.serveFunction(_APPNAME .. ".openApp", openApp)
end

return ui
