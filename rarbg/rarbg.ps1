# ? Search query
$query = 'intruders'
# ? In seconds
$WaitTime = 7
# ? Cookie for anti-script security
$Headers = @{'Cookie' = ''}

# ? User Agent
$UserAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
# ? Execution path + '/rarbg'
$Root = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) 'rarbg'


if(!([System.IO.DirectoryInfo]::New($Root).Exists)){
    [System.Console]::WriteLine("`e[38;5;11m Creating `e[38;5;9m" + $Root + "`e[38;5;11m folder `e[0m")
    [System.IO.DirectoryInfo]::New($Root).Create()
} else{
    [System.Console]::WriteLine("`e[38;5;11m Root: `e[38;5;9m" + $Root + "`e[0m")
}

# ? Path
$Files = Get-ChildItem $Root

$i = 1
$Torrents = [System.Collections.Generic.List[string]]::New()

$ProgressPreference = 'SilentlyContinue'


do {
    [System.Console]::WriteLine("`e[38;5;11m Collecting links for `e[38;5;12m" + $query + "`e[38;5;11m, page `e[38;5;12m" + $i + "`e[0m")
    $Page = Invoke-WebRequest ('https://rarbgp2p.org/torrents.php?search=' + $query + '&page=' + $i) -Headers $Headers -UserAgent $UserAgent

    if($Page.Content -match 'Please wait while we try to verify your browser'){
        [System.Console]::WriteLine("`e[38;5;39m Blocked by anti-script shield, please fill the cookie in `e[38;5;2m`$Headers`e[38;5;39m from network tab in your browser.`e[0m")
        exit;
    }

    $TorrentsTemp = ($page.links | Where-Object {$_.href -like '/torrent/*'} | Select-Object href).href -replace '#comments','' | Sort-Object -Unique
    $NextPage = ($page.links | Where-Object {$_.title -eq 'next page'} | Select-Object href).href -replace 'amp;','' | Sort-Object -Unique

    [System.Console]::Write("`e[38;5;11m Adding ")
    ForEach($Torrent in $TorrentsTemp){
        [System.Console]::Write("`e[38;5;9m" + ($Torrent -split '/')[2] + "`e[38;5;11m, `e[0m")
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
    $TorrentId = ($Torrent -split '/')[2]
    [System.Console]::WriteLine("`e[38;5;11m Downloading torrent file for `e[38;5;9m" + $TorrentId + "`e[0m")

    if($Files.Name -match $TorrentId){
        [System.Console]::WriteLine("`e[38;5;39m Skipping...`e[0m")
        continue;
    }

    $Page = Invoke-WebRequest ('https://rarbgp2p.org' + $Torrent) -Headers $Headers -UserAgent $UserAgent

    $TorrentFile = $page.links | Where-Object {$_.href -like '/download.php*'}
    $TorrentFileName = ($TorrentId + '.' + ($TorrentFile.href -split '=')[($TorrentFile.href -split '=').Count - 1])

    $TorrentFilePath = Join-Path $Root $TorrentFileName

    [System.Console]::WriteLine("`e[38;5;11m Found `e[38;5;12m" + $TorrentFileName + "`e[38;5;11m, url `e[38;5;12m" + $TorrentFile.href + "`e[0m")

    For($r = $WaitTime;$r -gt 0; $r--){
        [System.Console]::Write('.')
        [System.Threading.Thread]::Sleep(1000)
    }

    [System.Console]::WriteLine("`e[38;5;11m Downloading `e[38;5;9m" + $TorrentFileName + "`e[38;5;11m, id: `e[38;5;9m" + $TorrentId + "`e[0m")
    Invoke-WebRequest ('https://rarbgp2p.org' + $TorrentFile.href) -OutFile $TorrentFilePath -Headers $Headers -UserAgent $UserAgent
    [System.Console]::WriteLine("`e[38;5;2m Finished downloading `e[38;5;3m" + $TorrentFileName + "`e[0m")

    For($r = $WaitTime;$r -gt 0; $r--){
        [System.Console]::Write('.')
        [System.Threading.Thread]::Sleep(1000)
    }
}