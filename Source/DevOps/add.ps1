<#
.SYNOPSIS
    Create VM using Existing Image and starts the VM. 

.DESCRIPTION
    Create VM using Existing Image and starts the VM. 
    Rest of the parameters will be read from JSON from Assets (VM_Details variable)

.EXAMPLE
    add -virtualMachineName "somevmname" -userName "demouser" -password sample123$
    
.REVISION HISTORY
    Date: 27-Nov-2014 (Initial Version, Swamy PKV)    
#>

workflow add
{
    
    # List of Input Parameters required 
    Param
    (
        # Name of the current VM which will be created.
        [Parameter(Mandatory = $true)]
        [String]
        $virtualMachineName,
        
        # User name used while creating Virtual Machine
        [Parameter(Mandatory = $true)]
        [String]
        $userName,
        
        # Password used while creating Virtual Machine
        [Parameter(Mandatory = $true)]
        [String]
        $password
    )
    
    write-output '***** Starting the {add} run book *****'
    
    # Retrieving the information required.
    $VMDetails = Get-AutomationVariable -Name 'VM_Details'
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

    # Converting the Json Data to PSCustomObject
    $VMDetailsData = $VMDetails | ConvertFrom-Json
    
    $instanceSize = $VMDetailsData.VMSize
    $imageName = $VMDetailsData.VMImageName
    $availabilitySetName = $VMDetailsData.AvailabilitySetName
    $cloudServiceName = $VMDetailsData.CloudServiceName
    
    Write-Output "$instanceSize $imageName $availabilitySetName $cloudServiceName $virtualMachineName $username $password"
    
    InlineScript
    {
        
        $virtualMachine = New-AzureVMConfig -Name $Using:virtualMachineName -InstanceSize $Using:InstanceSize -ImageName $Using:imageName -AvailabilitySetName $Using:availabilitySetName |  
        Add-AzureProvisioningConfig -Windows -AdminUsername $Using:userName -Password $Using:password
        Write-Output "Virtual Machine with Configuration Generated $($virtualMachine)"
        
        Write-Output "Creating New Virtual Machine. Please wait ..."
        $virtualMachine | New-AzureVM -ServiceName $Using:cloudServiceName #-WaitForBoot | Out-Null
        
        Write-Output "New Virtual Machine created. Please wait while we start it ..."
        Start-AzureVM -ServiceName $Using:cloudServiceName -Name $Using:virtualMachineName
        
        do
        {
             Start-Sleep -Seconds 5
             $vm = Get-AzureVM -ServiceName $Using:cloudServiceName -Name $Using:virtualMachineName
             write-output "Verifying VM Status with " $vm.InstanceStatus $vm.PowerState
        } while(($vm.InstanceStatus -ne 'ReadyRole') -and ($vm.PowerState -ne 'Started'))
        
    }

    write-output '***** Ending the {add} run book *****'
    
}

 
