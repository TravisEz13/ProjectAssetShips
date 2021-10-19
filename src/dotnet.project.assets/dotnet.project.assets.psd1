# Copyright (c) Travis Plunk.
# Licensed under the MIT License.

@{

    # Script module or binary module file associated with this manifest.
    RootModule = './dotnet.project.assets.psm1'

    # Version number of this module.
    ModuleVersion = '0.1.1'

    # ID used to uniquely identify this module
    GUID = '24de7451-0f71-4e7a-8209-7c9d48900550'

    # Author of this module
    Author = 'Travis Plunk'

    Description = 'SHiPs provider for project.assets.json files'

    # Company or vendor of this module
    CompanyName = 'Unknown'

    # Copyright statement for this module
    Copyright = '(c) 2021 Travis Plunk. All rights reserved.'

    RequiredModules = @("SHiPS")

    FunctionsToExport = 'New-PADrive'

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @('dotnet.project.assets.ps1xml')
}