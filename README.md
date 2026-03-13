# 🎄FFmpeg

## 🎀A.V.S.D.C




`-crf 18 -preset 8 -tune film -profile:v high -level 51 -pix_fmt yuv420p -maxrate 24M -bufsize 48M -refs 4 -bf 6 -r 30000/1001 -s 1440x1080 -g 290 -keyint_min 1 -fast-pskip 0 -me_method umh -me_range 32 -subq 10 -aq-mode 2 -aq-strength 0.9 -trellis 2 -psy-rd 0.8:0.05 -ar 48000 -b:a 256k -ac 2 -c:a aac -af loudnorm -max_muxing_queue_size 2222`

`-c:v libx265 -pix_fmt yuv420p10le -crf 20 -preset 8 -x265-params "open-gop=0:min-keyint=1:keyint=192:rd=4:ref=6:subme=5:rc-lookahead=60:rect=0:rskip=0:aq-mode=3"`




### 🥕**SSIM/PSNR**

```Bash
ffmpeg -i Main.mp4 -i Refs.mp4 -map v:0 -lavfi ssim -f null -
```




### 🥕**计算Hash值**

```
ffmpeg -i XXX.mkv -map v:0 -f hash -hash murmur3 -
```

- 分别计算帧序列 [60,65) 的Hash值：

```
ffmpeg -i XXX.mkv -map v:0 -vf trim=start_frame=60:end_frame=65 -f framehash -hash murmur3 -
```




### 🥕**VMAF**

- 以下适用于4K屏幕场景，观看距离为1.5倍屏幕高度；记录的帧率可不同，但帧数量与分辨率皆相同（默认皆为逐行扫描）：

```
ffmpeg -r 1 -i Main.mp4 -r 1 -i Refs.mp4 -map v:0 -lavfi [0:v][1:v]libvmaf=model=version=vmaf_4k_v0.6.1:n_threads=16 -f null -
```

- 以下适用于1080P屏幕场景，观看距离为3倍屏幕高度；记录的帧率可不同，帧未精确对齐、切黑边的情况，并生成CSV文件以供分析：

```
ffmpeg -r 1 -colorspace bt709 -i Mian.mp4 -r 1 -colorspace bt709 -i Refs.mp4 -hide_banner -map_chapters -1 -map_metadata -1 -an -sn -dn -lavfi "[0:v:0]trim=start_frame=5000:end_frame=15000,crop=1904:1024[main];[1:v:0]trim=start_frame=5000:end_frame=15000,crop=1904:1024[refs];[main][refs]libvmaf=n_threads=16:log_fmt=csv:log_path=Main.csv" -f null -
```

- 用Powershell计算 1% Low of VMAF

```
$csv = Import-Csv Main.csv; ([double[]]$csv.vmaf | sort | select -First ($csv.Count/100) | measure -AllStats).Average
```

> https://blog.otterbro.com/how-to-vmaf-ffmpeg/

> https://github.com/Netflix/vmaf

> http://ffmpeg.org/ffmpeg-all.html#libvmaf




### 🥕**批处理**

```
for %a in (*.mp4 *.flv) do ffmpeg -i "%a" -crf 20 "output\%~na_cfr-20.mp4"  
```
> 先建立output文件夹；若要保存为.bat，则需将%替换为%%     
   
   
```powershell
Get-ChildItem *.jpg | ForEach-Object { ffmpeg -i $_.Name -lossless 1 "$($_.BaseName).webp" }
```




### 🥕**切片与拼接（非重编码，精确到关键帧）**

```
ffmpeg -i XXX.mkv -map 0 -c copy -f segment -segment_time 10 -reset_timestamps 1 -segment_list XXX.ffcat XXX_%3d.mp4  
ffmpeg -i XXX.ffcat -c copy -video_track_timescale 15360 .\XXX-C.mp4  
```

> 适合 MPEG CFR; 需指定 `-c copy` ，切割时间点将顺延至下一关键帧。

> `-segment_time 10` 等效于 `-segment_times 10,20,30,40,50`

