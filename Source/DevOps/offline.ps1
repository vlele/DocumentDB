<#
.SYNOPSIS
    Removes the VM from Existing Load Balance Set. 

.DESCRIPTION
    Retrieves the existing VM and Removes the VM from Existing Load Balance Set. 
    Rest of the parameters will be read from JSON from Assets (VM_Details variable)

.EXAMPLE
    offline -virtualMachineName "somevmname"
    
.REVISION HISTORY
    Date: 27-Nov-2014 (Initial Version, Swamy PKV)    
#>

workflow offline
{
    
    # List of Input Parameters required 
    Param
    (
        # Name of the current VM which will be created.
        [Parameter(Mandatory = $true)]
        [String]
        $virtualMachineName
    )
    
    write-output '***** Starting the {offline} run book *****'
    
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
    $loadBalanceEndPointName = "LbHttpEpName"
    $loadBalanceProtocol = "TCP"
    $loadBalanceLocalPort = "80"
    $loadBalancePublicPort = "80"
    $probeProtocol = "HTTP"
    $probePort = "1111"
    $probePath = "/"
    #>
    
    # Converting the Json Data to PSCustomObject
    $VMDetailsData = $VMDetails | ConvertFrom-Json
    $HttpLBSetData = $HttpLBSet | ConvertFrom-Json
    $HttpsLbSetData = $HttpsLbSet | ConvertFrom-Json
    
    $cloudServiceName = $VMDetailsData.CloudServiceName
    $lbEndPointName = $HttpLBSetData.LBEPN
    $lbEndPointName1 = $HttpsLbSetData.LBEPN

    Write-Output "$cloudServiceName $virtualMachineName $lbEndPointName $lbEndPointName1"
    
    InlineScript
    {
        Write-Output "Updating the VM to remove from Load Balance Set. Please wait ..."
        Get-AzureVM -Name $Using:virtualMachineName -ServiceName $Using:cloudServiceName | 
        Remove-AzureEndpoint -Name $Using:lbEndPointName |
        Remove-AzureEndpoint -Name $Using:lbEndPointName1 |
        Update-AzureVM

        Write-Output "Virtual Machine has been removed from Load Balance Set successfully."
    }

    write-output '***** Ending the {offline} run book *****'
    
}

 
