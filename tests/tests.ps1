Describe 'ALZ VM Module validation' {

    BeforeAll {
        $testSubscriptionId = "4b068872-d9f3-41bc-9c34-ffac17cf96d6"
        Import-Module Az.Accounts,Az.Compute
        Set-AZContext -SubscriptionName $testSubscriptionId

        $resourceGroupName = "rg-pr-vmstopstart-001"
        $automationAccountName = "auto-pr-vmstopstart-001"

        #Keyvault secrets
        $kvSecrets = (Get-AzKeyVaultSecret -VaultName "kv-alz-vm-test-001").Name
        
        # Linux 
        $vmLinux = Get-AzVM -Name vm-test-nix-01
        $linuxNic = Get-AzNetworkInterface -ResourceID $vmLinux.NetworkProfile.NetworkInterfaces.Id


        # Windows
        $vmWin = Get-AzVM -Name vm-test-win-01
        $winNic = Get-AzNetworkInterface -ResourceID $vmWin.NetworkProfile.NetworkInterfaces.Id
    }   

    Context 'Linux VM Validation' {
        It "Linux VM exists with correct name" { $vmLinux.Name | Should -Be "vm-test-nix-01" }
        It "Linux VM has correct IP address" { $linuxNic.IPConfigurations.PrivateIPAddress | Should -Be "192.168.99.6" }
        It "Linux VM monitoring is disabled" { $vmLinux.Tags.prometheusAzureVirtualMachines | Should -Be "notmonitored" }
        It "Linux VM has created credentials in Keyvault" { $kvSecrets | Should -Contain "vm-test-nix-01-password" }
    }

    Context 'Windows VM Validation' {
        It "Windows VM exists with correct name" { $vmWin.Name | Should -Be "vm-test-win-01" }
        It "Windows VM has correct IP address" { $winNic.IPConfigurations.PrivateIPAddress | Should -Be "192.168.99.5" }
        It "Windows VM monitoring is enabled" { $vmWin.Tags.prometheusAzureVirtualMachines | Should -Be "tomonitor" }
        It "Windows VM has created credentials in Keyvault" { $kvSecrets | Should -Contain "vm-test-win-01-password" }
    }
}
