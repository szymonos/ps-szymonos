# ps-szymonos

Repository for my *devops* PowerShell modules.

## Modules

### **do-common**

Common module not depending on other modules, working on all systems.

``` PowerShell
./install.ps1 -Module 'do-common'
# install module and clean-up old versions
./install.ps1 -Module 'do-common' -CleanUp
```

### **do-az**

Module intended to streamline work with Microsoft Azure Cloud.

``` PowerShell
./install.ps1 -Module 'do-az'
# install module without requirements to speed up loading and clean-up old versions
./install.ps1 -Module 'do-az' -CleanUp -RemoveRequirements
```

### **do-win**

Module intended to streamline work on Windows.

``` PowerShell
./install.ps1 -Module 'do-win'
# install module and clean-up old versions
./install.ps1 -Module 'do-win' -CleanUp
```
