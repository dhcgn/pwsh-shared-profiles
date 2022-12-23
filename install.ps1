<#
.SYNOPSIS
    Installs the Shared Profile

.NOTES
    {{Personal}} \PowerShell\Microsoft.VSCode_profile.ps1
    {{Personal}} \PowerShell\Microsoft.PowerShell_profile.ps1
    {{Personal}} \WindowsPowerShell\Microsoft.PowerShell_profile.ps1
    {{Personal}} \WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1    
#>
$scriptBlockVersion = "0.0.1"
$scriptBlock = @'
# START shared_profile
# shared_profile version: %%scriptBlockVersion%%

. (Join-Path $env:USERPROFILE ".shared_profile" ".ps1\manage.ps1")

Update-SharedProfile -Url "%%URL%%"
Execute-SharedProfile
# END shared_profile
'@

$scriptBlock = $scriptBlock.Replace("%%scriptBlockVersion%%", $scriptBlockVersion)

$personalFolder = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\' | ForEach-Object{$_.Personal}

$profiles = @(
    'PowerShell\Microsoft.VSCode_profile.ps1'
    'PowerShell\Microsoft.PowerShell_profile.ps1',
    'WindowsPowerShell\Microsoft.PowerShell_profile.ps1',
    'WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1'
    )

$url = Read-Host -Prompt "Deep direct url of the encrypted shared profile"

$isEncrypted = Invoke-WebRequest -Uri $url | ForEach-Object{$_.Content -like "*BEGIN AGE ENCRYPTED FILE*"}
if (-not $isEncrypted) {
    Write-Error "The url does not point to an encrypted file, not header BEGIN AGE ENCRYPTED FILE found."
    return
}

$scriptBlock = $scriptBlock.Replace("%%URL%%", $url)

foreach ($p in $profiles) {
    $fullpath = Join-Path $personalFolder $p

    if (-Not (Test-Path $fullpath )){
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

        $cRaw= Get-Content -Path $fullpath -Raw
        $cRaw = $cRaw -replace "(?ms)# START shared_profile.*# END shared_profile", $scriptBlock
        Set-Content -Path $fullpath -Value $cRaw

        continue
    }

    if ($content -notcontains ("# shared_profile version: {0}"-f $scriptBlockVersion)) {
        Write-Host "Updating $fullpath, because script block is not version $scriptBlockVersion"

        $cRaw= Get-Content -Path $fullpath -Raw
        $cRaw = $cRaw -replace "(?ms)# START shared_profile.*# END shared_profile", $scriptBlock
        Set-Content -Path $fullpath -Value $cRaw

        continue
    }
    
    
    Write-Host "Skipped $fullpath because it already contains the latest shared profile code block"
}
