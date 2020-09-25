function Get-BBCArchive {
    $WebClient = [System.Net.WebClient]::New()
    $Root = (Get-Location).Path
    $WebClient.DownloadFile('http://bbcsfx.acropolis.org.uk/assets/BBCSoundEffects.csv', 'BBCSoundEffects.csv')
    $Data = Import-Csv (Join-Path $Root 'BBCSoundEffects.csv')
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
    } -ThrottleLimit 6
}