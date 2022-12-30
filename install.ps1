<#
.SYNOPSIS
    Installs the Shared Profile

.NOTES
    {{Personal}} \PowerShell\Microsoft.VSCode_profile.ps1
    {{Personal}} \PowerShell\Microsoft.PowerShell_profile.ps1
    {{Personal}} \WindowsPowerShell\Microsoft.PowerShell_profile.ps1
    {{Personal}} \WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1    
#>

function Setup-Profiles {
    $scriptBlockVersion = "0.0.3"
    $scriptBlock = @'
# START shared_profile
# shared_profile version: %%scriptBlockVersion%%

. (Join-Path $env:USERPROFILE ".shared_profile\.ps1\manager.ps1")

Update-SharedProfile -Url "%%URL%%"
Execute-SharedProfile
# END shared_profile
'@

    $scriptBlock = $scriptBlock.Replace("%%scriptBlockVersion%%", $scriptBlockVersion)

    $personalFolder = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\' | ForEach-Object { $_.Personal }

    $profiles = @(
        'PowerShell\Microsoft.VSCode_profile.ps1'
        'PowerShell\Microsoft.PowerShell_profile.ps1',
        'WindowsPowerShell\Microsoft.PowerShell_profile.ps1',
        'WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1'
    )

    $url = Read-Host -Prompt "Deep direct url of the encrypted shared profile"

    $isEncrypted = Invoke-WebRequest -Uri $url | ForEach-Object { $_.Content -like "*BEGIN AGE ENCRYPTED FILE*" }
    if (-not $isEncrypted) {
        Write-Error "The url does not point to an encrypted file, not header BEGIN AGE ENCRYPTED FILE found."
        return
    }

    $scriptBlock = $scriptBlock.Replace("%%URL%%", $url)

    foreach ($p in $profiles) {
        $fullpath = Join-Path $personalFolder $p

        if (-Not (Test-Path $fullpath )) {
            $f = [System.IO.Path]::GetDirectoryName($fullpath)
            New-Item -Path $f -ItemType Directory -Force
            Set-Content -Path $fullpath -Value $scriptBlock
            Write-Host "Created $fullpath"

            continue
        }

        $content = Get-Content -Path $fullpath
        if ($content -notcontains "# START shared_profile" -and $content -notcontains "# END shared_profile") {
            $content += $scriptBlock
            Set-Content -Path $fullpath -Value $content
            Write-Host "Updated $fullpath"

            continue
        }
    
        if (-Not ($content -match $url)) {
            Write-Host "Updating $fullpath, because script block doen't contains url: $url"

            $cRaw = Get-Content -Path $fullpath -Raw
            $cRaw = $cRaw -replace "(?ms)# START shared_profile.*# END shared_profile", $scriptBlock
            Set-Content -Path $fullpath -Value $cRaw

            continue
        }

        if ($content -notcontains ("# shared_profile version: {0}" -f $scriptBlockVersion)) {
            Write-Host "Updating $fullpath, because script block is not version $scriptBlockVersion"

            $cRaw = Get-Content -Path $fullpath -Raw
            $cRaw = $cRaw -replace "(?ms)# START shared_profile.*# END shared_profile", $scriptBlock
            Set-Content -Path $fullpath -Value $cRaw

            continue
        }
    
    
        Write-Host "Skipped $fullpath because it already contains the latest shared profile code block"
    }
}

function Setup-FolderAndFiles {
    $folder = Join-Path $env:USERPROFILE ".shared_profile"
    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder
    }

    $scriptsFolder = Join-Path $env:USERPROFILE ".shared_profile\.ps1"
    if (!(Test-Path $scriptsFolder)) {
        New-Item -ItemType Directory -Path $scriptsFolder
    }

    $url = "https://raw.githubusercontent.com/dhcgn/pwsh-shared-profiles/main/manager.ps1"
    Invoke-WebRequest -Uri $url -OutFile (Join-Path $scriptsFolder "manager.ps1") -Headers @{"Cache-Control" = "no-cache" }

    $url = "https://raw.githubusercontent.com/dhcgn/pwsh-shared-profiles/main/install.ps1"
    Invoke-WebRequest -Uri $url -OutFile (Join-Path $scriptsFolder "install.ps1") -Headers @{"Cache-Control" = "no-cache" }

    $url = "https://raw.githubusercontent.com/dhcgn/pwsh-shared-profiles/main/README.md"
    Invoke-WebRequest -Uri $url -OutFile (Join-Path $folder "README.md") -Headers @{"Cache-Control" = "no-cache" }
}

function Check {
    $keyfile = Join-Path $env:USERPROFILE ".shared_profile\age-profile-key.txt"
    if (-not (Test-Path $keyfile)) {
        Write-Error "Missing age key file $keyfile, please create a key file with age-keygen and copy the key to $keyfile"
    }
    if (-not (Get-Alias age -ErrorAction SilentlyContinue)) {
        Write-Error "Missing age command, please install age and add it to the path or your profile"
    }
}

function Download-AgeEncryption {
    $assetsFolder = Join-Path $env:USERPROFILE ".shared_profile\bin"
    if (Test-Path "$assetsFolder\age\age.exe") {
        return
    }
    
    if (!(Test-Path $assetsFolder)) {
        New-Item -ItemType Directory -Path $assetsFolder
    }

    $ageurl = "https://github.com/FiloSottile/age/releases/download/v1.1.0/age-v1.1.0-windows-amd64.zip"
    
    Invoke-WebRequest -Uri $ageurl -OutFile "$assetsFolder\age.zip"; 
    Expand-Archive -Path "$assetsFolder\age.zip" -DestinationPath $assetsFolder
    Remove-Item "$assetsFolder\age.zip"

    if (-Not (Test-Path "$assetsFolder\age\age.exe")) {
        Write-Error "Failed to download age"
    }   
}

Setup-FolderAndFiles
Setup-Profiles
Download-AgeEncryption

Check