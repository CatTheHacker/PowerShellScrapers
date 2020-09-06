# ? Search query
$query = 'intruders'
$i = 1
# ? In seconds
$WaitTime = 7
# ? Cookie for anti-script security
$Headers = @{'Cookie' = ''}
$Torrents = [System.Collections.Generic.List[string]]::New()
$ProgressPreference = 'SilentlyContinue'
do {
    [System.Console]::WriteLine("`e[38;5;11m Collecting links for `e[38;5;9m" + $query + "`e[38;5;11m, page `e[38;5;9m" + $i + "`e[0m")
    $page = Invoke-WebRequest ('https://rarbgp2p.org/torrents.php?search=' + $query + '&page=' + $i) -Headers $Headers -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)
    $TorrentsTemp = ($page.links | Where-Object {$_.href -like '/torrent/*'} | Select-Object href).href -replace '#comments','' | Sort-Object -Unique
    $NextPage = ($page.links | Where-Object {$_.title -eq 'next page'} | Select-Object href).href -replace 'amp;','' | Sort-Object -Unique

    ForEach($Torrent in $TorrentsTemp){
        [System.Console]::WriteLine("`e[38;5;11m Adding `e[38;5;9m" + $Torrent + "`e[0m")
        [void]$Torrents.Add($Torrent)
    }

    For($r = $WaitTime;$r -gt 0; $r--){
        [System.Console]::Write('.')
        [System.Threading.Thread]::Sleep(1000)
    }
    [System.Console]::WriteLine()

    if($null -eq $NextPage -or $NextPage -eq ''){
        break;
    }

    $i++
} while ($true)

ForEach($Torrent in $Torrents){
    [System.Console]::WriteLine("`e[38;5;11m Downloading torrent file for `e[38;5;9m" + ($Torrent -split '/')[2] + "`e[0m")
    $Page = Invoke-WebRequest ('https://rarbgp2p.org' + $Torrent) -Headers $Headers -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)

    $TorrentFile = $page.links | Where-Object {$_.href -like '/download.php*'}
    $TorrentFileName = ($TorrentFile.href -split '=')[($TorrentFile.href -split '=').Count - 1]

    [System.Console]::WriteLine("`e[38;5;11m Found `e[38;5;9m" + $TorrentFileName + "`e[38;5;11m, url `e[38;5;9m" + $TorrentFile.href + "`e[0m")

    For($r = $WaitTime;$r -gt 0; $r--){
        [System.Console]::Write('.')
        [System.Threading.Thread]::Sleep(1000)
    }

    [System.Console]::WriteLine("`e[38;5;11m Downloading `e[38;5;9m" + $TorrentFileName + "`e[38;5;11m, id: `e[38;5;9m" + ($Torrent -split '/')[2] + "`e[0m")
    Invoke-WebRequest ('https://rarbgp2p.org' + $TorrentFile.href) -OutFile $TorrentFileName -Headers $Headers -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)
    [System.Console]::WriteLine("`e[38;5;2m Finished downloading `e[38;5;3m" + $TorrentFileName + "`e[0m")

    For($r = $WaitTime;$r -gt 0; $r--){
        [System.Console]::Write('.')
        [System.Threading.Thread]::Sleep(1000)
    }
}