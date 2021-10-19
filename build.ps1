# Copyright (c) Travis Plunk.
# Licensed under the MIT License.

param (
    [switch]
    $Test,
    [switch]
    $Bootstrap,
    [switch]
    $Publish,
    [string]
    $NuGetApiKey
)

if ($Bootstrap) {
    install-module SHIPS
}

if ($Test) {
    pwsh -c {
        get-psdrive -PSProvider ships -erroraction ignore | Remove-PSDrive
        import-module "./src/dotnet.project.assets.psd1" -force
        $null = new-padrive -name SampleProjectAssets -Path "./samples/project.assets.json"
        Push-Location SampleProjectAssets:
        Get-ChildItem -Recurse
    } -noexit -wd $psscriptroot
}

if($Publish) {
    Publish-Module -Path "$PSScriptRoot/src/dotnet.project.assets/" -NuGetApiKey $NuGetApiKey
}