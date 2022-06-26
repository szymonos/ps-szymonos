[void] [System.Reflection.Assembly]::Load('System.Windows.Forms')

<#
.SYNOPSIS
Get file name from open file dialag.
.PARAMETER InitialDirectory
Form dialog initial directory.
.PARAMETER FileFilter
File form dialog filter.
#>
function Get-FileName {
    [CmdletBinding()]
    param (
        [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "'{0}' is not a valid folder path.")]
        [string]$InitialDirectory = '.',

        [ValidateScript({ $_ -ne '' -and $_ -match '.+\|\s*\*\.' }, ErrorMessage = "'{0}' is not a valid file filter." )]
        [string]$FileFilter = 'All types| *.*'
    )

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = [System.IO.Path]::GetFullPath($InitialDirectory)
    $OpenFileDialog.Filter = $FileFilter
    [void] $OpenFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{ TopMost = $true }))

    return $OpenFileDialog.FileName
}

<#
.SYNOPSIS
Get folder path from folder browser dialag.
.PARAMETER InitialDirectory
Folder browser dialog initial directory.
#>
function Get-FolderPath {
    [CmdletBinding()]
    param (
        [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "'{0}' is not a valid folder path.")]
        [string]$InitialDirectory = '.'
    )

    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($InitialDirectory) {
        $FolderBrowserDialog.SelectedPath = Join-Path ([System.IO.Path]::GetFullPath($InitialDirectory)) -ChildPath $null
    }
    [void] $FolderBrowserDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{ TopMost = $true }))

    return $FolderBrowserDialog.SelectedPath
}
