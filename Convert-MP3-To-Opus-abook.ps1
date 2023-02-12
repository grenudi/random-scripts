param(
    [Parameter(Position=0,mandatory=$true)]
    $DirectoryFullPath,
    $Threads=2,
    $ApplicationType="voip",
    $BitRate="32k"
    )

$bookLocation = $DirectoryFullPath;
$opusLocation = "$bookLocation\opus";
mkdir $opusLocation 2> $null;
Write-Host -BackgroundColor blue -ForegroundColor white "bookLocation: $bookLocation";
Write-Host -BackgroundColor blue -ForegroundColor white "opusLocation: $opusLocation";

Get-Job | Stop-Job ;
Get-Job | Remove-Job;


function getRunning(){
    return $(get-job | ?{$_.state -match "Running"} | measure).count ;
}
function displayJobs(){
    Start-Sleep 1;
    clear;
    Get-Job | ft id,name,state,output -auto -wrap; 
}

$scr = {
    $fullInputFilePath = $args[0];
    $fullOutputFilePath = $args[1];
    $applicationType = $args[2];
    $bitRate = $args[3];
    # -compression_level 10 -frame_duration 60 
    ffmpeg -y -hwaccel cuda -i $fullInputFilePath -c:a libopus -b:a $bitRate -vbr on -application $applicationType $fullOutputFilePath $null $null 2>$1 ;
};

ls $bookLocation | ?{$_.Extension -match "mp3" -OR $_.Extension -match "flac"} | %{
    $tmp = $_;
    $fullInputFilePath = "$bookLocation\$($tmp.Name)";
    $fullOutputFilePath = "$opusLocation\$($tmp.BaseName).opus";

    while($(getRunning) -ge $Threads){
        displayJobs ;
    };

    Write-Host -BackgroundColor green -ForegroundColor white $fullInputFilePath ; 
    Start-Job -Name $tmp.Name $scr -ArgumentList $fullInputFilePath,$fullOutputFilePath,$applicationType,$BitRate 1> $null;
}  

While (Get-Job | where { $_.State -eq "Running" } )
{
    displayJobs;
}

Write-Host -BackgroundColor green -ForegroundColor white "============= ALL DONE ===============";