<#
.SYNOPSIS
    Moves the contents from shared location to Virtual directory. 

.DESCRIPTION
    Moves the contents from shared location to Virtual directory.. 
    Rest of the parameters will be read from JSON from Assets (VM_Details variable)

.EXAMPLE
    sync -virtualMachineName "somevmname"
    
.REVISION HISTORY
    Date: 27-Nov-2014 (Initial Version, Arun Mudiraj)    
#>

workflow sync
{
    
    # List of Input Parameters required 
    Param
    (
        # Name of the current VM which will be created.
        [Parameter(Mandatory = $true)]
        [String]
        $virtualMachineName
    )
    
    $VMDetails = Get-AutomationVariable -Name 'VM_Details'
    $SyncOptions = Get-AutomationVariable -Name 'Sync_Options'
    
    $VMDetailsData = $VMDetails | ConvertFrom-Json
    $SyncOptionsData = $SyncOptions | ConvertFrom-Json
    
    $csName = $VMDetailsData.CloudServiceName
    $scriptFileUrl = $SyncOptionsData.ScriptFileUrl
    $filetorun = $SyncOptionsData.FileToRun
    $src = $SyncOptionsData.SourceFilesLocation
    $destFolder = $SyncOptionsData.VirtualDirectoryLocation
 
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
    
    get-azureVM 
   
    Inlinescript 
    {
         
        $vm = get-azureVM -name $using:virtualMachineName  -ServiceName $using:csName 
        if($vm -eq $null)
        {
            write-output "Invalid VM provided, please check the name"
            return
        }
        if(!(  $vm | Get-AzureVMCustomScriptExtension))
        {
            Set-AzureVMExtension -ExtensionName CustomScriptExtension -VM $vm -Publisher Microsoft.Compute -Version 1.1 
        	Update-AzureVM -VM $VM.VM -Name $using:virtualMachineName -ServiceName $using:csName -Verbose
        }
    }
    
     Inlinescript
    {
        $vm = get-azureVM -name $using:virtualMachineName  -ServiceName $using:csName 
        if($vm -eq $null)
        {
             write-output "Invalid VM provided, please check the name"
            return
        }
        Set-AzureVMCustomScriptExtension -VM $VM.VM -FileUri  "http://cbostorage.blob.core.windows.net/passfiles/test.ps1" `
         -Argument  " -src $using:src -destFolder $using:destFolder" -run "test.ps1" | Update-AzureVM -Name $using:virtualMachineName -ServiceName $using:csName -Verbose
    }
    
    

    Inlinescript
    {
        $vm = get-azureVM -name $using:virtualMachineName  -ServiceName $using:csName 
        if($vm -eq $null)
        {
             write-output "Invalid VM provided, please check the name"
            return
        }
        Set-AzureVMCustomScriptExtension -VM $VM.VM -FileUri $using:scriptFileUrl `
         -Argument  " -src $using:src -destFolder $using:destFolder" -run $using:filetorun | Update-AzureVM -Name $using:virtualMachineName -ServiceName $using:csName -Verbose
    }
    
    Inlinescript {				
        	$vm = Get-azurevm -Name $using:virtualMachineName -ServiceName $using:csName
            if($vm -eq $null)
            {
                 write-output "Invalid VM provided, please check the name"
                return
            }
        	$status =  $vm.ResourceExtensionStatusList | where { $_.HandlerName -eq "Microsoft.Compute.CustomScriptExtension"} | select -ExpandProperty ExtensionSettingStatus | select -ExpandProperty Operation
        	while (($status -ne "Command Execution Finished") -and ($status -ne "Exiting"))
        	{
                Write-output "Still waiting for command execution to be completed current status $status"
              	Sleep -Seconds 30
        	    $vm = Get-azurevm -Name $using:virtualMachineName -ServiceName $using:csName
        	    $status =  $vm.ResourceExtensionStatusList | where { $_.HandlerName -eq "Microsoft.Compute.CustomScriptExtension"} | select -ExpandProperty ExtensionSettingStatus | select -ExpandProperty Operation
        	} 			
     }
    
     $successMessage = InlineScript
    {
	  $vm = Get-azurevm -Name $using:virtualMachineName -ServiceName $using:csName
      if($vm -eq $null)
        {
             write-output "Invalid VM provided, please check the name"
            return
        }
	  $successMsg = $vm.ResourceExtensionStatusList.ExtensionSettingStatus.SubStatusList | where { $_.Name -eq "StdOut"} | select -ExpandProperty FormattedMessage | select -ExpandProperty Message
	  $successMsg
    }
    $errorMessage = InlineScript
    {
	  $vm = Get-azurevm -Name $using:virtualMachineName -ServiceName $using:csName 
      if($vm -eq $null)
        {
             write-output "Invalid VM provided, please check the name"
            return
        }
	  $errMsg = $vm.ResourceExtensionStatusList.ExtensionSettingStatus.SubStatusList | where { $_.Name -eq "StdErr"} | select -ExpandProperty FormattedMessage | select -ExpandProperty Message
	  $errMsg
    }
    
    write-output "errorMessage $errorMessage"
    write-output "successMessage $successMessage"
    Write-output "Sync complete" 
}