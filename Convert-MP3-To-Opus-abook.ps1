param(
    [Parameter(Position=0,mandatory=$true)]
    $DirectoryFullPath,
    $Threads=2
    )

$bookLocation = $DirectoryFullPath;
$opusLocation = "$bookLocation\opus";
mkdir $opusLocation 2> $null;
Write-Host -BackgroundColor blue -ForegroundColor white "bookLocation: $bookLocation";
Write-Host -BackgroundColor blue -ForegroundColor white "opusLocation: $opusLocation";

Get-Job | Stop-Job ;
Get-Job | Remove-Job;

$scr = {
    $fullInputFilePath = $args[0];
    $fullOutputFilePath = $args[1];
    ffmpeg -hwaccel cuda -i $fullInputFilePath -c:a libopus -b:a 32k -vbr on -compression_level 10 -frame_duration 60 -application voip $fullOutputFilePath $null $null 2>$1 ;
};

$i = 0;
ls $bookLocation | ?{$_.Extension -match "mp3"} | %{
    $tmp = $_;
    $fullInputFilePath = "$bookLocation\$($tmp.Name)";
    $fullOutputFilePath = "$opusLocation\$($tmp.BaseName).opus";

    if($i%$Threads -eq 0)
    {
        Write-Host -BackgroundColor green -ForegroundColor white $fullInputFilePath ; 
        Invoke-Command -ScriptBlock $scr -ArgumentList $fullInputFilePath,$fullOutputFilePath;
    }else{
        Write-Host -BackgroundColor red -ForegroundColor white $fullInputFilePath ; 
        Start-Job -Name $tmp.Name $scr -ArgumentList $fullInputFilePath,$fullOutputFilePath 1> $null;
    }
    $i++;
}  

While (Get-Job | where { $_.State -eq "Running" } )
{
    Start-Sleep 1;
    clear;
    Get-Job | ft id,name,state,output -auto -wrap; 
}

Write-Host -BackgroundColor green -ForegroundColor white "============= ALL DONE ===============";