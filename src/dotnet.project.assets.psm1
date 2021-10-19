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
        #$result += [ProjectAssetsVersion]::new()

        $result += [TargetContainer]::new()

        $result += [LibraryContainer]::new()
        # $result += [packageFolders]::new()
        # $result += [project]::new()
        return $result
    }
}

class TargetContainer : SHiPSDirectory {
    TargetContainer():base('Targets') {
    }

    [object[]] GetChildItem() {
        $result = @()
        $targets = [ProjectAssets]::Json.targets | ForEach-Object { Get-MemberName -object $_ }
        foreach ($target in $targets) {
            $result += [Target]::new($target)
        }
        return $result
    }

    [string] GetValue(){
        return ''
    }
}

class LibraryContainer : SHiPSDirectory {
    LibraryContainer():base('Libraries') {

    }
    [object[]] GetChildItem() {
        $result = @()
        $libraries = [ProjectAssets]::Json.libraries | ForEach-Object { Get-MemberName -object $_ }
        foreach ($library in $libraries) {
            $result += [Library]::new($library)
        }
        return $result
    }

    [string] GetValue(){
        return ''
    }
}

class Library : SHiPSDirectory {
    [string] $Path
    [Object] $Library
    [string] $Sha512
    Library([string]$name) {
        $this.Library = [ProjectAssets]::Json.libraries.$name
        $this.Path = $this.Library.Path
        $this.name = $name -replace '/', '-'
        $target = $this.OriginalName
        $this.Sha512 = $this.Library.Sha512
    }

    [object[]] GetChildItem() {
        $result = @()
        $files = $this.Library.files
        foreach ($file in $files) {
            $result += [PAFile]::new($file)
        }
        return $result
    }

    [string] GetValue(){
        return "sha512: $($this.sha512)"
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

    [string] GetValue(){
        return ''
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
            $result += [DependencyContainer]::new($this.Reference.dependencies)
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

    [string] GetValue(){
        return ''
    }
}

class DependencyContainer : SHiPSDirectory {
    [object] $dependencies
    DependencyContainer ([object]$dependencies) : base('Dependencies') {
        $this.dependencies = $dependencies
    }

    [object[]] GetChildItem() {
        $result = @()
        $dependencyNames = Get-MemberName -Object $this.dependencies
        foreach ($dependency in $dependencyNames) {
            $result += [Dependency]::new($dependency, $this.dependencies.$dependency)
        }
        return $result
    }

    [string] GetValue(){
        return ''
    }
}

class Package : Reference {
    Package([string]$name, [object]$packageObject) : base($name, $packageObject) {
    }

    [string] GetValue(){
        return 'Package'
    }
}

class Project : Reference {
    Project([string]$name, [object]$packageObject):base($name, $packageObject) {
    }

    [string] GetValue(){
        return 'Project'
    }
}

class Dependency : SHiPSLeaf {
    [string]$Version
    Dependency ([string]$name, [string] $Version) {
        $this.name = $name
        $this.Version = $Version
    }

    [string] GetValue(){
        return $this.Version
    }
}

class PAFile : SHiPSLeaf {
    [string]$Path
    PAFile(){}

    PAFile([string]$name):base($name) {
        $this.Path = $name
    }

    [string] GetValue(){
        return $this.Path
    }
}

class RTFile : PAFile {
    [string] $AssetType
    [string] $Rid

    RTFile([string]$name,[string]$assetType,[string]$rid) {
        $this.name = $name
        $this.AssetType = $assetType
        $this.Rid = $rid
    }

    [string] GetValue(){
        return "AssetType: $($this.AssetType); RID: $($this.Rid)"
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

    [string] GetValue(){
        return ''
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

    [string] GetValue(){
        return ''
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

    [string] GetValue(){
        return ''
    }
}

class ProjectAssetsVersion : SHiPSLeaf {
    [string]$Version
    ProjectAssetsVersion () : base ('version') {
        $this.Version = [ProjectAssets]::Json.version
    }

    [string] GetValue(){
        return $this.Version
    }
}
