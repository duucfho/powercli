param
(
    [Parameter(Mandatory=$False,
        HelpMessage='Path to CSV to Import')]
        [string[]]$csvlist
)

#Import PowerCLI Module
Add-PSSnapin VMware.VimAutomation.Core
$Credential = Get-Credential
$VCenterName = Read-Host -Prompt "Name or IP address of vcenter"

If($csvlist -eq $NULL){
    $csvlist = Read-host -Prompt "Csv to import"
}
If((Test-Path $csvlist) -eq $False){Write-host "Could not find CSV.";break}
Connect-viserver $VCenterName -Credential $Credential
$vmlist = Import-csv "$csvlist"

$task = @()
foreach ($item in $vmlist) {
    $Static = $False
    $basevm = $item.basevm
    $vmcluster = $item.vmcluster
    $custspec = $item.custspec
    $vmname = $item.vmname
    $folder = $item.folder
    $TemplateName = $Null
    $IsTemplate = $NULL
    $IPaddress = $item.IPAddress
    $NetMask = $item.Netmask
    $Gateway = $item.Gateway
    $DNSServers = $item.DNSServers

    #Check if source vm is template or VM
    Try{
        If(Get-Template $basevm-$vmcluster -ErrorAction SilentlyContinue){
            $TemplateName = Get-Template $basevm-$vmcluster -ErrorAction Stop
            $IsTemplate = $True
        }
        Else{
            $TemplateName = Get-Template $basevm -ErrorAction Stop
            $IsTemplate = $True
        }
    }Catch {$IsTemplate = $False}

    #Get datastore cluster from vmcluster name
    $datastore = Get-DatastoreCluster "$vmcluster*DSC"  # | Sort-Object -Property FreeSpaceGB -Descending | select-object -First 1

    #Create VM
    If($IPAddress -like "*.*"){
        $Static = $True
        $DNS = $DNSServers.split(",")
		$custspec = Get-OSCustomizationSpec $custspec | New-OSCustomizationSpec -Name "$custspec-$vmname"
		If($custspec.OStype -eq "Linux"){
			$custspec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IPMode UseStaticIP -IPAddress $IPaddress -SubnetMask $NetMask -DefaultGateway $Gateway
		}Else{
			$custspec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IPMode UseStaticIP -IPAddress $IPaddress -SubnetMask $NetMask -DefaultGateway $Gateway -Dns $DNS[0],$DNS[1]
        }
    }

    If($IsTemplate -eq $True){
        #Clone the BaseVM Template with the adjusted Customization Specification
        $task += New-VM -Name $vmname -Location $folder -Template $TemplateName -Datastore $datastore -ResourcePool $vmcluster -OSCustomizationSpec $custspec -RunAsync -Confirm:$False
    }
    ElseIf($IsTemplate -eq $False){
        #Clone the BaseVM VM with the adjusted Customization Specification
        $task += New-VM -Name $vmname -Location $folder -VM $basevm -Datastore $datastore -ResourcePool $vmcluster -OSCustomizationSpec $custspec -RunAsync -Confirm:$False
    }
}

if ( $Task -ne $Null -OR $Task.count -gt 0 ){
    wait-task $Task
}

