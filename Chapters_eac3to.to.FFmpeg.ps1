
$cpt = Read-Host -Prompt 'Input Chapter Text'
$vdo = Read-Host -Prompt 'Input Video File'
$gc = Get-Content $cpt
Add-Content "$cpt.ffmd" ";FFMETADATA1"


for ($x=0; $x -lt $gc.Count; $x+=2) 
{
    $start = $gc[$x].Substring(10,12)
    $start_ticks = [timespan]::Parse($start).Ticks*100
    $title = $gc[$x+1].Substring(14)

    if (!$title) 
    {
        $tn = "{0:D2}" -f ($x/2+1); $title = "Chapter $tn"
    }

    if ($x -eq ($gc.Count-2))
    {
        $dur = [double](ffprobe -v 16 -show_entries format=duration -of csv=p=0 $vdo)
        $end_ticks = [int64]$dur*10e8
    }
    else
    {
        $end = $gc[$x+2].Substring(10,12)
        $end_ticks = [timespan]::Parse($end).Ticks*100
    }

    Add-Content "$cpt.ffmd" "`n[CHAPTER]`nSTART=$start_ticks`nEND=$end_ticks`nTITLE=$title"  
}

