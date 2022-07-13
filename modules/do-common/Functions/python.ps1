#!/usr/bin/pwsh
#Requires -PSEdition Core
<#
.SYNOPSIS
Manage conda environments.
.PARAMETER Option
Select script action.
.PARAMETER CondaFile
Specify conda file to use.

.EXAMPLE
Invoke-CondaScript                     # *Create/update environment
Invoke-CondaScript -o 'activate'       # *Activate environment
Invoke-CondaScript -o 'deactivate'     # *Deactivate environment
Invoke-CondaScript -o 'packages'       # *List packages
Invoke-CondaScript -o 'environments'   # *List environments
Invoke-CondaScript -o 'update'         # *Update conda
Invoke-CondaScript -o 'clean'          # *Clean conda
Invoke-CondaScript -o 'remove'         # !Remove environment

$CondaFile = '.tmp/env.yml'
Invoke-CondaScript -f $CondaFile               # *Create/update environment
Invoke-CondaScript -f $CondaFile -o 'activate' # *Activate environment
Invoke-CondaScript -f $CondaFile -o 'remove'   # !Remove environment
#>
function Invoke-CondaScript {
    [CmdletBinding()]
    param (
        [Alias('o')]
        [ValidateSet('create', 'activate', 'deactivate', 'packages', 'environments', 'clean', 'update', 'remove')]
        [string]$Option = 'create',

        [Alias('f')]
        [ValidateNotNullorEmpty()]
        [string]$CondaFile = 'conda.yaml'
    )

    # *Check for conda file
    begin {
        if ($Option -in @('create', 'activate', 'remove')) {
            if (Test-Path $CondaFile) {
                # get environment name
                $envName = (Select-String -Pattern '^name: +(\S+)' -Path $CondaFile).Matches.Groups[1].Value
                $envExists = $envName -in (Get-CondaEnvironment).Name
                # exit environment before proceeding
                Exit-CondaEnvironment
            } else {
                Write-Warning "File `e[4m$CondaFile`e[24m not found"
                break
            }
        }
    }

    # *Execute option
    process {
        switch ($Option) {
            'create' {
                # check libmamba solver installation
                if (-not (Get-ChildItem -Path "$env:_CONDA_ROOT/pkgs/" -Filter 'conda-libmamba-solver*' -Directory)) {
                    Write-Host 'conda-libmamba-solver not found, installing...'
                    Invoke-Conda install -y --name base --channel pkgs/main 'conda-libmamba-solver'
                }
                if ($envExists) {
                    # *Create environment
                    Write-Host "`nEnvironment `e[1;4m$envName`e[22;24m already exist. Updating..."
                    $cmd = "conda env update --file $CondaFile --prune$($envName -eq 'base' ? '' : ' --experimental-solver=libmamba')"
                    Invoke-Expression $cmd
                    Enter-CondaEnvironment $envName
                } else {
                    # *Update environment
                    Write-Host "Creating `e[1;4m$envName`e[22;24m environment."
                    conda env create --file $CondaFile --experimental-solver=libmamba
                    Enter-CondaEnvironment $envName
                }
                break
            }

            'activate' {
                # *Activate environment
                if ($envExists) {
                    Enter-CondaEnvironment $envName
                } else {
                    Write-Host "`e[1;4m$envName`e[22;24m environment doesn't exist!"
                }
                break

            }
            'remove' {
                # *Remove environment
                if ($envName -eq 'base') {
                    Write-Host "Cannot remove `e[1;4mbase`e[22;24m environment!"
                } elseif ($envExists) {
                    Write-Host "Removing `e[1;4m$envName`e[22;24m environment."
                    Invoke-Conda env remove --name $envName
                } else {
                    Write-Host "`e[1;4m$envName`e[22;24m environment doesn't exist!"
                }
                break
            }

            'deactivate' {
                # *Clean conda
                Exit-CondaEnvironment
                break
            }

            'packages' {
                # *List packages
                Invoke-Conda list
                break
            }

            'environments' {
                # *List environments
                Invoke-Conda env list
                break
            }

            'update' {
                # *Update conda
                conda update -y --name base --channel pkgs/main --update-all
                break
            }

            'clean' {
                # *Clean conda
                conda clean -y --all
                break
            }
        }
    }
}

