# pwsh-shared-profiles

Under heavy development! Don't use yet!

## Motivation

I want on each computer in each powershell profile the same scripts, these must be kept in sync and be encrypted.

### Each powershell profile?

- VSCode `{{Personal}} \PowerShell\Microsoft.VSCode_profile.ps1`
- Powershell 7 `{{Personal}} \PowerShell\Microsoft.PowerShell_profile.ps1`
- Powershell Legacy `{{Personal}} \WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
- Powershell ISE `{{Personal}} \WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1`

### Encrypted?

The shared powershell script is encrypted with  [age-encryption.org](https://age-encryption.org/) so it can be stored publicly.

A unprotected but not the same AGE-SECRET-KEY must be placed on each computer.

### in sync

Age encrypted file can be stored publicly, e.g. with a not guessable  link.

### Prerequisite

1. Age encrypted file of a powershell script, which should be executed on each powershell profile
1. This files must be placed in a publicly storage.

## How to use

## Prepare

1. 

## Install

```pwsh
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/dhcgn/pwsh-shared-profiles/main/install.ps1'))
```