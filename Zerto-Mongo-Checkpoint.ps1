##############################################################
# Zerto-mongo-checkpoint.ps1
# 
# By Justin Paul, Zerto Technical Alliances Architect
# Contact info: jp@zerto.com, @recklessop on twitter
# Repo: https://www.github.com/Zerto-ta-public/MongoDB-Journal-Checkpoints
#
# Full Howto on my blog - https://www.jpaul.me/?p=12645
#
##############################################################

#User customizable variables

#Zerto Info
$VPGName = "Mongo to Azure"
$ZVMServer = "172.16.1.20"
$ZVMPort = 9080
$ZVMUser = "administrator"
$ZVMPass = "password"

#Mongo information
$MongoServer = "172.16.1.76"
$MongoUser = "justin"
$MongoPass = "password"
$privateKey = "C:\id_rsa"

################ No editing needed below this line ##############
Add-PSSnapin Zerto.PS.Commands

$frozen = $false
$tries = 0

$nopasswd = new-object System.Security.SecureString
$Credential = New-Object System.Management.Automation.PSCredential ($MongoUser, $nopasswd)

$session = New-SSHSession -ComputerName $MongoServer -ea Stop -AcceptKey:$true -Credential $Credential -KeyFile $privatekey
If (!$session.Connected)
{
    Write-Host "Could Not establish SSH Connection to $MongoServer"
    exit
}

write-host "SSH Connected"
$SSHId = $session.SessionId

# Freeze MongoDB
Write-Host "Freezing MongoDB..."

while ((!$frozen) -or ($tries -gt 3)) {
    $tries++
    $RespFreeze = Invoke-SSHCommand -Command "/usr/local/bin/mongo_freeze.sh" -SessionId $SSHId
    $frozen = $RespFreeze.Output -match 'now locked'
}
if($tries -gt 3) {
    Write-Host "Unable to freeze MongoDB. Exiting..."
    Exit
}
Write-Host "MongoDB Frozen."
$frozen = $true



#Do Zerto Check Point
$checkpointInfo = ""
Write-Host "Calling ZVM..."
$checkpointInfo = Set-Checkpoint $ZVMServer $ZVMPort -Username $ZVMUser -Password $ZVMPass -VirtualProtectionGroup $VPGName -Tag 'MongoDB Frozen by Zerto' -Confirm:$false
If ($checkpointInfo)
{
    Write-Host "Checkpoint Inserted."
} else {
    Write-Host "Unable to Insert Zerto User Checkpoint"
}

#Unfreeze MongoDB
Write-Host "Unfreezing MongoDB..."

while ($frozen) {
    $UnFreeze = Invoke-SSHCommand -Command "mongo_unfreeze.sh" -SessionId $SSHId
    $frozen = $UnFreeze.Output -match 'unlock completed'
}
if(!$frozen) {
    Write-Host "MongoDB has been unfrozen"
}

#remove our ssh session
$disconnect = Remove-SSHSession $session

if($disconnect) {
    Write-Host "SSH Disconnected"
}