> http://ffmpeg.org/ffmpeg-formats.html#segment_002c-stream_005fsegment_002c-ssegment




### 🥕**重组视频（重编码，精确到帧）**

```
ffmpeg -i XXX.mkv -lavfi "[v:0]trim=0:10,setpts=PTS-STARTPTS[v1];[a:0]atrim=0:10,asetpts=PTS-STARTPTS[a1];[v:0]trim=30:40,setpts=PTS-STARTPTS[v2];[a:0]atrim=30:40,asetpts=PTS-STARTPTS[a2];[v:0]trim=50,setpts=PTS-STARTPTS[v3];[a:0]atrim=50,asetpts=PTS-STARTPTS[a3];[v1][a1][v2][a2][v3][a3]concat=n=3:v=1:a=1[v][a]" -map "[v]" -map "[a]" -crf 16 -c:a alac YYY.mov
```




### 🥕**合并多条视频分段**

```
(for %i in (*.flv) do @echo file '%i') > mylist.txt 
```

```powershell
Get-ChildItem *.mp4 | ForEach-Object { Write-Output "file '$($_.Name)'" } | Out-File mylist.txt  
```

```
ffmpeg -f concat -i mylist.txt -c copy YYY.mkv
```

> https://trac.ffmpeg.org/wiki/Concatenate




### 🥕**提取视频片段**

```
ffmpeg -ss 00:00:18.000 -t 15 -i XXX.mp4 -c copy -avoid_negative_ts make_zero YYY.mp4
```

> `-avoid_negative_ts make_zero`: 从指定起始位置的上一关键帧开始裁切，末端或有缺失帧，起始时间戳或略大于零

> 若输出容器格式为mkv，可省略`-avoid_negative_ts make_zero`; 但mkv默认时间精度为 1k tbn ，较低不适合作为抽取的目标容器

> 若`to`位于`[input]`之后，则视为时间段`t`

> `-ss 18 -t 15 -i ...` 与 `-ss 18 -to 33 -i ...` 等效

> 假设输入视频的起始时间戳为12.000，若...-ss 14...，则从输入视频的原始时间戳26.000开始裁切

> https://trac.ffmpeg.org/wiki/Seeking     

|                          |               优点                |                     缺点                      |
| :----------------------: | :-------------------------------: | :-------------------------------------------: |
| 有 `-c copy`，不重新编码 |             瞬间提取              |             实际时间范围不太精确             |
| 无 `-c copy`，需重新编码 | 实际时间范围准确：18.000s~28.000s |             重编码缓慢，CPU满负载             |




### 🥕**分离视频流与音频流**

```
ffmpeg -i input.mkv -map 0:1 -map 0:2 -c copy audio_only.mkv -map 0:0 -c copy video_only.mkv
```




### 🥕**更改流的默认值**

```
ffmpeg -i XXX.mkv -map 0 -c copy -disposition:a:0 0 -disposition:a:2 default YYY.mkv
```




### 🥕**循环流**

```
ffmpeg -stream_loop 3 -i XXX.wav -c copy XXX_x4.wav
```
  
> Set number of times input stream shall be looped. Loop 0 means no loop, loop -1 means infinite loop.




### 🥕**合并视频与音频**

```
ffmpeg -i XXX.mp4 -i XXX.aac -c copy YYY.mp4
```

> 合并后时长取较长段。若视频较长，则后半段音量为零；若音频较长，则后半段为视频的最后一帧




### 🥕**旋转视频方向**

```
ffmpeg -i XXX.mp4 -map_metadata 0 -metadata:s:v rotate="90" -c copy YYY.mp4
```




### 🥕**裁切视频**

```
ffmpeg -i XXX.mp4 -vf crop=w:h:x:y,scale=3840:-2 YYY.mp4
```




### 🥕**添加黑边**

```
ffmpeg -i XXX.mp4 -vf "pad=1920:1080:(ow-iw)/2:(oh-ih)/2" YYY.mp4
```

```
ffmpeg -i XXX.mp4 -vf scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1 YYY.mp4
```




