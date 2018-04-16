Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$USERNAME,
    [Parameter(Mandatory=$True,Position=2)]
    [string]$PASSLENGTH,
    [Parameter(Mandatory=$True,Position=3)]
    [string]$VAULTURL
)

# Credit: https://blogs.technet.microsoft.com/undocumentedfeatures/2016/09/20/powershell-random-password-generator/
$NEWPASS = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | sort {Get-Random})[0..$PASSLENGTH] -join ''
$SECUREPASS = ConvertTo-SecureString $NEWPASS -AsPlainText -Force
$JSON = "{ `"options`": { `"max_versions`": 3 }, `"data`": { `"root`": `"$NEWPASS`" } }"

# Renew our token before we do anything else.
$token_renew_response = Invoke-RestMethod -Headers @{"X-Vault-Token" = "fcd45f84-4802-d9ec-d779-8b4fd4bec574"} -Method POST -Uri ${VAULTURL}/v1/auth/token/renew-self
if(-Not $?)
{
   Write-Output "Error renewing Vault token lease."
}

# First commit the new password to vault, then change it locally.
$password_update_response = Invoke-RestMethod -Headers @{"X-Vault-Token" = "fcd45f84-4802-d9ec-d779-8b4fd4bec574"} -Method POST -Body $JSON -Uri ${VAULTURL}/v1/secret/data/windows/$($env:computername)/${USERNAME}_creds
if($?) {
   Write-Output "Vault updated with new password."
   $UserAccount = Get-LocalUser -name $USERNAME
   $UserAccount | Set-LocalUser -Password $SECUREPASS
   if($?) {
       Write-Output "${USERNAME}'s password was stored in Vault and updated locally."
   }
   else {
       Write-Output "Error: ${USERNAME}'s password was stored in Vault but *not* updated locally."
   }
}
else {
    Write-Output "Error saving new password to Vault. Local password will remain unchanged."
}

$NEWPASS