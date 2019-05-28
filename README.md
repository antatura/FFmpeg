# FFmpeg

## FFmpeg

* 提取视频片段

```
ffmpeg  -ss 00:00:18 -to 00:00:28 -i XXX.mp4 -c copy "D:\YYY.mp4"
```

## FFprobe

* 查看视频Info

```
ffprobe -v error -show_format -show_streams XXX.mp4
```

## FFplay

