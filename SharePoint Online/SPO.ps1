function Get-SharePointOpenDirectory ([string]$SharePointInviteUrl) {
    # * Get base domain
    $DriveDomain = ($SharePointInviteUrl -split '/')[0]
    $DriveType = ($SharePointInviteUrl -split '/')[3]
    $DriveUser = ($SharePointInviteUrl -split '/')[4]

    # * Use invite URL to get auth token
    $AuthToken = (Invoke-WebRequest -Uri ('https://' + $SharePointInviteUrl)).Headers.'Set-Cookie'
    $AuthToken = ($AuthToken -split ';')[0]

    # * Set headers with FedAuth cookie that will be used to authenticate all requests
    $Headers = @{
        'cookie'     = $AuthToken
        'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0'
    }

    # * Get root path
    $Response = Invoke-WebRequest -Headers $Headers -Uri ('https://' + $DriveDomain + '/' + $DriveType + '/' + $DriveUser + "/_api/web/GetListUsingPath(DecodedUrl=@a1)/RenderListDataAsStream?@a1='/" + $DriveType + "/" + $DriveUser + "/Documents'") -Method POST

    $Response = ConvertFrom-Json -InputObject $Response.Content

    # * Create directory if it doesn't exists
    if (!(Test-Path -LiteralPath $Response.row.FileLeafRef)) {
        New-Item -Name $Response.row.FileLeafRef -ItemType Directory
    }

    # * Move to directory
    Set-Location -LiteralPath $Response.row.FileLeafRef

    # * Start recursive function to grab all files
    Get-SharePointChildObjects -Path $Response.row.FileRef -Headers $Headers -DriveUser $DriveUser -DriveType $DriveType -DriveDomain $DriveDomain

    # * Show message when finished
    return ('Finished ' + $DriveDomain + '/' + $DriveType + '/' + $DriveUser)

}

function Get-SharePointChildObjects {
    param (
        $Path,
        $Headers,
        $DriveUser,
        $DriveType,
        $DriveDomain
    )

    # ! Encode hash otherwise scripts breaks into a eternal loop
    $Path = $Path -replace '#', '%23'

    # * Get items in directory
    $Response = Invoke-WebRequest -Headers $Headers -Uri ('https://' + $DriveDomain + '/' + $DriveType + '/' + $DriveUser + "/_api/web/GetListUsingPath(DecodedUrl=@a1)/RenderListDataAsStream?@a1='/" + $DriveType + "/" + $DriveUser + "/Documents'&RootFolder=" + $Path) -Method POST

    # * Convert it from JSON
    $Response = ConvertFrom-Json -InputObject $Response.Content

    ForEach ($Item in $Response.row) {
        <#
            ?   FSObjType:
            ?       1 - directory
            ?       0 - file
        #>
        if ($Item.FSObjType -eq 1) {

            # * Create directory if it doesn't exists
            if (!(Test-Path -LiteralPath $Item.FileLeafRef)) {
                New-Item -Name $Item.FileLeafRef -ItemType Directory
            }

            # * Move to directory
            Set-Location -LiteralPath $Item.FileLeafRef

            # *  Show directory path
            Write-Host ((Get-Location).Path) -ForegroundColor Magenta

            # * If path is not equal to directory name, recurse function on path
            if ($Path -ne $Item.FileRef) {
                Get-SharePointChildObjects -Path $Item.FileRef -Headers $Headers -DriveUser $DriveUser -DriveType $DriveType -DriveDomain $DriveDomain
            }

        } else {

            Write-Host ('Downloading: ' + $Item.FileLeafRef) -ForegroundColor Magenta
            Write-Host ('$Item size: ' + $Item.FileSizeDisplay) -ForegroundColor Cyan

            $FileUrl = ('https://' + $DriveDomain + '/' + $DriveType + '/' + $DriveUser + '/_layouts/15/download.aspx?UniqueId=' + ($Item.UniqueId -replace "{", "" -replace "}", ""))
            Write-Information $FileUrl

            # TODO Rewrite it to System.Net.HttpClient for better performance
            if ($False -eq (Test-Path -LiteralPath $Item.FileLeafRef)){

                # * Download the file
                Invoke-WebRequest -Headers $Headers -Method GET -Uri $FileUrl -OutFile $Item.FileLeafRef

            } elseif((Get-Item -LiteralPath $Item.FileLeafRef).Length -ne $Item.FileSizeDisplay) {

                # * Display local size
                Write-Host ('File size: ' + (Get-Item -LiteralPath $Item.FileLeafRef).Length) -ForegroundColor DarkRed

                # * Resume downloading of the file
                Invoke-WebRequest -Headers $Headers -Method GET -Uri $FileUrl -OutFile $Item.FileLeafRef -Resume

                # * Faster

                # $webClient = New-Object System.Net.WebClient
                # $webClient.Headers.add('cookie',$Headers.cookie)
                # $webClient.DownloadFile(('https://' + $DriveDomain + '/' + $DriveType + '/' + $DriveUser + '/_layouts/15/download.aspx?UniqueId=' + ($Item.UniqueId -replace "{","" -replace "}","")), $Item.FileLeafRef)
            }
        }
    }

    # * Move up once finished in current directory
    Set-Location '..'

    # * Show message when finished
    return ('Finished ' + $Path)

}