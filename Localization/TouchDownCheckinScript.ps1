param([String]$SrcRoot="undefined",[String]$AuthToken="",[String]$Branch="")

# This script will upload the files which need to be localized to the Touchdown servers and they will automatically be translated by Bing translate

# Usage: .\TouchDownCheckinScript.ps1 absolute\path\to\reporoot branch_to_base_off

#What would be the standard steps to enable check in process
#  -Sync the Localized File on the machine
#  -GIT reset –hard reset
#  -GIT pull
#  -Create a Temp loc branch
#  -Set the Flag (ChangesAreDetected = false)
#  -Call TD
#  -Extract the ZIP file from TD
#  -Map the extracted file to the Local file
#  -Compare the localized File with File in the Repo, if those files are different then run the command sd add
#  -Set the Flag (ChangesAreDetected = True)
#  -Run a Git push (Integrate the TempLocBranch to your working branch)

$CultureSettingFile= "appcenter-cultures.csv"
$ProjectInfo = "appcenter-sdks-loc-file-list.csv"

$TempLocBranch = "translatedFiles"
$repoPath = $SrcRoot
$DefaultRepoBranch = "develop"
$teamId = "272" #ID for iOS
$git = "git"

Function ProcessStart($AppToRun,$Argument,$WorkingDir)
{
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $AppToRun
    $pinfo.Arguments = $Argument
    $pinfo.WorkingDirectory = $WorkingDir
    $pinfo.CreateNoWindow = $True
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()

    $output = $p.StandardOutput.ReadToEnd()
    $output += $p.StandardError.ReadToEnd()

    write-host $output
}

Function InitializeRepoForCheckin
{
    if (!($Branch -eq "")) {
        $DefaultRepoBranch = $Branch
    }

    $Argument = "checkout " + $DefaultRepoBranch 
    ProcessStart $git $Argument $repoPath

    $Argument = "reset --hard HEAD"
    ProcessStart $git $Argument $repoPath

    $Argument = "pull origin " + $DefaultRepoBranch
    ProcessStart $git $Argument $repoPath

    $Argument = "branch -D " + $TempLocBranch
    ProcessStart $git $Argument

    $Argument = "checkout -b " + $TempLocBranch
    ProcessStart $git $Argument $repoPath
}

