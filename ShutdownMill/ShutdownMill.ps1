<#
.SYNOPSIS
This script along with several subscripts comprise the shutdown process for the J61 Mill Nutanix Cluster (MPMSNTXB).

Author: Michael Becker (mbecker@mpmaterials.com)
https://github.com/Mainframe79

.DESCRIPTION
This script along with several subscripts comprise the shutdown process for the J61 Mill Nutanix Cluster (MPMSNTXB) at the MPM Mine Site.
Additionally when available we power down the physical domain controller.

This must be run from PS 7 due to the Nutanix Cmdlets

This is assumed to be running as admin ring 2 account from the LASJMP01 jumpbox.
If you are running this from another machine, ensure the pre-requisites are installed.

.NOTES
These modules are required in PS7:
    Nutanix.cli
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

    To Install Nutanix.cli module, run the following command in an elevated PowerShell session on J61Tools01:
    "E:\Nutanix\cmdlets\Install-NutanixCmdlets.ps1"
    Upon completion, you should be able to import the Nutanix modules as shown below.


When we import the nutanix modules with a prefix so as to attempt to not clobber over Hyper-V cmdlets.
    Import-Module Nutanix.Prism.PS.Cmds -Prefix NTNX
    Import-Module Nutanix.Prism.Common -Prefix NTNX

#>
# MP Logo and script title
(Write-Host "MP Materials, LLC" -ForegroundColor "Blue" -BackgroundColor "White")
(Write-Host "J61 Mill Nutanix Cluster (MPMSNTXB) Power Down Routine"  -ForegroundColor "Blue" -BackgroundColor "White")

#get prism central local admin
$prismcred = Get-Credential -UserName "admin" -Message "Enter J61 Mill Prism Central local admin credentials - Bitwarden 'mpm mine prism central admin'"

##Import Nutanix Modules####
Import-Module Nutanix.Prism.PS.Cmds -Prefix NTNX
Import-Module Nutanix.Prism.Common -Prefix NTNX

##Stop J61 Mill Nutanix VM's####
Connect-PrismCentral -Server j61prism01.j61.scada -Credential $prismCred -AcceptInvalidSSLCerts -ForcedConnection
$vms = get-ntnxvm -clustername MPMSNTXB

foreach ($vm in $vms)
    {
    if ($vm.powerstate -eq 'on')
        {
            if($vm.vmName -like "*cvm*")
                {
                    Write-Host "not stopping cvm " $vm.vmName
                }
            else {
                Write-Host "Stopping VM: " $vm.vmName
                Stop-NTNXVM $vm.uuid | Wait-Task

            }       
        }
    }

Write-host "Proceed to stop the J61 Mill Nutanix Cluster..." -ForegroundColor Yellow
Pause

#Stop J61 Mill Nutanix Cluster
$loc = get-location
$WorkingDir = $loc.Path
Write-host "Calling new window to stop NTX cluster service"
Write-host "Stop cluster with command 'cluster stop' and verify status with 'cluster status'" -ForegroundColor Green
Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -WorkingDirectory $WorkingDir -ArgumentList "-File .\J61-MillClusterSvc.ps1" -Wait

Write-host "Shutdown CVM's. Connect to each cvm in a new window and shut it down" -ForegroundColor Yellow
Write-host "Connecting to J61NTXB01A" -ForegroundColor Green
Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -WorkingDirectory $WorkingDir -ArgumentList "-File .\MPMSNTXB01-CVM.ps1" -Wait

Write-host "Connecting to J61NTXB01B" -ForegroundColor Green
Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -WorkingDirectory $WorkingDir -ArgumentList "-File .\MPMSNTXB02-CVM.ps1" -Wait

Write-host "Connecting to J61NTXB02A" -ForegroundColor Green
Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -WorkingDirectory $WorkingDir -ArgumentList "-File .\MPMSNTXB03-CVM.ps1" -Wait

Write-host "Connecting to J61NTXB02B" -ForegroundColor Green
Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -WorkingDirectory $WorkingDir -ArgumentList "-File .\MPMSNTXB04-CVM.ps1" -Wait

Pause

##Stop Nutanix Nodes####




Write-Host "Power down script complete." -ForegroundColor Green

