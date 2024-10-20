Install-WindowsFeature -Name DNS -IncludeManagementTools
$DnsServerSettings = Get-DnsServerSetting -All
$NameServerIPaddr = (Get-DnsServerSetting).ListeningIPAddress.IPAddressToString | Select-String "^10"
$DnsServerSettings.ListeningIpAddress = @("$NameServerIPaddr")
Set-DnsServerSetting $DnsServerSettings
Add-DnsServerPrimaryZone -Name "act-akslab.com" -ZoneFile "act-akslab.com.dns"
Add-DnsServerPrimaryZone -NetworkId "10.1.0.0/24" -ZoneFile "0.1.10.in-addr.arpa.dns"
Add-DnsServerResourceRecordA -Name "www" -ZoneName "act-akslab.com" -IPv4Address "10.1.0.100" -CreatePtr
$Forwarders = @("8.8.8.8", "8.8.4.4", "168.63.129.16")
Set-DnsServerForwarder -IPAddress $Forwarders