### 🥕**淡入淡出**

```
ffmpeg -i XXX.mp4 -vf "fade=t=in:st=0:d=5,fade=t=out:st=55:d=5"
```

> 0-5秒：淡入； 55-60秒：淡出




### 🥕**加速视频和音频**

```
ffmpeg -i 30fps.mp4 -lavfi "setpts=0.5*PTS;atempo=2" -r 60 60fps.mp4
```

> https://trac.ffmpeg.org/wiki/How%20to%20speed%20up%20/%20slow%20down%20a%20video




### 🥕**录制桌面**

```
ffmpeg -filter_complex ddagrab=framerate=60,hwdownload,format=bgra,setparams=range=tv:colorspace=bt709:color_trc=bt709:color_primaries=bt709,scale=flags=accurate_rnd+full_chroma_int+bitexact+lanczos,format=yuv420p -c:v h264_amf -profile:v high -quality quality -preset balanced -qp_i 12 -qp_p 12 YYY.mkv
```

```
ffmpeg -probesize 64M -f gdigrab -framerate 30 -i desktop -qp 0 -preset 0 -level 51 YYY.mp4
```

> https://trac.ffmpeg.org/wiki/Capture/Desktop 

> https://ffmpeg.org/ffmpeg-devices.html#gdigrab  

> http://ffmpeg.org/ffmpeg-filters.html#ddagrab




### 🥕**录制声音**

```
ffmpeg -list_devices true -f dshow -i dummy     
ffmpeg -f dshow -i audio="麦克风阵列 (Realtek(R) Audio)" YYY.wav  
ffmpeg -f dshow -i audio="立体声混音 (Realtek(R) Audio)" YYY.wav
```   

> 录制桌面音频需开启麦克风权限并将声音输入设备改为立体声混音  
> 播放音量会影响录制音量









---
## 🎀Video

### 🥕**Nvidia GPU 编解码**

- Encode:
```
ffmpeg -i XXX.mp4 -c:v h264_nvenc -profile:v high -rc-lookahead 32 -bf 4 -b_ref_mode 2 -temporal_aq 1 -spatial_aq 1 -aq-strength 15 -b:v 0 -bufsize 0 -keyint_min 1 -g 300 -an -preset p7 -qp 16 YYY.mp4
```

- Decode:

```
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i XXX.mkv ......
```

> https://developer.nvidia.com/video-encode-and-decode-gpu-support-matrix-new

> https://developer.nvidia.com/blog/nvidia-ffmpeg-transcoding-guide/

> https://github.com/Xaymar/obs-StreamFX/wiki/Encoder-FFmpeg-NVENC

> https://blog.xaymar.com/2020/06/24/the-art-of-encoding-with-nvidia-turing-nvenc/

> https://github.com/rigaya/NVEnc/blob/master/NVEncC_Options.zh-cn.md




### 🥕**GIF 转 Animated WebP**

```
ffmpeg -i XXX.gif -vf scale=320:-1,fps=15 -loop 0 -lossles 1 -y YYY.webp
```




### 🥕**mp4 转 gif**

```
ffmpeg -ss 5 -t 7 -i XXX.mp4 -vf fps=10,scale=480:-2 -loop 0 YYY.gif
```

- 高质量版： 

```
ffmpeg -i XXX.mp4 -vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 YYY.gif
```




### 🥕**添加文字水印**

```
ffmpeg -i XXX.mp4 -vf "drawtext=fontfile=C\\:/Windows/fonts/consola.ttf:text='Abg0123':x=20:y=H-th-20:fontsize=30:fontcolor=white:borderw=3:bordercolor=black" YYY.mp4
```




### 🥕**生成单色视频并添加计时器水印**

```
ffmpeg -f lavfi -i "color=c=0x333333:s=1920x1080:r=10,drawtext=fontfile=C\\:/Windows/fonts/consola.ttf:fontsize=96:fontcolor='white':timecode='00\:00\:00\:00':rate=10:text='TCR\:':boxcolor=0x000000AA:box=1:x=960-text_w/2:y=540" -g 100 -keyint_min 100 -t 60 YYY.mp4
```

