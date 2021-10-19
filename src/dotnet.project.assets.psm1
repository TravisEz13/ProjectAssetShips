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
class ProjectAssets : Microsoft.PowerShell.SHiPS.SHiPSDirectory {
    static [Object] $Json
    static [String] $Path

    ProjectAssets () {
        $this.Name = 'spa'
    }

    ProjectAssets([string]$name):base($name) {
    }

    [object[]] GetChildItem() {
        $result = @()
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

class Target : SHiPSDirectory {
    Target([string]$name):base($name) {
    }

    [object[]] GetChildItem() {
        $result = @()
        $target = $this.Name
        $packages = [ProjectAssets]::Json.targets.$target
        foreach ($packageName in (Get-MemberName -Object $packages)) {
            $package = $packages.$packageName
            if ($package.Type -eq 'package') {
                Write-Verbose "adding package: $packageName"
                $result += [Package]::new($packageName, $package)
            }
        }
        foreach ($projectName in (Get-MemberName -Object $packages)) {
            $project = $packages.$projectName
            if ($project.Type -eq 'project') {
                $result += [Project]::new($projectName, $project)
            }
        }
        return $result
    }
}

class Reference  : SHiPSDirectory {
    [object]$Reference

    Reference([string]$name, [object]$Reference) {
        $this.Reference = $Reference
        $this.name = $name -replace '/', '-'
    }

    [object[]] GetChildItem() {
        $result = @()
        if ($this.Reference.dependencies) {
            $dependencyNames = Get-MemberName -Object $this.Reference.dependencies
            foreach ($dependency in $dependencyNames) {
                $result += [Dependency]::new($dependency, $this.Reference.dependencies.$dependency)
            }
        }
        if ($this.Reference.runtime) {
            $runtimes = Get-MemberName -Object $this.Reference.runtime
            foreach ($runtime in $runtimes) {
                $result += [Runtime]::new($runtime)
            }
        }

        if ($this.Reference.compile) {
            $names = Get-MemberName -Object $this.Reference.compile
            foreach ($name in $names) {
                $result += [Compile]::new($name)
            }
        }

        if ($this.Reference.runtimeTargets) {
            $names = Get-MemberName -Object $this.Reference.runtimeTargets
            foreach ($name in $names) {
                $assetType = $this.Reference.runtimeTargets.$name.assetType
                $rid  = $this.Reference.runtimeTargets.$name.rid
                $result += [RuntimeTarget]::new($name, $assetType, $rid)
            }
        }

        return $result
    }
}

class Package : Reference {
    Package([string]$name, [object]$packageObject) : base($name, $packageObject) {
    }
}

class Project : Reference {
    Project([string]$name, [object]$packageObject):base($name, $packageObject) {
    }
}

class Dependency : SHiPSLeaf {
    [string]$Version
    Dependency ([string]$name, [string] $Version) {
        $this.name = $name
        $this.Version = $Version
    }
}

class PAFile : SHiPSLeaf {
    PAFile(){}

    PAFile([string]$name):base($name) {}
}

class RTFile : PAFile {
    [string] $AssetType
    [string] $Rid

    RTFile([string]$name,[string]$assetType,[string]$rid) {
        $this.name = $name
        $this.AssetType = $assetType
        $this.Rid = $rid
    }
}


class RuntimeTarget : SHiPSDirectory {
    [string]$File
    [string] $AssetType
    [string] $Rid
    RuntimeTarget ([string]$name,[string]$assetType,[string]$rid) {
        $this.File = $name
        $this.Name = "RuntimeTarget"
        $this.AssetType = $assetType
        $this.Rid = $rid
    }

    [object[]] GetChildItem() {
        $result = @()
        $result += [RTFile]::new($this.File,$this.AssetType,$this.Rid)
        return $result
    }
}

class Runtime : SHiPSDirectory {
    [string]$File
    Runtime ([string]$name) {
        $this.File = $name
        $this.Name = "Runtime"
    }

    [object[]] GetChildItem() {
        $result = @()
        $result += [PAFile]::new($this.File)
        return $result
    }
}

class Compile : SHiPSDirectory {
    [string]$File
    Compile ([string]$name) {
        $this.File = $name
        $this.Name = "Compile"
    }

    [object[]] GetChildItem() {
        $result = @()
        $result += [PAFile]::new($this.File)
        return $result
    }
}

class ProjectAssetsVersion : SHiPSLeaf {
    [string]$Version
    ProjectAssetsVersion () : base ('version') {
        $this.Version = [ProjectAssets]::Json.version
    }
}