foreach ($item in $vmlist) {
    $vmname = $item.vmname
    $vlan = $item.vlan
    $vmcluster = $item.vmcluster
    [int]$pdisk = $item.pdisk
    [int]$sdisk1 = $item.sdisk1
    [int]$sdisk2 = $item.sdisk2
    [int]$sdisk3 = $item.sdisk3
    [int]$sdisk4 = $item.sdisk4
    [int]$sdisk5 = $item.sdisk5
    [int]$sdisk6 = $item.sdisk6
    [int]$sdisk7 = $item.sdisk7
    [int]$sdisk8 = $item.sdisk8
    [int]$sdisk9 = $item.sdisk9
    [int]$sdisk10 = $item.sdisk10
    [int]$totalcpu = $item.totalcpu
    [int]$corespersocket = $item.corespersocket
    [int]$memorygb = $item.memorygb

    #Get datastore cluster from vmcluster name
    $datastore = Get-DatastoreCluster "$vmcluster*DSC"  # | Sort-Object -Property FreeSpaceGB -Descending | select-object -First 1

    $VMName = Get-VM $VMName

    #Set NIC to correct VDS
    $VMName | Get-NetworkAdapter |Set-NetworkAdapter -NetworkName $vlan -StartConnected $True -confirm:$false

    #adjust number of cpu's and sockets
    $spec = new-object -typename VMware.VIM.virtualmachineconfigspec -property @{'numcorespersocket'=$corespersocket;'numCPUs'=$totalcpu}
    ($VMName).ExtensionData.ReconfigVM_Task($spec)

    #adjust memory allocation
    $VMName | Set-VM -MemoryGB $memorygb -confirm:$false

    #Resize Primary Disk
    if($pdisk -gt 1){Write-Host "Disk0: $pdisk";$VMName | Get-HardDisk | Select-Object -First 1 | Set-HardDisk -CapacityGB $pdisk -Confirm:$False}

    #Add Additional Disks
    if($sdisk1 -gt 1){Write-Host "Disk1: $sdisk1";$VMName | New-HardDisk -CapacityGB $sdisk1 -Datastore $datastore -StorageFormat "EagerZeroedThick" -Confirm:$False}
    if($sdisk2 -gt 1){Write-Host "Disk2: $sdisk2";$VMName | New-HardDisk -CapacityGB $sdisk2 -Datastore $datastore -StorageFormat "EagerZeroedThick" -Confirm:$False}
    if($sdisk3 -gt 1){Write-Host "Disk3: $sdisk3";$VMName | New-HardDisk -CapacityGB $sdisk3 -Datastore $datastore -StorageFormat "EagerZeroedThick" -Confirm:$False}
    if($sdisk4 -gt 1){Write-Host "Disk4: $sdisk4";$VMName | New-HardDisk -CapacityGB $sdisk4 -Datastore $datastore -StorageFormat "EagerZeroedThick" -Confirm:$False}
    if($sdisk5 -gt 1){Write-Host "Disk5: $sdisk5";$VMName | New-HardDisk -CapacityGB $sdisk5 -Datastore $datastore -StorageFormat "EagerZeroedThick" -Confirm:$False}
    if($sdisk6 -gt 1){Write-Host "Disk6: $sdisk6";$VMName | New-HardDisk -CapacityGB $sdisk6 -Datastore $datastore -StorageFormat "EagerZeroedThick" -Confirm:$False}
    if($sdisk7 -gt 1){Write-Host "Disk7: $sdisk7";$VMName | New-HardDisk -CapacityGB $sdisk7 -Datastore $datastore -StorageFormat "EagerZeroedThick" -Confirm:$False}
    if($sdisk8 -gt 1){Write-Host "Disk8: $sdisk8";$VMName | New-HardDisk -CapacityGB $sdisk8 -Datastore $datastore -StorageFormat "EagerZeroedThick" -Confirm:$False}
    if($sdisk9 -gt 1){Write-Host "Disk9: $sdisk9";$VMName | New-HardDisk -CapacityGB $sdisk9 -Datastore $datastore -StorageFormat "EagerZeroedThick" -Confirm:$False}
    if($sdisk10 -gt 1){Write-Host "Disk10: $sdisk10";$VMName | New-HardDisk -CapacityGB $sdisk10 -Datastore $datastore -StorageFormat "EagerZeroedThick" -Confirm:$False}

    #Start the VM
    $VMName | Start-VM -Confirm:$False
	$vmname = $item.vmname
	Get-OSCustomizationSpec "*$vmname" | Remove-OSCustomizationSpec -Confirm:$False
}

Disconnect-Viserver $VCenterName -confirm:$false
