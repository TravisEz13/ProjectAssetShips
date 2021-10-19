# Copyright (c) Travis Plunk.
# Licensed under the MIT License.

using namespace Microsoft.PowerShell.SHiPS

function New-PADrive {
    param (
        [string]
        $Path,
        [string]
        $Name
    )

    [ProjectAssets]::Path = $Path
    [ProjectAssets]::Json = (Get-Content -Path $Path | ConvertFrom-Json)

    Get-PSDrive
    New-PSDrive -Name $Name -PSProvider SHiPS -Root 'dotnet.project.assets#ProjectAssets' -Scope Global
}

function Get-MemberName {
    param(
        [object]$object
    )

    ($object | Get-Member -Type NoteProperty).Name
}

[SHiPSProvider()]
class ProjectAssets : Microsoft.PowerShell.SHiPS.SHiPSDirectory
{
    static [Object] $Json
    static [String] $Path

    ProjectAssets ()
    {
        $this.Name     = 'spa'
    }

    ProjectAssets([string]$name):base($name)
    {
    }

    [object[]] GetChildItem()
    {
        $result =  @()
        $result += [ProjectAssetsVersion]::new()
        $targets = [ProjectAssets]::Json.targets | ForEach-Object { Get-MemberName -object $_ }
        foreach ($target in $targets) {
            $result += [Target]::new($target)
        }
        # $result += [Libraries]::new()
        # $result += [projectFileDependencyGroups]::new()
        # $result += [packageFolders]::new()
        # $result += [project]::new()
        return $result
    }
}

class Target : SHiPSDirectory
{
    Target([string]$name):base($name)
    {
    }

    [object[]] GetChildItem()
    {
        $result =  @()
        $target = $this.Name
        $packages = [ProjectAssets]::Json.targets.$target
        #$packages = $packages | ForEach-Object { $_ | ft | out-string | Write-Verbose -Verbose}
        foreach($packageName in (Get-MemberName -Object $packages))
        {
            $package = $packages.$packageName
            if($package.Type -eq 'package'){
                $result += [Package]::new($packageName, $package)
            }
        }
        foreach($projectName in (Get-MemberName -Object $packages))
        {
            $project = $packages.$projectName
            if($project.Type -eq 'project'){
                $result += [Project]::new($projectName, $project)
            }
        }
        #TODO add projects
        return $result
    }
}

class Package : SHiPSDirectory
{
    [object]$Package

    Package([string]$name,[object]$packageObject)
    {
        $this.Package = $packageObject
        $this.name = $name -replace '/', '-'
    }

    [object[]] GetChildItem()
    {
        $result =  @()
        if($this.Package.dependencies) {
            $dependencyNames = Get-MemberName -Object $this.Package.dependencies
            foreach($dependency in $dependencyNames) {
                $result += [Dependency]::new($dependency,$this.Package.dependencies.$dependency)
            }
        }
        #$result += [compile]::new($target)
        #runtime
        #runtimeTargets

        return $result
    }
}

class Dependency : SHiPSLeaf {
    [string]$Version
    Dependency ([string]$name, [string] $Version) {
        $this.name = $name
        $this.Version = $Version
    }
}

class Project : SHiPSDirectory
{
    [object]$Package

    Project([string]$name, [object]$packageObject)
    {
        $this.Package = $packageObject
        $this.name = $name -replace '/', '-'
    }

    [object[]] GetChildItem()
    {
        $result =  @()
        if($this.Package.dependencies) {
            $dependencyNames = Get-MemberName -Object $this.Package.dependencies
            foreach($dependency in $dependencyNames) {
                $result += [Dependency]::new($dependency,$this.Package.dependencies.$dependency)
            }
        }
        #framework
        #$result += [dependencies]::new($target)
        #$result += [compile]::new($target)
        #runtime

        return $result
    }
}

class ProjectAssetsVersion : SHiPSLeaf
{
    [string]$Version
    ProjectAssetsVersion () : base ('version')
    {
        $this.Version = [ProjectAssets]::Json.version
    }
}
