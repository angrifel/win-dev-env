function Set-NodeJSVersion([string] $Version, [string] $Architecture) {
    [string] $nodeVersionDirectory = Get-NodeJSVersionDirectory $Version $Architecture
    if (-not (Test-Path -Path $nodeVersionDirectory -PathType Container)) {
        throw "nodejs version not found at $nodeVersionDirectory"
    }

    SetPathEnvironmentToNodeVersion $nodeVersionDirectory
}

function Get-NodeJSVersionDirectory([string] $Version, [string] $Architecture) {
    [string] $root = Get-NodeJSDistributionDirectory
    [string] $nodeVersionDirectory = "$root\node-v$Version-win-$Architecture"
    return  $nodeVersionDirectory
}

function Get-NodeJSDistributionDirectory {
    return "c:\env\nodejs\dist"
}


function Get-NodeJSInstalledVersion {
    [string] $root = Get-NodeJSDistributionDirectory
    return Get-ChildItem -Path $Root | foreach {$_.Name}
}

function Install-NodeJS([string] $Version, [string] $Architecture) {
    if (Test-Path -Path (Get-NodeJSVersionDirectory $Version $Architecture) -PathType Container) {
        Write-Host 'Already installed'
        return
    }

    [string] $sourcesRoot = 'https://nodejs.org/dist'
    [string] $fileName = "node-v$Version-win-$Architecture.zip"
    [string] $tempDownloadDirectory = [System.IO.Path]::GetTempPath() + "\" + [System.IO.Path]::GetRandomFileName()
    [string] $source = "$sourcesRoot/v$version/$fileName"
    [string] $tempDestination = "$tempDownloadDirectory\$fileName"
    [string] $extractionDirectory = Get-NodeJSDistributionDirectory
    
    try {
        [void](Add-Type -AssemblyName System.IO.Compression.FileSystem)
        [void](New-Item -Path $tempDownloadDirectory -ItemType Container)
        [void](Start-BitsTransfer -Source $source -Destination $tempDestination -DisplayName "NodeJS v$Version-$Architecture" -Description "Getting NodeJS v$Version-$Architecture")
        [void](Expand-Archive -Path $tempDestination -DestinationPath $extractionDirectory)
    }
    finally {
        if (Test-Path -Path $tempDownloadDirectory -PathType Container) {
            Remove-Item -Path $tempDownloadDirectory -Recurse
        }
    }
}

function GetNodeJsRoot() {
    return "c:\env\nodejs"
}
function SetPathEnvironmentToNodeVersion([string] $newVersionRoot) {
    [string] $root = Get-NodeJSDistributionDirectory
    [string] $path = [System.Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::User)
    [string[]] $components = $path.Split(';', [StringSplitOptions]::None)
    [int] $index = 0
    [int] $found = -1
    while ($index -lt $components.Length) {
         if ($components[$index].StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
             $found = $index
         }
         
         $index += 1
    }

    [string] $newPath = ""

    if ($found -eq -1) {
        $newPath = "$newVersionRoot;$path"
    }
    else {
        $components[$found] = $newVersionRoot
        $newPath = [string]::Join(';', $components)
    }
    
    [string] $nodeREPLHistory = "$newVersionRoot\.node_repl_history"
    [void][System.Environment]::SetEnvironmentVariable('PATH', $newPath, [EnvironmentVariableTarget]::User)
    [void][System.Environment]::SetEnvironmentVariable('NODE_REPL_HISTORY', $nodeREPLHistory, [EnvironmentVariableTarget]::User)
}

Export-ModuleMember -Function Set-NodeJSVersion
Export-ModuleMember -Function Get-NodeJSVersionDirectory
Export-ModuleMember -Function Get-NodeJSDistributionDirectory
Export-ModuleMember -Function Install-NodeJS
Export-ModuleMember -Function Get-NodeJSInstalledVersion