> rate = video fps

> [【效果图】](https://i.loli.net/2019/10/02/B8NfrWOpSjwFVc2.png)




### 🥕**周期性显示文字水印（周期1.6s，显示0.8s）**

```
ffmpeg -i XXX.mp4 -vf "drawtext=fontfile=C\\:/Windows/fonts/consola.ttf:text='test0test':x=100:y=100:enable=lt(mod(t\,1.6)\,0.8):fontsize=30:fontcolor=blue" YYY.mp4
```




### 🥕**添加图片水印**

```
ffmpeg -i XXX.mp4 -i XXX.png -filter_complex overlay=20:20:enable='between(t,10,16)' YYY.mp4
```

> 右上：overlay=W-w-20:20  
> 右下：overlay=W-w-20:H-h-20  
> 左下：overlay=20:H-h-20  
> 居中：overlay=(W-w)/2:(H-h)/2  




### 🥕**添加覆盖动画（从t=5s开始，速度400，位置正中）**

```
ffmpeg -i XXX.mp4 -i XXX.png -filter_complex "overlay='if(gte(t,5), -w+(t-5)*400, NAN)':(H-h)/2" YYY.mp4
```




### 🥕**添加Gif图片水印**

```
ffmpeg -i XXX.mp4 -ignore_loop 0 -i XXX.gif -filter_complex overlay=20:20:shortest=1 YYY.mp4
```




### 🥕**跑马灯**

```
ffmpeg -i XXX.mp4 -i XXXX.mp4 -filter_complex "overlay=x='if(gte(t,2), -w+(t-2)*400, NAN)':y=0" YYY.mp4
```





### 🥕**导出图片**


```
ffmpeg -colorspace bt709 -i XXX.mkv -sws_flags accurate_rnd+full_chroma_int+bitexact -map v:0 -vf select='not(mod(n\,2143))',crop=1920:800,format=rgb24 -fps_mode passthrough -pred 2 -frame_pts 1 -v 16 -stats Frame.%06d.png
```





### 🥕**从单一图片创建视频 (FFmpeg 8.0+)**

> 方案一：scale

```
ffmpeg -loop 1 -framerate 30 -t 60 -i XXX.bmp -vf scale=out_color_matrix=bt709:out_primaries=bt709:out_transfer=bt709:out_range=tv:flags=accurate_rnd+full_chroma_int+bitexact+lanczos,format=yuv420p YYY.mp4
```

> 方案二：libplacebo

```
ffmpeg -loop 1 -framerate 30 -t 60 -i XXX.bmp -vf libplacebo=colorspace=bt709:color_primaries=bt709:color_trc=bt709:range=tv:dithering=none:format=yuv420p,sidedata=delete YYY.mp4
```

方案一对比方案二：
质量：总体相似
性能：scale强于libplacebo (scale: 解码50s+滤镜8s; libplacebo: 解码50s+滤镜30s)







### 🥕**HEVC.4K.HDR.10bit >>> x264.1080p.SDR.8bit**

```
-vf zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p,zscale=1920:-2
```


> 使用libplacebo的升级版（推荐）

```
-vf libplacebo=colorspace=bt709:color_primaries=bt709:color_trc=bt709:range=tv:format=yuv420p:w=1920:h=-2,sidedata=delete
```




### 🥕**Dolby Vision >>> SDR**

> Requirement: https://github.com/jellyfin/jellyfin-ffmpeg/releases  

> https://www.reddit.com/r/ffmpeg/comments/yn5krm/comment/iv7a3ui/  

```
-init_hw_device opencl:0 -i XXX.mp4 -vf hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12
```




### 🥕**编码为Prores**

`ffmpeg -h encoder=prores_ks`

```
ffmpeg -i XXX.mp4 -c:v prores_ks -profile:v 4 -pix_fmt yuva444p10le -c:a pcm_s16le YYY.mov
```

> https://video.stackexchange.com/questions/14712/how-to-encode-apple-prores-on-windows-or-linux 
 
> https://trac.ffmpeg.org/wiki/Encode/VFX  

> https://wideopenbokeh.com/AthenasFall/?p=111  

> 相比于prores_ks, prores牺牲了压缩率提升了编码速度（`profile:v`也适用于prores）









---
## 🎀Audio

### 🥕**查询音量**

- RMS:

```
ffmpeg -i XXX.mp4 -af volumedetect -f null nul
```

- EBU R128:

```
ffmpeg -i XXX.mp4 -map a:0 -af ebur128=peak=true:framelog=verbose -f null -
```

> https://ffmpeg.org/ffmpeg-filters.html#ebur128-1




### 🥕**正常化音量大小**

```
ffmpeg-normalize audio.m4a -vn -sn -mn -cn --keep-loudness-range-target -t -17 -tp -1 -ar 48000 -o output.wav
```

> https://github.com/slhck/ffmpeg-normalize




### 🥕**调节音量（10~16s音量为150%）**

```
ffmpeg -i XXX.mp4 -c:v copy -af volume=1.5:enable='between(t,10,16)' YYY.mp4
```

> Volume与CRF算法相似，volume=0.5 相当于 volume=-6dB




### 🥕**绘制音频波形图**

```
ffmpeg -i XXX.wav -filter_complex "showwavespic=s=1920x1080:split_channels=1" -frames:v 1 YYY.png
```

> [【示例图】](https://github.com/antatura/FFmpeg/blob/master/Images/output.png)

> https://trac.ffmpeg.org/wiki/Waveform




### 🥕**绘制音频频谱**

```
ffmpeg -i XXX.mp4 -y -v 16 -lavfi showspectrumpic=s=3584x2048 XXX.png
```

> https://ffmpeg.org/ffmpeg-filters.html#showspectrumpic

> 高度需为2^n; 默认值`4096x2048`可能导致频谱轻微变形




### 🥕**混音**

```
ffmpeg -i 01.wav -i 02.wav -filter_complex amix=inputs=2:duration=first:dropout_transition=2  mix.wav
```









---
## 🎀Subtitle

### 🥕**导出字幕**

```
ffmpeg -i XXX.m2ts -map 0:2 -c:s copy YYY.sup
```




### 🥕**烧制字幕**

```
ffmpeg -ss 12:34 -copyts -i XXX.mkv -ss 12:34 -t 56 -vf "subtitles=XXX.srt:force_style='Fontname=Source Han Serif,Fontsize=28,Outline=2,MarginV=20,PrimaryColour=&H8515C7'" YYY.mkv
```

> &H8515C7 = #C71586




### 🥕**Burn PGS Subtitle**

```
ffmpeg -analyzeduration 100M -probesize 100M -ss 38:10 -t 20 -i XXX.mkv -lavfi "[v:0]setpts=PTS-STARTPTS,pad=3840:2160:(ow-iw)/2:(oh-ih)/2[v1]; [s:0]setpts=PTS-STARTPTS,scale=3840:2160[s1]; [v1][s1]overlay[out]" -map "[out]" -map a:0 YYY.mkv
```




### 🥕**为MP4添加srt字幕**

```
ffmpeg -i XXX.mp4 -i XXX.srt -map 0:v:0 -map 0:a:0 -map 1 -c:v copy -c:a copy -c:s mov_text -metadata:s:s:0 language=chi YYY.mp4
```









# 🎄FFprobe

### 🥕**查看视频Info**

```
ffprobe -v error -show_format -show_streams XXX.mp4
```




### 🥕**输出每一帧的 time, size, type**

```
ffprobe -v error -select_streams v:0 -show_entries frame=pts_time,pkt_size,pict_type -of csv=p=0 XXX.mp4 >XXX.csv
```




### 🥕**获取所有关键帧** 

```
ffprobe -v 16 -select_streams v:0 -skip_frame nokey -show_entries frame=pts_time -of csv=print_section=0 XXX.mp4
```




### 🥕**关键帧计数**

```
ffprobe -v 8 -count_frames -select_streams v:0 -skip_frame nokey -show_entries stream=nb_read_frames -of default=nokey=1:noprint_wrappers=1 XXX.mp4
```

`-skip_frame nokey`: Keyframes

`-skip_frame nointra`: I frames

`-skip_frame bidir`: except B frames

> https://stackoverflow.com/questions/2017843/fetch-frame-count-with-ffmpeg




### 🥕**获取01:25:31前一个关键帧**

```
ffprobe -read_intervals 01:25:31%+#1 -show_entries frame=key_frame,pts_time -of json -v 16 XXX.mkv
```




### 🥕**获取20~40sec的视觉亮度信息(Powershell)**
```
ffprobe -v 16 -f lavfi movie=XXX.mp4,trim=start=20:end=40,signalstats -show_entries frame=pts_time:frame_tags=lavfi.signalstats.YAVG -of csv=p=0 >YAVG.csv; $Data = Import-Csv YAVG.csv -Header pts_time,YAVG; $Data | Export-Csv YAVG.csv -NoTypeInformation
```

> https://www.csvplot.com/   




### 🥕**为MP3导入元数据和封面**

```
ffmpeg -i XXX.mp3 -i XXX.png -map 0:0 -map 1:0 -c copy -id3v2_version 3 -write_id3v1 1 -metadata title="?" -metadata artist="?" -metadata album="?" -metadata comment="Cover (front)" YYY.mp3
```









# 🎄FFplay 


### 🥕**以选定音频流和字幕播放视频**

```
ffplay XXX.mkv -fs -ast 2 -vf subtitles=XXX.mkv:si=0
```




### 🥕**视频差值对比**

```
ffplay -v 16 -fs -f lavfi "movie=XXX.mp4,fps=source_fps,format=gbrp10le[A];movie=YYY.mp4,fps=source_fps,format=gbrp10le[B];[A][B]blend=all_mode=difference,eq=gamma=1.5"
```

> https://ffmpeg.org/ffmpeg-filters.html#blend-1




### 🥕**音频频谱对比**


对比立体声的FR声道：
```
ffplay -v 16 -fs -f lavfi "amovie=XXX.m4a,pan=stereo|c0=FR,showspectrumpic=s=3584x2048,drawbox=y=2112:t=fill,format=gbrp[B];amovie=XXX.wav,pan=stereo|c0=FR,showspectrumpic=s=3584x2048,drawbox=w=142:t=fill,format=gbrp[C];[B][C]blend=all_mode=difference"
```


对比5.1(side)的FC声道：
```
ffmpeg -v 16 -i XXX.m4a -i XXX.wav -lavfi "[0:a]pan=5.1(side)|c0=FC,showspectrumpic=s=7226x4096:stop=20000:fscale=log,drawbox=y=4160:t=fill,format=gbrp[B];[1:a]pan=5.1(side)|c0=FC,showspectrumpic=s=7226x4096:stop=20000:fscale=log,drawbox=w=142:t=fill,format=gbrp[C];[B][C]blend=all_mode=6,format=gbrp,drawbox=y=1020:h=4:c=yellow,drawbox=y=2660:h=4:c=cyan" XXX.qoi
```

> https://ffmpeg.org/ffmpeg-utils.html#toc-Channel-Layout    
> https://qoiformat.org/




### 🥕**N卡硬解**

```
ffplay -vcodec hevc_cuvid -an -x 960 -y 540 XXX.mp4
```









# 🎄metaflac

### 🥕**编辑FLAC元数据与封面**

```
metaflac --remove-all XXX.flac

metaflac --import-tags-from=FlacTags.txt --import-picture-from=cover.jpg XXX.flac
```

> [FlacTags.txt](https://github.com/antatura/FFmpeg/blob/master/Examples/FlacTags.txt) (ANSI编码)

> https://xiph.org/flac/documentation_tools_metaflac.html

> [Vorbis注释规范](https://xiph.org/vorbis/doc/v-comment.html)










