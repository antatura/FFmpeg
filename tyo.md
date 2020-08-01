|         Option         |                  Value                  |                             Note                             |
| :--------------------: | :-------------------------------------: | :----------------------------------------------------------: |
| -max_muxing_queue_size |    512<br />999<br />4000<br />9999     |  解决错误：Too many packets buffered for output stream 0:0.  |
|        -pix_fmt        | yuv420p<br />yuvj420p<br />yuv420p10le  |             设定像素格式，详见：ffmpeg -pix_fmts             |
|   -af<br />-filter:a   |                loudnorm                 |                          音量正常化                          |
|   -vf<br />-filter:v   |           subtitles=input.srt           |                           烧制字幕                           |
|           -h           | encoder=libx264<br />encoder=h264_nvenc |        查阅编码器帮助信息<br />详见：ffmpeg -encoders        |
|      -write_tmcd       |                    0                    | 解决错误：Stream #0:2(eng): <br />Data: none (tmcd / 0x64636D74)<br/>          handler_name: Apple Video Media Handler<br/>      timecode: 00:00:00:00<br/>Unsupported codec with id 0 for input stream 2 |
|     -map_chapters      |                   -1                    |                         剥离章节信息                         |
|     -map_metadata      |                   -1                    |                          剥离元数据                          |
|   -output_ts_offset    |                    -                    |                          时间戳补偿                          |
|           -            |                    -                    |                              -                               |

