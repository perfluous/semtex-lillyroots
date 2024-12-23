#Resource Group
$locationName = <...>
$resourceGroupName = <...>
#Virtual Network 
$networkName = <...>
$nicName = "NIC-"

#CREATING VNET
##################################################
$virtualNetwork = New-AzVirtualNetwork -Name $networkName -ResourceGroupName $resourceGroupName -Location $locationName -AddressPrefix "10.0.0.0/16"
##################################################

$vnet = Get-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $resourceGroupName  
$subnetNames = @("FrontEndSubnet", "BackEndSubnet", "mySQLSubnet") 
$subnetAddress = @("10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24")                     
#Virtual Machines
$computerNames = @("FrontEndServer1", "FrontEndServer2", "FrontEndServer3", "BackEndServer1", "BackEndServer2", "BackEndServer3", "mySQLServer1", "mySQLServer2", "mySQLServer3")
$vmSize = "Standard_B1s"
$publisherName = "MicrosoftWindowsServer"
$offer = "UbuntuLTS"
$skus = "18.04-LTS"

#Security

#Availability
#Werkt niet (naam is hardcoded): $availabilitySetName = "AvSet1"
$faultDomainCount = 3
$updateDomainCount = 3
$avSku = "Classic"

#Users
$user = <...>
$password = ConvertTo-SecureString -String <...> -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($user, $password);


#CREATING 3 SUBNETS
##################################################
for($i = 0; $i -le $subnetNames.count -1; $i++)
{
    #$subnets = New-AzVirtualNetworkSubnetConfig -Name $subnetNames[$i] -AddressPrefix $subnetAddress[$i]
    Add-AzureRmVirtualNetworkSubnetConfig -Name $subnetNames[$i] -VirtualNetwork $virtualNetwork -AddressPrefix  $subnetAddress[$i]
    $virtualNetwork | Set-AzVirtualNetwork #Updates Vnet with new subnet
    #az network vnet subnet create -n ($subnetNames[$i]) -g $resourceGroupName --vnet-name $networkName --address-prefixes ($subnetAddress[$i])
}
##################################################
#CREATING AVAILABILITY SET
New-AzAvailabilitySet -Name "AvailabilitySet01" -ResourceGroupName $ResourceGroupName -Location $locationName -PlatformUpdateDomainCount $updateDomainCount -PlatformFaultDomainCount $faultDomainCount -Sku $avSku
##################################################


#CREATING VMS
#################################################
for($i = 0; $i -le $computerNames.count -1; $i++) 
{
    Write-Output $computerNames[$i]
    $currentSubnet = [math]::floor($i/3)+1
    #$NIC = New-AzNetworkInterface -Name ($nicName+$computerNames[$i+1]) -ResourceGroupName $resourceGroupName -Location $locationName -SubnetId $vnet.Subnets[$currentSubnet].Id
    $NIC = New-AzNetworkInterface -Name ($nicName+$computerNames[$i+1]) -ResourceGroupName $resourceGroupName -Location $locationName -SubnetId $vnet
    $VirtualMachine = New-AzVMConfig - VMName $computerNames[$i] -VMSize $vmSize
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $computerNames[$i] -Credential $credential -ProvisionVMAgent 
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -Publishername $publisherName -Offer $offer -Skus $skus -Version latest
    $VirtualMachine = New-AzVM -ResourceGroupName $resourceGroupName -Location $locationName -VM $VirtualMachine -Verbose
}
#################################################

################################################
for($i = 0; $i -le $computerNames.count -1; $i++) 
{
    Write-Output $computerNames[$i]
    $currentSubnet = [math]::floor($i/3)+1
    #$NIC = New-AzNetworkInterface -Name ($nicName+$computerNames[$i+1]) -ResourceGroupName $resourceGroupName -Location $locationName -SubnetId $vnet.Subnets[$currentSubnet].Id
    $NIC = New-AzNetworkInterface -Name ($nicName+$computerNames[$i+1]) -ResourceGroupName $resourceGroupName -Location $locationName -SubnetId $vnet
    $VirtualMachine = New-AzureRmVMConfig  - VMName $computerNames[$i] -VMSize $vmSize
    $VirtualMachine = Set-AzureRmVMOperatingSystem  -VM $VirtualMachine -Linux -ComputerName $computerNames[$i] -Credential $credential -ProvisionVMAgent 
    $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzureRmVMSourceImage  -VM $VirtualMachine -Publishername $publisherName -Offer $offer -Skus $skus -Version latest
    $VirtualMachine = New-AzVM -ResourceGroupName $resourceGroupName -Location $locationName -VM $VirtualMachine -Verbose
    }

Get-AzVirtualNetwork -Name $networkName -ResourceGroupName $resourceGroupName
