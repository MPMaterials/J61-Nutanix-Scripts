#get nutanix IPMI credential
$ntxcred = Get-Credential -UserName "ADMIN" -Message "Enter credentials for IPMI access from Bitwarden - 'mpm mill (mpmsntxb) IPMI access'"


##Stop Nutanix Nodes####
$nodelist = "192.168.210.15","192.168.210.16","192.168.210.17","192.168.210.18"
foreach($ip in $nodelist)
    {
        get-pcsvdevice -targetaddress $ip -managementprotocol IPMI -credential $ntxcred  | Stop-PcsvDevice
    }


$wait = "60"
foreach ($node in $nodelist)
{
    $ck = $null
    do {
        Write-Host "Checking $node status..."
        $ck = get-pcsvdevice -targetaddress $node -managementprotocol IPMI -credential $ntxcred
        $state = $ck.EnabledState
        if($state -eq "Enabled")
            {
                for ($i = 1; $i -le $wait; $i++ )
                {
                    Write-Progress -Activity "Waiting for $node to power down" -Status "$i seconds elapsed:" -PercentComplete ($i/$wait*100);
                    Start-Sleep -s 1
                }
                Write-Progress -Activity "Waiting for $node to power down" -Status "Completed" -Completed;
            }
            else {$off = $true}
        }
    until ($off -eq $true)
    {
        Write-Host "$node is now powered off." -ForegroundColor Green
    }
}
