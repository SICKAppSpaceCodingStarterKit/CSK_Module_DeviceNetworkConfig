# Changelog
All notable changes to this project will be documented in this file.

## Release 2.2.2

### Improvements
- Check if specific set functions are supported (e.g. not for SIM300 or SAE)

### Bugfix
- Legacy bindings of ValueDisplay elements within UI did not work if deployed with VS Code AppSpace SDK
- UI differs if deployed via Appstudio or VS Code AppSpace SDK
- Fullscreen icon of iFrame was visible

## Release 2.2.1

### Bugfix
- Error with adding new DNS server (introduced in version 2.2.0)

## Release 2.2.0

### New features
- Provide version of module via 'OnNewStatusModuleVersion'
- Function 'getParameters' to provide PersistentData parameters
- Check if features of module can be used on device and provide this via 'OnNewStatusModuleIsActive' event / 'getStatusModuleActive' function

### Improvements
- New UI design available (e.g. selectable via CSK_Module_PersistentData v4.1.0 or higher), see 'OnNewStatusCSKStyle'
- Show timestamp info after ping
- Check interface selection within UI table
- 'loadParameters' returns its success
- 'sendParameters' can control if sent data should be saved directly by CSK_Module_PersistentData
- Added browser tab information
- Minor UI changes

### Bugfix
- Error while trying to set nameserver if running on emulator or SAE

## Release 2.1.0

### Improvements
- Possibility to configure nameservers via the UI

## Release 2.0.0

### Improvements
- Renamed function 'setPingIpAddress' to 'setPingIPAddress'
- Using recursive helper functions to convert Container <-> Lua table

## Release 1.4.0

### Improvements
- Update to EmmyLua annotations
- Usage of lua diagnostics
- Documentation updates

## Release 1.3.0

### Improvements
- Prepared for CSK_UserManagement user levels: Operator, Maintenance, Service, Admin to optionally hide content related to UserManagement module (using bool parameter)
- Module name added to log messages
- Renamed page folder accordingly to module name
- Hiding  SOPAS Login
- Documentation updates (manifest, code internal, UI elements)
- camelCase renamed functions
- Minor code edits
- Using prefix for events

### Bugfix
- UI events notified after pageLoad after 300ms instead of 100ms to not miss

## Release 1.2.0
- Initial commit

### Improvements
- Hide IPs in the list if DHCP is enabled

## Release 1.1.0

### New features
- Added IP utils

## Release 1.0.0
- Initial commit
