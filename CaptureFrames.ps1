# Name                : CaptureFrames.ps1
# CreationTime        : 2026.02.05 21:03:41
# LastWriteTime       : 2026.06.02 16:37:10
# ChangeLog           : drawtext


#Requires -Version 5.1


param
(
    [string]$Video,
    [string]$Destination='D:\',
    [ValidateSet('Segment','Frame','Tile')][string]$Mode = 'Segment',
    [ValidateSet('BMP','JPEG','PNG')][string]$Format = 'BMP',
    [ValidateRange(1,9999)][int]$Segment_Count = 12,
    [ValidateRange(1,64)][int]$Tile_COLUMNS = 3,
    [ValidateRange(1,64)][int]$Tile_ROWS = 8,
    [ValidateRange(256,16000)][int]$Tile_Width = 3840,
    [ValidateRange(1,[int]::MaxValue)][int]$Frame_Interval,
    [string]$Frame_Crop,
    [ValidateSet('4:2:0','4:4:4')][string]$JPEG_Sampling_Factor = '4:2:0',
    [string]$JPEG_Quality = 85,
    [switch]$NoTimestamp
)




# $ErrorActionPreference = 'Stop'

[System.Console]::InputEncoding = [System.Text.UTF8Encoding]::UTF8
[System.Console]::OutputEncoding = [System.Text.UTF8Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [System.Text.UTF8Encoding]::UTF8

$Date_Beginning = Get-Date
$Path_Beginning = Get-Location




function Invoke-Warning
{
    param($Param_1)
    Write-Host $Param_1 -ForegroundColor Magenta
}




function Invoke-NewFile
{
    Get-Item *.* | Where-Object LastWriteTime -gt $Date_Beginning
}




function Invoke-LoopSegmentBMP
{
    for ($i=1; $i -le $Segment_Count; $i++) 
    {
        $i_D4 = "{0:D4}" -f $i
        $SS = $i*$Duration/($Segment_Count+1)
        # $SS_Point = "{0:hh\.mm\.ss\.\.fff}" -f [timespan]::fromseconds($SS)

        if (!($NoTimestamp))
        {
            $SS_Date = ("{0:hh\:mm\:ss\.fff}" -f [timespan]::fromseconds($SS)).Replace(':','\:')
            $TEXT_Filter = "drawtext=fontfile='C\:/Windows/fonts/consola.ttf':text='$($SS_Date)':x=H/50:y=H-th-x:fontsize=H/25:box=1:boxcolor=Black:fontcolor=White:boxborderw=10"
        }
        

        $Stats = [System.Collections.ArrayList]::new()

        # $ErrorActionPreference = 'Continue'
        ffmpeg -ss $SS -i $Video -y -hide_banner -nostats -map_chapters -1 -map_metadata -1 -map v:0 -frames:v 1 `
        -vf "libplacebo=colorspace=bt709:color_primaries=bt709:color_trc=bt709:range=tv:w=$($BMP_Width):h=-2:format=bgr24,sidedata=delete,showinfo,$($TEXT_Filter)" `
        "$($Fresh_Name)__$($i_D4).bmp" *>&1 | ForEach-Object { $Stats.Add([string]$_) | Out-Null }
        # $ErrorActionPreference = 'Stop'
 

        [array]$NewBMP = Invoke-NewFile

        if (!($NewBMP.Count -eq $i))
        {
            $NewBMP | Remove-Item -ErrorAction SilentlyContinue
            $Stats.ForEach({Invoke-Warning $_})
            Invoke-Warning "`n>>>>  An error occurred as described above."
            return
        }       
    }
}




if (!($Video))
{
    Invoke-Warning "`n>>>>  Run 'Get-Help CaptureFrames.ps1' to get help"
    return
}




if (Get-Command ffmpeg)
{
    [string]$GCC = ffmpeg -version *>&1 | ForEach-Object {"$_"} | Where-Object {$_.Contains('built')} | Select-Object -First 1

    if ($GCC -match '\d+(?:\.\d+){1,3}')
    {
        $GCC_Version = [version]$matches[0]

        if ($GCC_Version -lt [version]'15.2.0')
        {
            Invoke-Warning "`n>>>>  Requirement: FFmpeg 8.0 or later (gcc 15.2.0 or later)  https://www.gyan.dev/ffmpeg/builds/"
            return
        }
    }
    else
    {
        Invoke-Warning "`n>>>>  ???: $($GCC)"
        return
    }
}
else
{
    Invoke-Warning "`n>>>>  Requirement: FFmpeg.exe  https://www.gyan.dev/ffmpeg/builds/"
    return
}




if (($Format -eq 'JPEG') -and !(Get-Command magick))
{
    Invoke-Warning "`n>>>>  Requirement: Magick.exe  https://imagemagick.org/script/download.php#windows"
    return
}




try { $Video = Get-Item $Video -ErrorAction Stop }
catch { $Video = Get-Item -LiteralPath $Video -ErrorAction Stop }

$Fresh_Name = ((Split-Path $Video -Leaf).Replace(' ','_') -replace '[^\p{L}\p{N}/./_/-]').Trim('.')




if (Get-Command ffprobe)
{
    if (ffprobe -v -8 -select_streams v:0 -show_entries stream $Video)
    {
        try
        {
            [double]$Duration = ([array](ffprobe -v -8 -select_streams v:0 -show_entries stream=duration -of default=nk=1:nw=1 $Video))[0]
        }
        catch
        {
            [double]$Duration = ([array](ffprobe -v -8 -show_entries format=duration -of default=nk=1:nw=1 $Video))[0]
        }

        try
        {   
            $Framerate_Tmp = ([array](ffprobe -v -8 -select_streams v:0 -show_entries stream=avg_frame_rate -of default=nk=1:nw=1 $Video))[0]
            [double]$Framerate = $Framerate_Tmp.Split('/')[0]/$Framerate_Tmp.Split('/')[1]
        }
        catch
        {
            $Framerate_Tmp = ([array](ffprobe -v -8 -select_streams v:0 -show_entries stream=r_frame_rate -of default=nk=1:nw=1 $Video))[0]
            [double]$Framerate = $Framerate_Tmp.Split('/')[0]/$Framerate_Tmp.Split('/')[1]
        }

        [int]$Video_Width = ([array](ffprobe -v -8 -select_streams v:0 -show_entries stream=width -of default=nk=1:nw=1 $Video))[0]
        [int]$Video_Height = ([array](ffprobe -v -8 -select_streams v:0 -show_entries stream=height -of default=nk=1:nw=1 $Video))[0]


        if (!($Duration -and $Framerate -and $Video_Width))
        {
            Invoke-Warning "`n>>>>  Failed to get info for Duration, Framerate, or Video_Width."
            return
        }
    }
    else
    {
        Invoke-Warning "`n>>>>  The input file is required to contain at least one video stream."
        return
    }
}
else
{
    Invoke-Warning "`n>>>>  Requirement: FFprobe.exe  https://www.gyan.dev/ffmpeg/builds/"
    return
}









try { Set-Location $Destination -ErrorAction Stop }
catch { Set-Location -LiteralPath $Destination -ErrorAction Stop }




if ($Mode -eq 'Segment')
{
    $BMP_Width = $Video_Width
    Invoke-LoopSegmentBMP
}




if ($Mode -eq 'Tile')
{ 
    $Padding = 8

    $Tile_Width = [math]::Min(($Video_Width+$Padding)*$Tile_COLUMNS-$Padding,$Tile_Width)
    $BMP_Width =[math]::Floor(($Tile_Width-($Tile_COLUMNS-1)*$Padding)/$Tile_COLUMNS/2)*2

    $BMP_Height = [math]::Ceiling($BMP_Width/$Video_Width*$Video_Height/2)*2
    $Tile_Height = ($BMP_Height+$Padding)*$Tile_ROWS-$Padding

    if ($Tile_Height -le 16000)
    {
        $Segment_Count = $Tile_COLUMNS*$Tile_ROWS
        Invoke-LoopSegmentBMP

        [array]$NewBMP = Invoke-NewFile

        ffmpeg -y -v -8 -i "$($Fresh_Name)__%04d.bmp" -vf "tile=layout=$($Tile_COLUMNS)x$($Tile_ROWS):padding=$($Padding),format=bgr24" "Tile__$($Fresh_Name).bmp"
        
        $NewBMP | Remove-Item -ErrorAction SilentlyContinue
    }
    else 
    {
        Invoke-Warning "`n>>>>  When       : Tile_COLUMNS = $($Tile_COLUMNS)"
        Invoke-Warning "`n>>>>  Requirement: Tile_ROWS <= $([math]::Floor((16000+$Padding)/($BMP_Height+$Padding)))"
    }
}




if ($Mode -eq 'Frame')
{
    if ($Frame_Interval)
    {
        if ($Frame_Crop)
        {
            $Crop_Filter = "crop=$($Frame_Crop)"
        }


        $Stats = [System.Collections.ArrayList]::new()

        # $ErrorActionPreference = 'Continue'
        ffmpeg -i $Video -y -hide_banner -nostats -map_chapters -1 -map_metadata -1 -map v:0 `
        -vf "select=not(mod(n\,$($Frame_Interval))),libplacebo=colorspace=bt709:color_primaries=bt709:color_trc=bt709:range=tv:format=bgr24,sidedata=delete,showinfo,$($Crop_Filter)" `
        -fps_mode passthrough -frame_pts 1 Frame.%06d.bmp *>&1 | ForEach-Object { $Stats.Add([string]$_) | Out-Null }
        # $ErrorActionPreference = 'Stop'


        [array]$Showinfo = $Stats | Where-Object { $_.Contains('showinfo') -and $_.Contains('type:') }

        [array]$NewBMP = Invoke-NewFile

        if (($NewBMP) -and ($NewBMP.Count -eq $Showinfo.Count))
        {
            for ($i=0; $i -lt $NewBMP.Count; $i++)
            {
                $pict_type = $Showinfo[$i].Substring($Showinfo[$i].IndexOf('type:')+5,1)
        
                if ($pict_type -notin ('I','P','B'))
                {
                    $pict_type = '#'
                }

                $NewName = "$($NewBMP[$i].BaseName)__-$($pict_type)-__$($Fresh_Name).bmp"
                Remove-Item $NewName -ErrorAction SilentlyContinue
                Rename-Item $NewBMP[$i].Name $NewName 
            }
        }
        else
        {
            $NewBMP | Remove-Item -ErrorAction SilentlyContinue
            $Stats.ForEach({Invoke-Warning $_})
            Invoke-Warning "`n>>>>  An error occurred as described above."
            Invoke-Warning "`n>>>>  Examples:  [-Frame_Crop 1920:800:0:140]  [-Frame_Crop 1920:800]  https://ffmpeg.org/ffmpeg-all.html#crop"

        }
    }
    else
    {
        Invoke-Warning "`n>>>>  Requirement: [Frame_Interval]"
        Invoke-Warning "`n>>>>  Reference: The total number of frames in the video is estimated to be [$([int]($Duration*$Framerate))]."
    }
}




[array]$NewBMP = Invoke-NewFile

if ($NewBMP)
{
    if ($Format -eq 'BMP')
    {
        $NewBMP | Select-Object FullName | Format-List
    }

    if ($Format -eq 'JPEG')
    {
        $NewBMP | ForEach-Object { magick $_.Name -strip -sampling-factor $JPEG_Sampling_Factor -quality $JPEG_Quality "$($_.BaseName).jpg" }
        $NewBMP | Remove-Item
        Invoke-NewFile | Select-Object FullName | Format-List
    }

    if ($Format -eq 'PNG')
    {
        $NewBMP | ForEach-Object { ffmpeg -y -v 16 -i $_.Name -pred 5 "$($_.BaseName).png" }
        $NewBMP | Remove-Item
        Invoke-NewFile | Select-Object FullName | Format-List
    }
}




Set-Location -LiteralPath $Path_Beginning

Get-Date