<#
.SYNOPSIS
Setup Python virtual environment in the project and much more...
.EXAMPLE
. modules/do-common/Functions/python.ps1
Invoke-PySetup -o 'venv'         # *Setup python virtual environment
Invoke-PySetup -o 'delvenv'      # *Delete python virtual environment
Invoke-PySetup -o 'cleanup'      # *Delete all cache folders
Invoke-PySetup -o 'purgecache'   # *Purge pip cache
Invoke-PySetup -o 'reqs'         # *Install requirements
Invoke-PySetup -o 'upgrade'      # *Upgrade installed python modules
Invoke-PySetup -o 'sshkey'       # *Generate key pairs for SSH
Invoke-PySetup -o 'ssltrust'     # *Trust SSL connection to pypi.org
Invoke-PySetup -o 'setenv'       # *Set environment variables
Invoke-PySetup -o 'getenv'       # *Get environment variables
Invoke-PySetup -o 'list'         # *List installed modules
Invoke-PySetup -o 'activate'     # *Activate virtual environment
Invoke-PySetup -o 'deactivate'   # *Deactivate virtual environment
#>
function Invoke-PySetup {
    [CmdletBinding()]
    param (
        [Alias('o')]
        [Parameter(Mandatory)]
        [ValidateSet('venv', 'delvenv', 'cleanup', 'purgecache', 'reqs', 'upgrade', 'sshkey', 'ssltrust', 'setenv', 'getenv', 'list', 'activate', 'deactivate')]
        [string]$Option,

        [Alias('p')]
        [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "'{0}' is not a valid folder path.")]
        [string]$AppPath
    )

    begin {
        # constants
        $VENV_DIR = '.venv'
        $GITIGNORE = 'https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore'

        # calculate script variables
        $req_files = [Collections.Generic.List[string]]::new([string[]]@('requirements.txt'))
        if ($AppPath) {
            $appReq = [IO.Path]::Combine($AppPath, 'requirements.txt')
            if (Test-Path $appReq) {
                $req_files.Add($appReq)
            }
        }
        $req = @{
            name  = $req_files[0]
            value = "black`nflake8`nipykernel`nnotebook`npydocstyle`npylint`npypath-magic`n"
        }
        $localSettings = [IO.Path]::Combine($AppPath, 'local.settings.json')
        $activateScript = [IO.Path]::Combine($VENV_DIR, ($IsWindows ? 'Scripts' : 'bin'), 'Activate.ps1')
        $venvCreated = Test-Path $activateScript
        $initScript = [IO.Path]::Combine('.vscode', 'init.ps1')

        # get environment variables from local.settings.json file
        if ($option -in @('setenv', 'getenv')) {
            if (Test-Path $localSettings) {
                Write-Host "`e[96mUsing variables configured in local.settings.json.`e[0m"
                $envVars = (Get-Content ([IO.Path]::Combine($AppPath, 'local.settings.json')) | ConvertFrom-Json).Values
            } else {
                Write-Warning "File `e[1;3mlocal.settings.json`e[23m not exists!`n`t Set environment variables there."
                break
            }
        }
    }

    process {
        switch ($Option) {
            # *Activate virtual environment.
            { $_ -in @('activate', 'upgrade', 'venv') -and -not $env:VIRTUAL_ENV -and $venvCreated } {
                & $activateScript
                if ($Option -eq 'activate') {
                    break
                }
            }

            # *Deactivate virtual environment.
            { $_ -eq 'deactivate' -and $env:VIRTUAL_ENV } {
                deactivate
                break
            }

            # *Delete python virtual environment.
            'delvenv' {
                if ($env:VIRTUAL_ENV) {
                    deactivate
                }
                if (Test-Path $VENV_DIR) {
                    Write-Host "`e[96mDelete virtual environment.`e[0m"
                    Remove-Item $VENV_DIR -Recurse -Force
                } else {
                    Write-Host "`e[96mVirtual environment not exists.`e[0m"
                }
                break
            }

            # *Delete all cache folders
            'cleanup' {
                $dirs = Get-ChildItem -Directory -Exclude '.venv'
                foreach ($d in $dirs) {
                    if ($d.Name -match '_cache$|__pycache__') {
                        Remove-Item $d -Recurse -Force
                    } else {
                        @('*_cache', '__pycache__') | ForEach-Object {
                            [IO.Directory]::GetDirectories($d.FullName, $_, 1) | `
                                Remove-Item -Recurse -Force
                        }
                    }
                }
                break
            }

            # *Purge pip cache.
            'purgecache' {
                pip cache purge
                break
            }

            # *Generate key pairs for SSH authentication in remote repository.
            'sshkey' {
                if ($IsLinux) {
                    if (!(Test-Path '~/.ssh/id_rsa.pub')) {
                        # create new authentication key pairs for SSH if not exist
                        sh -c "ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ''"
                    }
                    Write-Host "`e[95mAdd below key to the repository's SSH keys:`e[0m"
                    Get-Content '~/.ssh/id_rsa.pub'
                } elseif ($IsWindows) {
                    Write-Host "`e[96mYou don't need to crete key for SSH, use HTTPS.`e[0m`n"
                }
                break
            }

            # *Trust SSL connection to pypi.org.
            'ssltrust' {
                if ($IsWindows) {
                    $pipLocation = "$env:APPDATA\pip\pip.ini"
                } elseif ($IsLinux -or $IsMacOS) {
                    $pipLocation = "$env:HOME/.config/pip/pip.conf"
                }
                $pipConfDir = [IO.Path]::GetDirectoryName($pipLocation)
                if (!(Test-Path $pipConfDir)) { New-Item $pipConfDir -ItemType Directory | Out-Null }
                Set-Content $pipLocation -Value "[global]`ntrusted-host = pypi.org`n`tpypi.python.org`n`tfiles.pythonhosted.org"
                break
            }

            # *Set project environment variables.
            'setenv' {
                # set environment targed depending on host system
                foreach ($prop in $envVars.PSObject.Properties) {
                    if ($IsWindows) {
                        [Environment]::SetEnvironmentVariable($prop.Name, $prop.Value, 'User')
                        # refresh environment
                        try {
                            RefreshEnv.cmd
                        } catch {
                            taskkill.exe /F /IM explorer.exe; Start-Process explorer.exe
                        }
                    } else {
                        if (!([Environment]::GetEnvironmentVariable($prop.Name))) {
                            "export $($prop.Name)=""$($prop.Value)""" >> ~/.profile
                        }
                    }
                }
                break
            }

            # *Get project environment variables.
            'getenv' {
                foreach ($prop in $envVars.PSObject.Properties) {
                    [PSCustomObject]@{
                        Variable = $prop.Name;
                        Value    = [Environment]::GetEnvironmentVariable($prop.Value)
                    }
                }
                break
            }

            # *List installed modules.
            'list' {
                python -m pip list --format=json | ConvertFrom-Json | Tee-Object -Variable modules | Format-Table
                $pipPath = (python -m pip -V) -replace '^.*from |pip \(.*$'
                Write-Host "`e[96m$(python -V) `e[0m|`e[96m $($modules.Count) modules installed in `e[1;34m$pipPath`e[0m"
                break
            }

            # *Setup python virtual environment.
            'venv' {
                # create virtual environment
                if ($null -eq $env:VIRTUAL_ENV) {
                    Write-Host "`e[96mSet up Python environment.`e[0m"
                    if (-not $venvCreated) {
                        python -m venv $VENV_DIR
                    }
                    # activate virtual environment
                    & $activateScript
                } else {
                    Write-Host "`e[96mVirtual environment already set.`e[0m"
                }
                # add files to the project
                if (-not (Test-Path '.gitignore')) {
                    Write-Host "`e[95madd Python .gitignore`e[0m"
                    [Net.WebClient]::new().DownloadFile($GITIGNORE, '.gitignore')
                }
                if (-not (Test-Path $req.name)) {
                    Write-Host "`e[95madd `e[1;3mrequirements.txt`e[22;23m with dev modules`e[0m"
                    New-Item $req.name -Value $req.value | Out-Null
                }
                if (-not (Test-Path $initScript)) {
                    Write-Host "`e[95mcreate `e[1;3minit.ps1`e[22;23m for virtual environment activation`e[0m"
                    $initContent = (
                        "#!/usr/bin/pwsh -nop`n#Requires -Version 7.0`n" +
                        "`$activateScript = [IO.Path]::Combine('$VENV_DIR', (`$IsWindows ? 'Scripts' : 'bin'), 'Activate.ps1')`n" +
                        "if (Test-Path `$activateScript) {`n`t& `$activateScript`n}`n"
                    )
                    New-Item -Path $initScript -Value $initContent -Force | Out-Null
                    if ($IsLinux) {
                        chmod +x $initScript
                    }
                }
            }

            # *Upgrade pip, wheel and setuptools.
            { $_ -in @('reqs', 'venv', 'upgrade') } {
                Write-Host "`e[95mupgrade pip, wheel and setuptools`e[0m"
                python -m pip install -U pip wheel setuptools
            }

            # *Install requirements.
            { $_ -in @('reqs', 'venv') } {
                if (Test-Path $req.name) {
                    # get modules from requirements files
                    $modules = $req_files | ForEach-Object { Get-Content $_ }
                }
                if ($modules) {
                    Write-Host "`e[95install requirements`e[0m"
                    $reqs_temp = 'reqs_temp.txt'
                    Set-Content -Path $reqs_temp -Value $modules
                    python -m pip install -U -r $reqs_temp
                    Remove-Item $reqs_temp
                }
                # add project path in virtual environment
                if ($env:VIRTUAL_ENV -and 'pypath-magic' -in $modules) {
                    pypath add ([IO.Path]::Combine($PWD, $AppPath)) 2>$null
                    pypath add $PWD 2>$null
                }
                break
            }

            # *Upgrade all modules.
            'upgrade' {
                $modules = (python -m pip list --format=json | ConvertFrom-Json).name
                if ($modules) {
                    Write-Host "`e[95mupgrade all modules`e[0m"
                    $reqs_temp = 'reqs_temp.txt'
                    Set-Content -Path $reqs_temp -Value $modules
                    python -m pip install -U -r $reqs_temp
                    Remove-Item $reqs_temp
                }
                break
            }
        }
    }
}
