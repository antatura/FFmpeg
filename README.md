# FFmpeg doc


## FFmpeg

示例：

ffmpeg -ss 12 -to 24 -i input.mp4 -c:v libx264 -pix_fmt yuv420p -profile high -level 4.1 -crf 21.5 -preset 6 -x264-params keyint=123:min-keyint=20  -ar 44100 -filter:a loudnorm output.mp4

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



## FFplay 

