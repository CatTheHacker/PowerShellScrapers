function Get-BBCArchive {
    [CmdletBinding()]
    param (
        [Parameter()]
        [int32]
        $Threads = 6,
        [Parameter()]
        [string]
        $Root = (Get-Location).Path
    )
    $WebClient = [System.Net.WebClient]::New()
    if(!(Test-Path (Join-Path $Root 'BBCSoundEffects.csv'))){
        $WebClient.DownloadFile('http://bbcsfx.acropolis.org.uk/assets/BBCSoundEffects.csv', (Join-Path $Root 'BBCSoundEffects.csv'))
    }
    $Data = Import-Csv (Join-Path $Root 'BBCSoundEffects.csv')
    if($PSVersionTable.PSVersion.Major -gt 6){
        $Data | ForEach-Object -Parallel {
            $Path = Join-Path $using:Root $_.location
            [System.Console]::WriteLine('Filename: ' + $_.location + ', Category: ' + $_.category)
            $Uri = ('http://bbcsfx.acropolis.org.uk/assets/' + $_.location)
            if(Test-Path $_.location){
                continue
            } else{
                $WebClient = [System.Net.WebClient]::New()
                $WebClient.DownloadFile($Uri, $Path)
            }
            $WebClient.Dispose()
        } -ThrottleLimit $Threads
    } else{
        foreach($Item in $Data){
            $Path = Join-Path $Root $Item.location
            [System.Console]::WriteLine('Filename: ' + $Item.location + ', Category: ' + $Item.category)
            $Uri = ('http://bbcsfx.acropolis.org.uk/assets/' + $Item.location)
            if(Test-Path $Item.location){
                continue
            } else{
                $WebClient.DownloadFile($Uri, $Path)
            }
        }
    }
    $WebClient.Dispose()
}