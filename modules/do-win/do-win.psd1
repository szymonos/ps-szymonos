@{

# Script module or binary module file associated with this manifest.
RootModule = 'do-win.psm1'

# Version number of this module.
ModuleVersion = '0.2.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '55883a77-76a6-49df-94ab-6883a44736ad'

# Author of this module
Author = 'Szymon Osiecki'

# Copyright statement for this module
Copyright = '(c) Szymon Osiecki. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Module intended to streamline work on Windows.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.0'

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
ScriptsToProcess = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    # common
    'Get-CommandSource',
    'Get-DiskUsage',
    # forms
    'Get-FileName',
    'Get-FolderPath'
    # winget
    'Get-WingetResult',
    'Invoke-WingetUpgrade'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @(
    'which',
    'du'
)

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/szymonos/ps-szymonos/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/szymonos/ps-szymonos'

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        Prerelease = 'beta'

    } # End of PSData hashtable

} # End of PrivateData hashtable

}
