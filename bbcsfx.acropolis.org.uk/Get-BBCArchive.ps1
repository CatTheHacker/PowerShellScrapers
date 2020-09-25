function Get-BBCArchive {
    [CmdletBinding()]
    param (
        [Parameter()]
        [int32]
        $Threads = 6,
        [Parameter()]
        [string]
        $Root = $PWD.Path
    )
    $WebClient = [System.Net.WebClient]::New()
    $CSVPath = [System.Management.Automation.SessionState]::New().Path.Combine($Root, 'BBCSoundEffects.csv')
    if(!([System.IO.File]::Exists($CSV))){
        $WebClient.DownloadFile('http://bbcsfx.acropolis.org.uk/assets/BBCSoundEffects.csv', $CSVPath)
    }
    $Data = Import-Csv $CSVPath | Select-Object location, category
    if($PSVersionTable.PSVersion.Major -gt 6){
        $Data | ForEach-Object -Parallel {
            $Item = $_
            [System.Console]::WriteLine('Filename: {0}, Category: {1}', $Item.location, $Item.category)
            $FilePath = [System.Management.Automation.SessionState]::New().Path.Combine($using:Root, $Item.location)
            $FileUri = [System.String]::Format('http://bbcsfx.acropolis.org.uk/assets/{0}', $Item.location)
            $Client = [System.Net.WebClient]::New()
            if([System.IO.File]::Exists($FilePath)){
                $Request = [System.Net.WebRequest]::Create($FileUri)
                $Request.Method = 'HEAD'
                $Response = $Request.GetResponse()
                if([System.IO.FileInfo]::new($FilePath).Length -ne $Response.ContentLength){
                    [System.Console]::WriteLine('Found existing file ({0}), attempting to finish download.', $Item.location)
                    #Invoke-WebRequest -Uri $FileUri -OutFile $FilePath -Resume
                    [System.Console]::WriteLine('File resume currently not supported. Re-downloading.')
                    $Client.DownloadFile($FileUri, $FilePath)
                }
            } else{
                $Client.DownloadFile($FileUri, $FilePath)
            }
            $Client.Dispose()
            [System.Console]::WriteLine('File {0} is complete.', $Item.location)
        } -ThrottleLimit $Threads
    } else{
        foreach($Item in $Data){
            [System.Console]::Write('Filename: {0}, Category: {1}...', $Item.location, $Item.category)
            $FilePath = [System.Management.Automation.SessionState]::New().Path.Combine($Root, $Item.location)
            $FileUri = [System.String]::Format('http://bbcsfx.acropolis.org.uk/assets/{0}', $Item.location)
            if([System.IO.File]::Exists($FilePath)){
                $Request = Invoke-WebRequest -Uri $FileUri -Method Head
                if([System.IO.FileInfo]::new($FilePath).Length -ne $Request.Headers.'Content-Length'){
                    [System.Console]::WriteLine('Found existing file ({0}), attempting to finish download.', $Item.location)
                    if($PSVersionTable.PSVersion.Major -gt 6){
                        Invoke-WebRequest -Uri $FileUri -OutFile $FilePath -Resume
                    } else{
                        $WebClient.DownloadFile($FileUri, $FilePath)
                    }
                    [System.Console]::WriteLine('Finished.')
                } else{
                    [System.Console]::WriteLine('Skipped.')
                }
            } else{
                $WebClient.DownloadFile($FileUri, $FilePath)
                [System.Console]::WriteLine('Finished.')
            }

        }
    }
    $WebClient.Dispose()
}