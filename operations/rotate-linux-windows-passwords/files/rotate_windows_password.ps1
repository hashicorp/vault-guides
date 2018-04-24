Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$USERNAME,
    [Parameter(Mandatory=$True,Position=2)]
    [string]$PASSLENGTH,
    [Parameter(Mandatory=$True,Position=3)]
    [string]$VAULTURL
)

# Inspired by https://daniel.streefkerkonline.com/2016/05/19/correct-horse-battery-staple-for-powershell-aka-random-memorable-password-generator/
# This function will generate longer phrase based passwords.
function Get-RandomPassword {
    
    [OutputType([string])]
    Param
    (
        [int]
        $Count = 1,

        [string]
        $Separator = '-'
    )
    $words = (Invoke-WebRequest 'https://s3.amazonaws.com/password-rotation-demo-files/wordlist.txt' | Select-Object -ExpandProperty Content).Split(',')
    1..$Count | ForEach-Object {"$([string]::Join($Separator,(1..4 | ForEach-Object {[cultureinfo]::CurrentCulture.TextInfo.ToTitleCase(($words | Get-Random))})))$Separator$(1..99 | Get-Random)"}
}

# This snippet generates random passwords of a specified length
# Credit: https://blogs.technet.microsoft.com/undocumentedfeatures/2016/09/20/powershell-random-password-generator/
$NEWPASS = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | Sort-Object {Get-Random})[0..$PASSLENGTH] -join ''
# Use this instead if you want phrase-based passwords instead.
# $NEWPASS = Get-RandomPassword
$SECUREPASS = ConvertTo-SecureString $NEWPASS -AsPlainText -Force
$JSON = "{ `"options`": { `"max_versions`": 3 }, `"data`": { `"Administrator`": `"$NEWPASS`" } }"

# Renew our token before we do anything else.
Invoke-RestMethod -Headers @{"X-Vault-Token" = $env:VAULT_TOKEN} -Method POST -Uri ${VAULTURL}/v1/auth/token/renew-self
if(-Not $?)
{
   Write-Output "Error renewing Vault token lease."
}

# First commit the new password to vault, then change it locally.
Invoke-RestMethod -Headers @{"X-Vault-Token" = $env:VAULT_TOKEN} -Method POST -Body $JSON -Uri ${VAULTURL}/v1/secret/data/windows/$($env:computername)/${USERNAME}_creds
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