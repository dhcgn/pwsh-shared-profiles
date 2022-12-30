function Update-SharedProfile {
    param(
        [Parameter(Mandatory = $true)] [String] $Url,
        [switch] $Force
    )

    if (-Not (Test-SharedProfileInstallation)) {
        return
    }

    $folder = Join-Path $env:USERPROFILE ".shared_profile"

    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder
    }

    $filePlain = Join-Path $folder "shared_profile.ps1"
    
    if (Test-Path $filePlain) {
        $d = (Get-Date).Subtract((Get-ChildItem $filePlain).LastWriteTimeUtc)
        if ($d.TotalDays -lt 1 && -Not $Force) {
            # TODO be more smart
            return
        }
    }

    $fileEnc = Join-Path $folder "ps1.age.txt"
    Write-Progress -Activity "Downloading shared profile" -Status "Downloading $Url"
    Invoke-WebRequest -Uri $Url -OutFile $fileEnc | Out-Null
    if (!$?) {
        Write-Error "Failed to download $Url"
        return
    }
  
    # age -e -i (Join-Path $env:USERPROFILE ".shared_profile" "age-profile-key.txt") -a (Join-Path $env:USERPROFILE ".shared_profile\shared_profile.ps1")

    $id = Join-Path $folder "age-profile-key.txt"
    age -d -i $id -o $filePlain $fileEnc
    if (!$?) {
        Write-Error "Failed to decrypt $fileEnc"
        return
    }
    Write-Host ("Updated Shared Profile SHA256: {0}" -f (Get-SharedProfileHash))
}

function Get-SharedProfileHash {
    $filePlain = Join-Path $env:USERPROFILE ".shared_profile\shared_profile.ps1"
    $hash = Get-FileHash $filePlain -Algorithm SHA256
    return $hash.Hash.SubString(0, 16)
}

function Execute-SharedProfile {
    $filePlain = Join-Path $env:USERPROFILE ".shared_profile\shared_profile.ps1"
    if (Test-Path $filePlain) {
        Write-Host ("Execute Shared Profile SHA256: {0}" -f (Get-SharedProfileHash))
        . $filePlain
    }
    else {
        Write-Host "Shared profile not found at $filePlain" -ForegroundColor Red
    }
}

function Test-SharedProfileInstallation {
    $keyfile = Join-Path $env:USERPROFILE ".shared_profile\age-profile-key.txt"
    $result = $true
    if (-not (Test-Path $keyfile)) {
        # Write-Host "Missing age key file $keyfile"
        $result = $false
    }
    if (-not (Get-Alias age -ErrorAction SilentlyContinue)) {
        # Write-Host "Missing age command"
        $result = $false
    }

    return $result
}

$ageexecutable = Join-Path $env:USERPROFILE ".shared_profile\bin\age\age.exe"
if (Test-Path $ageexecutable) {
    Set-Alias -Name age -Value $ageexecutable
}

function New-EncryptedSharedProfile {
    if (-Not (Test-SharedProfileInstallation)) {
        Write-Error "Shared profile will not work until you have a key file and age command"
        return
    }

    Write-Host "This will only encrypt the shared_profile.ps1 with the key file in .shared_profile\age-profile-key.txt, if you use multiple keys, you will need to encrypt the file yourself!" -ForegroundColor Yellow
    age -e -i (Join-Path $env:USERPROFILE ".shared_profile\age-profile-key.txt") -a (Join-Path $env:USERPROFILE ".shared_profile\shared_profile.ps1")   
}

if (-Not (Test-SharedProfileInstallation)) {
    Write-Host "Shared profile will not work until you have a key file and age command" -ForegroundColor Red
}
