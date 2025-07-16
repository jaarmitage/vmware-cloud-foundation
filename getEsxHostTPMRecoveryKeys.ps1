### Retrieves TPM encryption recovery keys from multiple ESXi hosts and exports them to CSV.
### Joshua Armitage
### jarmitage@gmail.com
### joshua.armitage@broadcom.com

If ($global:DefaultVIServers.Count -ge 1) {
    Write-Host "Select connected vCenter Server to proceed"

    $viSelectMenu = @{}

    For ($i=1; $i -le ($global:DefaultVIServers.Count +1); $i++) {
        If ($i -le $global:DefaultVIServers.Count) {
            Write-Host "$i. $($global:DefaultVIServers[$i-1].Name)"
            $viSelectMenu.Add($i,($global:DefaultVIServers[$i-1].Name))
        } Else {
            #Write-Host "0. ALL"
            $viSelectMenu.Add(0,"ALL")
        }
    }

    [int]$ans = Read-Host 'Enter Selection'
    $viSel = $viSelectMenu.Item($ans)

    Write-Host $viSel
    Write-Host " "
    Write-Host "-----"
    Write-Host " "
    Write-Host "Select vSphere host cluster to proceed"
    Write-Host " "

    If ($viSel -eq "ALL") {
        $clusters = Get-Cluster | Select-Object -Property Name
    } Else {
        $clusters = Get-Cluster -Server $viSel | Select-Object -Property Name | Sort-Object -Property Name
    }

    $cluSelectMenu = @{}

    For ($i=1; $i -le ($clusters.count +1); $i++) {
        If ($i -le $clusters.count) {
            Write-Host "$i. $($clusters[$i-1].Name)"
            $cluSelectMenu.Add($i,($clusters[$i-1].Name))
        } Else {
            Write-Host "0. ALL"
            $cluSelectMenu.Add(0,"ALL")
        }
    }

    [int]$ans = Read-Host 'Enter Selection'
    $cluSel = $cluSelectMenu.Item($ans)

    If ($cluSel -eq "ALL") {
        $hosts = Get-VMHost | Where-Object { ($_.ConnectionState -eq "Connected") -or ($_.ConnectionState -eq "Maintenance") } | Select-Object -Property Name
    } Else {
        $hosts = Get-VMHost -Location $cluSel | Where-Object { ($_.ConnectionState -eq "Connected") -or ($_.ConnectionState -eq "Maintenance") } | Select-Object -Property Name | Sort-Object -Property Name
    }

    If ($hosts.count -ge 1) {
        $hostSelectMenu = @{}
        Write-Host "Select vSphere host to proceed"
        Write-Host " "
        For ($i=1; $i -le ($hosts.count +1); $i++) {
            If ($i -le $hosts.count) {
                Write-Host "$i. $($hosts[$i-1].Name)"
                $hostSelectMenu.Add($i,($hosts[$i-1].Name))
            } Else {
                Write-Host "0. ALL"
                $hostSelectMenu.Add(0,"ALL")
            }
        }
        [int]$ans = Read-Host 'Enter Selection'
        $hostSel = $hostSelectMenu.Item($ans)
    } Else {
        Write-Host "No connected hosts in cluster selection."
        Break
    }

    Write-Host " "
    Write-Host "-----"
    Write-Host " "

    If ($cluSel -ne "ALL") {
        Write-Host "Selected cluster: $cluSel"
        If ($hostSel -ne "ALL") {
            Write-Host "Selected host: $hostSel"
            $workingHosts = Get-VMHost -Location $cluSel -Name $hostSel
        } Else {
            Write-Host "Selected host: ALL"
            $workingHosts = Get-VMHost -Location $cluSel
        }
    } Else {
        Write-Host  "Selected cluster: ALL"
        $workingHosts = Get-VMHost
    }
} Else {
    Write-Host "Not connected to any vCenter Servers."
}

#Iterate through all selected hosts and retrieve any TPM encryption recovery keys found.
If ($workingHosts -ne $null) {
    $tpmEncRecoveryKeys = @()

    ForEach ($vsh in $workingHosts) {
        $h = Get-EsxCli -VMHost $vsh -V2
        $keys = $h.system.settings.encryption.recovery.list.Invoke()

        If ($keys) {
            ForEach ($k in $keys) {
                $hostRecoveryKeys = [PSCustomObject]@{
                    Host         = $vsh.Name
                    RecoveryID   = $k.'Recovery Id'
                    'Recovery Key' = $k.Key
                }
                $tpmEncRecoveryKeys += $hostRecoveryKeys
            }
        } Else {
            $hostRecoveryKeys = [PSCustomObject]@{
                Host         = $vsh.Name
                RecoveryID   = "N/A"
                'Recovery Key' = "No TPM Recovery Keys Found"
            }
            $tpmEncRecoveryKeys += $hostRecoveryKeys
        }
    }

    # Display table on screen
    $tpmEncRecoveryKeys | Format-Table -AutoSize

    # Export to CSV
    $ExportDirectory = Read-Host -Prompt "Enter the directory path to save the CSV file"
    $CSVFilePath = Join-Path -Path $ExportDirectory -ChildPath "TPM_RecoveryKeys.csv"
    $tpmEncRecoveryKeys | Export-Csv -Path $CSVFilePath -NoTypeInformation
    Write-Host "CSV exported to: $CSVFilePath"
}
