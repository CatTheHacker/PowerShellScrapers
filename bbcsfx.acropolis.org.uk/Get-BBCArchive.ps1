function Get-BBCArchive {
    $WebClient = [System.Net.WebClient]::New()
    $Root = (Get-Location).Path
    $WebClient.DownloadFile('http://bbcsfx.acropolis.org.uk/assets/BBCSoundEffects.csv', 'BBCSoundEffects.csv')
    $Data = Import-Csv (Join-Path $Root 'BBCSoundEffects.csv')
    ForEach($Item in $Data){
        $Path = Join-Path $Root $Item.location
        [System.Console]::WriteLine('Filename: ' + $Item.location + ', Category: ' + $Item.category)
        $WebClient.DownloadFile(('http://bbcsfx.acropolis.org.uk/assets/' + $Item.location), $Path)
    }
}