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
        # $result += [Targets]::new()
        # $result += [Libraries]::new()
        # $result += [projectFileDependencyGroups]::new()
        # $result += [packageFolders]::new()
        # $result += [project]::new()
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
