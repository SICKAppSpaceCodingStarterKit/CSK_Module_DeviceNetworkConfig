# Changelog
All notable changes to this project will be documented in this file.


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
