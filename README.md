# 🎄FFmpeg

## 🎀A.V.S.D.C




`-crf 18 -preset 8 -tune film -profile:v high -level 51 -pix_fmt yuv420p -maxrate 24M -bufsize 48M -refs 4 -bf 6 -r 30000/1001 -s 1440x1080 -g 290 -keyint_min 1 -fast-pskip 0 -me_method umh -me_range 32 -subq 10 -aq-mode 2 -aq-strength 0.9 -trellis 2 -psy-rd 0.8:0.05 -ar 48000 -b:a 256k -ac 2 -c:a aac -af loudnorm -max_muxing_queue_size 2222`

`-c:v libx265 -preset 7 -keyint_min 1 -pix_fmt yuv420p10le -x265-params open-gop=0:sao=0:strong-intra-smoothing=0:colormatrix=1:qg-size=8:rect=0:ref=4:rd=4:pbratio=1.2:cbqpoffs=-2:crqpoffs=-2:qcomp=0.65:lookahead-slices=4:tu-inter-depth=2:tu-intra-depth=2:limit-refs=3:deblock=-1:merange=25:ctu=32:rc-lookahead=60:bframes=6 -crf 23 -g 200`




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
ffmpeg -r 1 -i Main.mp4 -r 1 -i Refs.mp4 -map v:0 -lavfi libvmaf=model=version=vmaf_4k_v0.6.1:n_threads=16 -f null -
```

- 以下适用于1080P屏幕场景，观看距离为3倍屏幕高度；记录的帧率相同，但帧未精确对齐、分辨率未匹配的情况，并生成CSV文件以供分析：
```
ffmpeg -i Main.mp4 -i Refs.mp4 -hide_banner -map v:0 -lavfi "[0:v]fps=source_fps,scale=1920:1080[main];[1:v]fps=source_fps,scale=1920:1080[refs];[main][refs]libvmaf=model=version=vmaf_v0.6.1:n_threads=16:log_fmt=csv:log_path=Main.csv" -f null -
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




### 🥕**切片与拼接**

```
ffmpeg -i XXX.mov -map 0 -c copy -f segment -segment_time 17 -reset_timestamps 1 -segment_list XXX.ffcat XXX_%3d.mov  
ffmpeg -i XXX.ffcat -c copy .\XXX-C.mov  
```

> 适合 MPEG CFR; 每17秒切一刀; 切片首帧为关键帧
  
> `-segment_times 13,18,55` 以每个时间点之后的关键帧为切割点，若切割时间点与上一个相同，则顺延到下一个关键帧

> http://ffmpeg.org/ffmpeg-formats.html#segment_002c-stream_005fsegment_002c-ssegment




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
ffmpeg -ss 00:00:18.000 -t 15 -i XXX.mp4 -c copy -avoid_negative_ts 1 YYY.mp4
```

> `-avoid_negative_ts 1`: 从指定起始位置的上一关键帧开始裁切，末端或有缺失帧，起始时间戳或略大于零

> 若输出容器格式为mkv，可省略`-avoid_negative_ts 1`

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
ffmpeg -filter_complex ddagrab=framerate=60,hwdownload,format=bgra,scale=out_color_matrix=bt709:out_range=tv -c:v h264_amf -profile:v high -quality balanced -qp_i 14 -qp_p 16 YYY.mp4
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

> 需开启麦克风权限； 播放音量会影响录制音量









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





### 🥕**导出图片并合并**

```
ffmpeg -ss 10 -i XXX.mp4 -frames:v 1 YYY.png
```

```
ffmpeg -ss 10 -i XXX.mp4 -frames:v 120 YYY_%3d.png
```

```
ffmpeg -framerate 30 -i YYY_%3d.png -c copy YYY.mkv
```




### 🥕**创建仅包含图像的视频**

```
ffmpeg -loop 1 -framerate FPS -t 5 -i XXX.png -pix_fmt yuv420p YYY.mp4
```




### 🥕**转换为BT.709有限色彩空间并定义相关标签**

```
-vf zscale=range=limited:matrix=709,format=yuv420p -color_trc bt709 -color_primaries bt709
```




### 🥕**HEVC.4K.HDR.10bit >>> x264.1080p.SDR.8bit**

```
-vf zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p,zscale=1920:-2
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
ffmpeg -i XXX.mp4 -y -v 16 -lavfi showspectrumpic=s=1764x1024:color=fruit:drange=120 X.png; ffplay -v 16 -fs X.png
```

> [【示例图】](https://github.com/antatura/FFmpeg/blob/master/Images/spectrogram-q.png)

> https://ffmpeg.org/ffmpeg-filters.html#showspectrumpic

> 高度需为2的幂次方




### 🥕**本地aac高质量编码**

```
ffmpeg -i XXX.aac -ar 48000 -b:a 256k -aac_coder 1 -strict -2 -cutoff 24000 YYY.aac
```




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
ffprobe -i XXX.mkv -show_frames -read_intervals 01:25:31%+#1
```




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

```
ffplay -v 16 -fs -f lavfi "amovie=XXX.m4a,showspectrumpic,drawbox=y=2113:t=fill,format=rgb24[A];amovie=XXX.wav,showspectrumpic,drawbox=w=iw/2-2050:t=fill,format=rgb24[B];[A][B]blend=all_mode=difference"
```

```
ffmpeg -v 16 -i XXX.m4a -i XXX.wav -lavfi "[0:a]showspectrumpic=s=8192x4096:stop=20000:fscale=log,drawbox=y=4161:t=fill,format=rgb24[A];[1:a]showspectrumpic=s=8192x4096:stop=20000:fscale=log,drawbox=w=iw/2-4098:t=fill,format=rgb24[B];[A][B]blend=all_mode=6,format=rgb24,drawbox=y=1020:h=4:c=yellow,drawbox=y=2660:h=4:c=cyan" XXX.png
```

> 若采样率为48000Hz，则AAC时长不可为100秒，否则其频谱可能出现拉伸或收缩`??????`     
> 若采样率为44100Hz，则AAC时长不可为90秒左右，否则其频谱可能出现拉伸或收缩`??????`




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




