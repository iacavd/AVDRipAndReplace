[CmdletBinding()]
param (
    [parameter(mandatory = $true)]$Environment
)
# Connect using a Managed Service Identity
try
{
    $AzureContext = (Connect-AzAccount -Identity -Environment $Environment).context
}
catch
{
    Write-Output "There is no system-assigned user identity. Aborting.";
    exit
}

# Sleeping to ensure data is ingested into workspace
while ($null -eq (($alert = Get-AzAlert | Where-Object {$_.Name -like "New Image Found for AVD Environment*" -and $_.State -eq "New"} | Sort-Object -Property StartDateTime | Select-Object -Last 1 ))) {
Start-Sleep -Seconds 30
}

try
{
    # Loop until the alert is closed
    while ((($alert = Get-AzAlert | Where-Object {$_.Name -like "New Image Found for AVD Environment*"} `
    | Sort-Object -Property StartDateTime | Select-Object -Last 1).State -eq "New") -and `
    ($null -eq ($comments = (Get-AzAlertObjectHistory -ResourceId $alert.id.split('/')[-1])[0] | Where-Object {$_.Comments -eq $null}))) {
        Start-Sleep -Seconds 5
    }
    Start-Sleep -Seconds 120
    $alert = (Get-AzAlert | Where-Object {($_.Name -like "New Image Found for AVD Environment*") -and ($_.State -eq "Closed")} `
    | Sort-Object -Property StartDateTime | Select-Object -Last 1)
    $comments = (Get-AzAlertObjectHistory -ResourceId $alert.id.split('/')[-1]).Comments
    if($comments[0] -contains("Approved")){
        $Approval = $true
    }
    else{
        $Approval = $false
    }
}
catch
{
    $Approval = $false
    throw
}

$objOut = [PSCustomObject]@{
    Approval = $Approval
}

Write-Output ( $objOut | ConvertTo-Json)