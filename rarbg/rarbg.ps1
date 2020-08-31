# ? Search query
$query = 'intruders'
$i = 1
# ? In seconds
$WaitTime = 7
# ? Cookie for anti-script security
$Headers = @{'Cookie' = '__cfduid=d6fa76069c20272398b8defd82b13883d1598878677; gaDts48g=q8h5pp9t; tcc; aby=2; skt=QDVEUwbej6; skt=QDVEUwbej6; gaDts48g=q8h5pp9t; expla=1'}
$Torrents = [System.Collections.ArrayList]::New()
$ProgressPreference = 'SilentlyContinue'
do {
    [System.Console]::WriteLine('Collecting links for ' + $query + ', page ' + $i)
    $page = Invoke-WebRequest ('https://rarbgp2p.org/torrents.php?search=' + $query + '&page=' + $i) -Headers $Headers -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)
    $TorrentsTemp = ($page.links | Where-Object {$_.href -like '/torrent/*'} | Select-Object href).href -replace '#comments','' | Sort-Object -Unique
    $NextPage = ($page.links | Where-Object {$_.title -eq 'next page'} | Select-Object href).href -replace 'amp;','' | Sort-Object -Unique

    ForEach($Torrent in $TorrentsTemp){
        [System.Console]::WriteLine('Adding ' + $Torrent)
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
    [System.Console]::WriteLine('Downloading torrent file for ' + ($Torrent -split '/')[2])
    $Page = Invoke-WebRequest ('https://rarbgp2p.org' + $Torrent) -Headers $Headers -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)

    $TorrentFile = $page.links | Where-Object {$_.href -like '/download.php*'}
    $TorrentFileName = ($TorrentFile.href -split '=')[($TorrentFile.href -split '=').Count - 1]

    [System.Console]::WriteLine('Found ' + $TorrentFileName + ', url ' + $TorrentFile.href)

    For($r = $WaitTime;$r -gt 0; $r--){
        [System.Console]::Write('.')
        [System.Threading.Thread]::Sleep(1000)
    }

    [System.Console]::WriteLine('Downloading ' + $TorrentFileName + ', id: ' + ($Torrent -split '/')[2])
    Invoke-WebRequest ('https://rarbgp2p.org' + $TorrentFile.href) -OutFile $TorrentFileName -Headers $Headers -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)
    [System.Console]::WriteLine('Finished downloading ' + $TorrentFileName)

    For($r = $WaitTime;$r -gt 0; $r--){
        [System.Console]::Write('.')
        [System.Threading.Thread]::Sleep(1000)
    }
}