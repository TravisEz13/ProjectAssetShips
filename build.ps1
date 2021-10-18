# Copyright (c) Travis Plunk.
# Licensed under the MIT License.

param (
    [switch]
    $Test,
    [switch]
    $Bootstrap

)

if ($Bootstrap) {
    install-module SHIPS
}

if ($Test) {
    pwsh -c {
        get-psdrive -PSProvider ships -erroraction ignore | Remove-PSDrive
        import-module "./src/dotnet.project.assets.psd1" -force -Verbose
        new-padrive -name SampleProjectAssets -Path "./samples/project.assets.json"
        Push-Location SampleProjectAssets:
    } -noexit -wd $psscriptroot
}