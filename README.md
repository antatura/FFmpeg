# FFmpeg doc


## FFmpeg

示例：

ffmpeg -ss 02:30 -t 75 -i XXX.mp4 -crf 18 -preset 8 -tune animation -profile:v high -level 51 -pix_fmt yuv420p -refs 4 -bf 6 -r 30 -s 1440x1080 -g 290 -keyint_min 1 -fast-pskip 0 -me_method umh -me_range 32 -subq 10 -aq-mode 2 -aq-strength 0.9 -trellis 2 -psy-rd 0.8:0.05 -ar 48000 -ab 128k -ac 2 -c:a aac -af loudnorm -max_muxing_queue_size 512 YYY.mp4

* **提取视频片段**

```
ffmpeg  -ss 00:00:18.000 -to 00:00:28.000 -i XXX.mp4 -c copy "D:\YYY.mp4"
```

> https://trac.ffmpeg.org/wiki/Seeking     

|                          |               优点                |                     缺点                      |
| :----------------------: | :-------------------------------: | :-------------------------------------------: |
| 有 `-c copy`，不重新编码 |             瞬间提取              | 实际时间范围不准：(上一关键帧)17.345s~28.000s |
| 无 `-c copy`，需重新编码 | 实际时间范围准确：18.000s~28.000s |             重编码缓慢，CPU满负载             |

- **合并多条视频分段**

```
(for %i in (*.flv) do @echo file '%i') > mylist.txt

ffmpeg -f concat -i mylist.txt -c copy YYY.flv
```

> <https://trac.ffmpeg.org/wiki/Concatenate>  

- **录制桌面**

> https://trac.ffmpeg.org/wiki/Capture/Desktop  

CPU

```
ffmpeg -f gdigrab -framerate 30 -i desktop -qp 0 -preset 0 -level 51 YYY.mp4
```

```
ffmpeg -thread_queue_size 512 -f gdigrab -framerate 30 -i desktop -f dshow -i audio="立体声混音 (Realtek(R) Audio)" -qp 0 -preset 0 -level 51 YYY.mp4
```

GPU

```
ffmpeg -f gdigrab -framerate 30 -i desktop -c:v h264_nvenc -qp 0 -profile:v high -level 51 output.mkv
```

同时录制声音

```
ffmpeg -list_devices true -f dshow -i dummy     
ffmpeg -f gdigrab -framerate 30 -i desktop -f dshow -i audio="麦克风阵列 (Realtek(R) Audio)" YYY.mp4  
ffmpeg -f gdigrab -framerate 30 -i desktop -f dshow -i audio="立体声混音 (Realtek(R) Audio)" YYY.mp4
```

- **旋转视频方向**

```
ffmpeg -i XXX.mp4 -map_metadata 0 -metadata:s:v rotate="90" -c copy YYY.mp4
```

- **调整画面大小**

```
ffmpeg -i XXX.mp4 -vf scale=2160:-2 -preset 2 YYY.mp4
```

- **裁切视频**

```
ffmpeg -i XXX.mp4 -vf crop=out_w:out_h:x:y YYY.mp4
```

- **批处理**

```
for %a in (*.mp4 *.flv) do ffmpeg -i "%a" -crf 20 "output\%~na_cfr-20.mp4"
```

> 先建立output文件夹；若要保存为.bat，则需将%替换为%%     

- **提取音频**

```
ffmpeg -i XXX.mkv -vn -ar 44100 -ab 312k YYY.aac
```

- **合并视频与音频**

```
ffmpeg -i A1.mp4 -i A2.mp4 -c copy A3.mp4
```

- **图片转WebP**

```
ffmpeg -i input.jpg -q 90 output.webp
```

> https://ffmpeg.org/ffmpeg-all.html#toc-Options-27   

- GIF 转 Animated WebP

```
ffmpeg -i input.gif -vf scale=320:-1,fps=15 -loop 0 -lossles 1 -y output.webp
```

- **mp4 转 gif**

```
ffmpeg -i input.mp4 -vf fps=10,scale=480:-1 -loop 0 output.gif
```

高质量版:         
```
ffmpeg -i input.mp4 -vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 output1.gif
```

- **导出字幕**

```
ffmpeg -i 00905.m2ts -map 0:2 -c:s copy 02.sup
```

- **烧制字幕**

```
ffmpeg -i XXX.mp4 -vf subtitles=XXX.ass -preset 0 -CRF 34 YYY.MP4
```

- **添加文字水印**

```
ffmpeg -i XXX.mp4 -vf "drawtext=font=consolas:text='Abg0123':x=20:y=H-th-20:fontsize=30:fontcolor=white:borderw=3:bordercolor=black" YYY.mp4
```

计时器

```
ffmpeg -i XXX.mp4 -vf "drawtext=fontfile=C\\:/Windows/fonts/consola.ttf:fontsize=72:fontcolor='white':timecode='00\:00\:00\:00':rate=30:text='TCR\:':boxcolor=0x000000AA:box=1:x=860-text_w/2:y=960" YYY.mp4
```

[效果图](https://i.loli.net/2019/10/02/B8NfrWOpSjwFVc2.png)

- **添加图片水印**

```
ffmpeg -i XXX.mp4 -i XXX.png -filter_complex overlay=20:20 -preset 0 YYY.mp4
```

右上：overlay=W-w-20:20  
右下：overlay=W-w-20:H-h-20  
左下：overlay=20:H-h-20  
居中：overlay=(W-w)/2:(H-h)/2  

- **查询音量**

```
ffmpeg -i nfs.mp4 -af volumedetect -f null nul
```

- **导出图片**

```
ffmpeg -ss 10 -i XXX.mp4 -frames:v 1 YYY.png
```

```
ffmpeg -ss 10.123 -i XXX.mp4 -frames:v 9 YYY_%3d.png
```

## FFprobe

* **查看视频Info**

```
ffprobe -v error -show_format -show_streams XXX.mp4
```

- **获取所有关键帧** 

```
ffprobe -loglevel error -skip_frame nokey -select_streams v:0 -show_entries frame=pkt_pts_time -of csv=print_section=0 XXX.mp4
```

- **获取01:25:31前一个关键帧**

```
ffprobe -i XXX.mkv -show_frames -read_intervals 01:25:31%+#1
```

- **输出每一帧的大小**
```
ffprobe -select_streams v -show_entries packet=size:stream=duration -of compact=p=0:nk=1 XXX.mp4 >bitrate.csv
```



## FFplay 

