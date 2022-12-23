function Update-SharedProfile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [String] $Url
    )

    $folder = Join-Path $env:USERPROFILE ".shared_profile"

    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder
    }

    $filePlain = Join-Path $folder "shared_profile.ps1"
    
    if (Test-Path $filePlain) {
        $d = (Get-Date).Subtract((Get-ChildItem $filePlain).LastWriteTimeUtc)
        if ($d.TotalDays -lt 1) {
            # return
        }
    }

    $fileEnc = Join-Path $folder "shared_profile.ps1.age.txt"
    Write-Progress -Activity "Downloading shared profile" -Status "Downloading $Url"
    Invoke-WebRequest -Uri $Url -OutFile $fileEnc | Out-Null
    if (!$?) {
        Write-Error "Failed to download $Url"
        return
    }
  
    # age -e -i (Join-Path $env:USERPROFILE ".shared_profile" "age-profile-key.txt") -a (Join-Path $env:USERPROFILE ".shared_profile" "shared_profile.ps1")

    $id = Join-Path $folder "age-profile-key.txt"
    age -d -i $id -o $filePlain $fileEnc
    if (!$?) {
        Write-Error "Failed to decrypt $fileEnc"
        return
    }
    Write-Host ("Updated Shared Profile SHA256: {0}" -f (Get-SharedProfileVersion))
}

function Get-SharedProfileVersion {
    $hash = Get-FileHash $filePlain -Algorithm SHA256
    return $hash.Hash.SubString(0,16)
}

function Execute-SharedProfile {
    $filePlain = Join-Path $env:USERPROFILE ".shared_profile" "shared_profile.ps1"
    Write-Host ("Execute Shared Profile SHA256: {0}" -f (Get-SharedProfileVersion))
    if (Test-Path $filePlain) {
        . $filePlain
    }else {
        Write-Error "Shared profile not found at $filePlain"
    }
}

function Test-SharedProfileInstallation {
    $keyfile = Join-Path $env:USERPROFILE ".shared_profile" "age-profile-key.txt"
    $result = $true
    if (-not (Test-Path $keyfile)) {
        Write-Error "Missing age key file $keyfile"
        $result = $false
    }
    if (-not (Get-Alias $name -ErrorAction SilentlyContinue)) {
        Write-Error "Missing age command"
        $result = $false
    }

    return $result
}

function New-EncryptedSharedProfile {
    if (-Not (Test-SharedProfileInstallation)) {
        Write-Error "Shared profile will not work until you have a key file and age command"
        return
     }

    age -e -i (Join-Path $env:USERPROFILE ".shared_profile" "age-profile-key.txt") -a (Join-Path $env:USERPROFILE ".shared_profile" "shared_profile.ps1")   
}

if (-Not (Test-SharedProfileInstallation)) {
    Write-Error "Shared profile will not work until you have a key file and age command"
}