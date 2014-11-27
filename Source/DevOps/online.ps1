<#
.SYNOPSIS
    Adds the VM into Existing Load Balance Set. 

.DESCRIPTION
    Retrieves the existing VM and Adds the VM into Existing Load Balance Set. 
    Rest of the parameters will be read from JSON from Assets (VM_Details variable)

.EXAMPLE
    online -virtualMachineName "somevmname"
    
.REVISION HISTORY
    Date: 27-Nov-2014 (Initial Version, Swamy PKV)    
#>

workflow online
{

    
    # List of Input Parameters required 
    Param
    (
        # Name of the current VM which will be created.
        [Parameter(Mandatory = $true)]
        [String]
        $virtualMachineName
    )
    
    write-output '***** Starting the {online} run book *****'
    
    # Retrieving the information required.
    $VMDetails = Get-AutomationVariable -Name 'VM_Details'
    $HttpLBSet = Get-AutomationVariable -Name 'HttpLbSet'
    $HttpsLbSet = Get-AutomationVariable -Name 'HttpsLbSet'
    $AzureConnectionDetails = Get-AutomationVariable -Name 'azureconnectionvariablename'
    $StorageAccountName = Get-AutomationVariable -Name 'storageaccountname'
    $AzureSubscriptionName = Get-AutomationVariable -Name 'azuresubscriptionname'

    write-output "$AzureConnectionDetails $StorageAccountName $AzureSubscriptionName" 
    
    write-output "Connecting to Azure $AzureConnectionDetails $AzureSubscriptionName"
    Connect-Azure -AzureConnectionName $AzureConnectionDetails -AzureSubscriptionName $AzureSubscriptionName
    
    write-output "Setting the Azure Subscription $AzureSubscriptionName :: $StorageAccountName"
    Set-AzureSubscription -SubscriptionName $AzureSubscriptionName -CurrentStorageAccountName $StorageAccountName
    
    write-output "Selecting the Azure Subscription $AzureSubscriptionName"
    Select-AzureSubscription -SubscriptionName $AzureSubscriptionName

    <#
    $instanceSize = "Small"
    $imageName = "simpleImage"
    $availabilitySetName = "availabilityfd"
    $lbSetName = "lbsetforfd"
    $cloudServiceName = "csforfdproject"
    $lbEndPointName = "LbHttpEpName"
    $lbProtocol = "TCP"
    $lbLocalPort = "80"
    $lbPublicPort = "80"
    $probeProtocol = "HTTP"
    $probePort = "1111"
    $probePath = "/"
    #>
    
    # Converting the Json Data to PSCustomObject
    $VMDetailsData = $VMDetails | ConvertFrom-Json
    $HttpLBSetData = $HttpLBSet | ConvertFrom-Json
    $HttpsLbSetData = $HttpsLbSet | ConvertFrom-Json
    
    $instanceSize = $VMDetailsData.VMSize
    $imageName = $VMDetailsData.VMImageName
    $availabilitySetName = $VMDetailsData.AvailabilitySetName
    $cloudServiceName = $VMDetailsData.CloudServiceName

    $lbSetName = $HttpLBSetData.LoadBalanceSetName
    $lbEndPointName = $HttpLBSetData.LBEPN
    $lbProtocol = $HttpLBSetData.LBP
    $lbLocalPort = $HttpLBSetData.LBLP
    $lbPublicPort = $HttpLBSetData.LBPP
    $probeProtocol = $HttpLBSetData.PPcol
    $probePort = $HttpLBSetData.PP
    $probePath = $HttpLBSetData.PPath

    # For Https LB Set
    $lbSetName1 = $HttpsLbSetData.LoadBalanceSetName
    $lbEndPointName1 = $HttpsLbSetData.LBEPN
    $lbProtocol1 = $HttpsLbSetData.LBP
    $lbLocalPort1 = $HttpsLbSetData.LBLP
    $lbPublicPort1 = $HttpsLbSetData.LBPP
    $probeProtocol1 = $HttpsLbSetData.PPcol
    $probePort1 = $HttpsLbSetData.PP
    $probePath1 = $HttpsLbSetData.PPath

    Write-Output "$instanceSize $imageName $availabilitySetName $lbSetName $cloudServiceName $virtualMachineName"
    Write-Output "$lbEndPointName $lbProtocol $lbLocalPort $lbPublicPort $probeProtocol $probePort $probePath"
    Write-Output "$lbEndPointName1 $lbProtocol1 $lbLocalPort1 $lbPublicPort1 $probeProtocol1 $probePort1 $probePath1"
    
    InlineScript
    {
        Write-Output "Updating the VM to place into Load Balance Set. Please wait ..."
        Get-AzureVM -Name $Using:virtualMachineName -ServiceName $Using:cloudServiceName | 
        Add-AzureEndpoint -Name $Using:lbEndPointName -Protocol $Using:lbProtocol -LocalPort $Using:lbLocalPort -PublicPort $Using:lbPublicPort -LBSetName $Using:lbSetName -ProbeProtocol $Using:probeProtocol -ProbePort $Using:probePort -ProbePath $Using:probePath |
        Add-AzureEndpoint -Name $Using:lbEndPointName1 -Protocol $Using:lbProtocol1 -LocalPort $Using:lbLocalPort1 -PublicPort $Using:lbPublicPort1 -LBSetName $Using:lbSetName1 -ProbeProtocol $Using:probeProtocol1 -ProbePort $Using:probePort1 -ProbePath $Using:probePath1 |
        Update-AzureVM

        Write-Output "Virtual Machine placed into Load Balance Set successfully."
    }

    write-output '***** Ending the {online} run book *****'
    
}