Function CheckinFilesIntoRepo
{
    #Commit the changes
    $Argument = 'commit -m "Latest localized files from touchdown"'
    ProcessStart $git $Argument $repoPath

    #Push the Changes to the git server you still need to merge the changes
    if ($AuthToken -eq "") {
        #Unauthorized
        $Argument = "push origin " + $TempLocBranch
    }
    else {
        #Authorized
        $Argument = "-c http.extraheader=`"Authorization: Bearer " + $AuthToken + "`" push origin " + $TempLocBranch
    }
    
    ProcessStart $git $Argument $repoPath
}

Class Cl_Culture 
{
    [String]$LCID
    [String]$LSBUILD
    [string]$Culture

    Cl_Culture ([string]$LCID,$LSBUILD,$Culture)
    {
        $this.LCID =$LCID
        $this.LSBUILD = $LSBUILD
        $this.Culture = $Culture
    }
}

#Unzip a file
Add-Type -AssemblyName System.IO.Compression.FileSystem
Function Unzip ($zipfile,$outpath)
{
    write-Host "We are unzipping the zip file $zipfile to $outpath"

    #Remove the content of the outpath folder if it exists
    if ((Test-Path -Path $outpath) -and $outpath.Contains("Unzip"))
    {
        write-host "Deleting the file"
        Remove-Item -Recurse -Force $outpath
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Function GetCulture($CultureFile,$CultureToSearch)
{
    $Cultures = Import-CSV $CultureFile 

    ForEach ($culture in $Cultures)
    {
        $LCID =$culture.LCID
        $LSBUILDCULTURE =$culture.LSBUILDCULTURE
        $CULTURE =$culture.Culture

        if ($CultureToSearch -eq $LSBUILDCULTURE)
        {
            $OCulture = [Cl_Culture]::new($LCID,$LSBUILDCULTURE,$Culture)
            write-host $OCulture.LSBUILD
            Return $OCulture
        }
    }
}

Function TouchDownTransaction ($absoluteFilePath,$outFilePath,$relativeFilePath,$teamId,$LanguageSet)
{
    $filePath = @{ FilePath = $relativeFilePath }
    $filePathJson = ConvertTo-Json $filePath -Compress

    # convert file into an octet-stream
    $fileBinary = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString((Get-Content -Encoding Byte -Path $absoluteFilePath))

    # generate form-data body
    $boundary = "tdbuildFormBoundary"

    #Formatting is weird in script to keep correct format for output?
    $body = @"
--$boundary
Content-Disposition: form-data; name="application/json"
Content-Type: application/json

$filePathJson
--$boundary
Content-Disposition: form-data; name="resources"; filename="resources"
Content-Type: application/octet-stream

$fileBinary
--$boundary--
"@

    Invoke-RestMethod -Uri "http://tdbuild/api/teams/$teamId/LocalizableFiles" -Method Put -UseDefaultCredentials -ContentType "multipart/form-data; boundary=$boundary" -Body $body -OutFile $outFilePath
}

Function BinPlace ($UnzipFileTo,$relativeFilePath,$TargetPath,$LanguageSet)
{
    $Langs = $LanguageSet.split(";")
    
    write-host "the culture file is: $CultureSettingsFile"

    foreach($Language in $Langs)
    {
        $OCulture = GetCulture $CultureSettingFile $Language
        $LocalizedFile = $UnzipFileTo + "\" + $OCulture.LSBUILD + $relativeFilePath
        $LocDir = ""

        # Chinese (zh) regions use a different directory structure
        if ($OCulture.Culture -eq "zh") {
            $LocDir = $TargetPath + $OCulture.Culture + $(if ($Language.split("-")[1] -eq "CN") {"-Hans"} else {"-Hant"}) + ".lproj"
        } else {
            $LocDir = $TargetPath + $OCulture.Culture + ".lproj"
        }
        
        if(!(Test-Path -Path $LocDir)){
            New-Item -Path $LocDir -ItemType directory
        }

        $targetFile = $LocDir + $relativeFilePath

        write-host "Loc File:   $LocalizedFile"
        write-host "TargetPath: $targetFile"
        write-host "Copying Loc file to TargetPath"

        Copy-Item $LocalizedFile $targetFile
    }
}

Function AddFiletoRepo ($TargetPath,$LanguageSet)
{
    $Langs = $LanguageSet.split(";")

    foreach($Language in $Langs)
    {
        $OCulture = GetCulture $CultureSettingFile $Language
        if ($OCulture.Culture -eq "zh") {
            $LocDir = $TargetPath + $OCulture.Culture + $(if ($Language.split("-")[1] -eq "CN") {"-Hans"} else {"-Hant"}) + ".lproj"
        } else {
            $LocDir = $TargetPath + $OCulture.Culture + ".lproj"
        }

        $Argument = "add " + $LocDir

        write-host $Argument

        ProcessStart $git $Argument $repoPath
    }
}

Function RefreshTDFiles
{
    InitializeRepoForCheckin

    $Files = Import-CSV $ProjectInfo 

    Foreach($File in $Files)
    {
        write-host "Start processing Files"

        $absoluteFilePath = $File.absoluteFilePath
        $outFilePath      = $File.outFilePath
        $relativeFilePath = $File.relativeFilePath
        $TargetPath       = $File.TargetPath
        $LanguageSet      = $File.LanguageSet

        $outFilePath      = $ExecutionContext.InvokeCommand.ExpandString($outFilePath)
        $absoluteFilePath = $ExecutionContext.InvokeCommand.ExpandString($absoluteFilePath)
        $TargetPath       = $ExecutionContext.InvokeCommand.ExpandString($TargetPath)

        write-host "-----TOUCHDOWN TRANSACTION-----"
        TouchDownTransaction $absoluteFilePath $outFilePath $relativeFilePath $teamId $LanguageSet

        $UnzipFolderLocation = $SrcRoot + "\Localization\Unzip"

        Unzip $outFilePath $UnzipFolderLocation

        BinPlace $UnzipFolderLocation $relativeFilePath $TargetPath $LanguageSet

        write-host "-----ADD FILES TO REPO-----"
        AddFiletoRepo $TargetPath $LanguageSet
    }

    write-host "-----CHECK IN FILES TO REPO-----"
    CheckinFilesIntoRepo
}

RefreshTDFiles