# FFmpeg doc


## FFmpeg

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
ffmpeg -i input.jpg -compression_level 6 -q 90 output.webp
```

> https://ffmpeg.org/ffmpeg-all.html#toc-Options-27   



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
