# Adapter definitions
$appStudioProjectFolder = "project"
$gitIgnoreFile = ".gitignore"
$dependentModules = ,("v4.0.0", "dependencies/modulePersistentData", "https://github.com/SICKAppSpaceCodingStarterKit/CSK_Module_PersistentData")

$modules = 	"CSK_Module_DeviceNetworkConfig",
			"HomeScreen"

# Add folder to the GIT ignore list if not already exist
Function addFolderToGitIgnore
{
	Param ($folderToAdd)
	
	$entry = $folderToAdd.replace("\", "/")
	if (Test-Path -Path $gitIgnoreFile -PathType Leaf)
	{
		foreach($line in Get-Content $gitIgnoreFile) 
		{
			if($line -match $regex)
			{
				if ($line -eq $entry)
				{
					return
				}
			}
		}
	}
	"Adding '" + $entry + "' to the GIT ignore list"
	Add-Content $gitIgnoreFile $entry
}

# Description
" "
"====================================================================================="
"Get the dependencies specified in the script from GitHub"
"and create a project folder, which can be used by SICK AppStudio."
"====================================================================================="

# Script input promps
$updateSubtrees = Read-Host -Prompt "Do you want to add/update the dependent modules used in this project? (y=add/update + create project, n=create project only)"
$moduleUpdate = $false
if ($updateSubtrees -eq "y")
{
	$moduleUpdate = $true
}


# Create AppStudio project folder if not exist
if (-not(Test-Path -Path $appStudioProjectFolder))
{
	New-Item $appStudioProjectFolder -Type Directory
}

# Adding dependencies
foreach($module in $dependentModules)
{
	# GIT add / pull
	if ($moduleUpdate)
	{
		if (Test-Path -Path $module[1])
		{
			"===== Update " + $module[1] + " (pull from GIT) ====="
			git subtree pull --prefix $module[1] $module[2] $module[0]
		}
		else
		{
			"===== Add " + $module[1] + " (add from GIT) ====="
			git subtree add --prefix $module[1] $module[2] $module[0]
		}
	}
	
	# Create sym links if not exists
	foreach($app in Get-ChildItem ($module[1]) -Directory)
	{
		if (not $app.name.StartsWith('CSK_Module'))
		{
			continue
		}
		
		$source = $module[1] + '\' + $app.name
		$destination = $appStudioProjectFolder + '\' + $app.name
		
		if (-not(Test-Path -Path $destination))
		{
			"===== Create sym link for " + $app.name + " ====="
			New-Item -Path $destination -ItemType SymbolicLink -Value $source
		}
	}
}

# Adding modules
foreach($module in $modules)
{
	$source = $module
	$destination = $appStudioProjectFolder + '\' + $module
	
	if (-not(Test-Path -Path $destination))
	{
		Write-Output($source)
		"===== Create sym link for " + $module + " ====="
		New-Item -Path $destination -ItemType SymbolicLink -Value $source
	}
}

addFolderToGitIgnore($appStudioProjectFolder)
	

Write-Host -NoNewLine 'Press any key to exit...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');