local function setHomeScreenAsMainWebpage()
  local defaultWebpage = Parameters.get("AEDefaultWebpage")
  if defaultWebpage == "" then
    assert(Parameters.set("AEDefaultWebpage", _APPNAME))
  elseif defaultWebpage == nil then
    assert(false, "AppEngine does not support setting the default webpage over variable AEDefaultWebpage")
  end
end

local function main()
  setHomeScreenAsMainWebpage()
end
Script.register("Engine.OnStarted", main)

-------------------------------------------------------------
-- Create and wire AppList and UI modules

local appList = require("AppList")

local ui = require("HomeScreenUI")
ui.getAppListAsJson = appList.getAsJson
ui.serveBindings()

appList.notifyUpdateFunction = ui.notifyAppList
appList.update()
