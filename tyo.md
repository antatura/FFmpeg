|         Option         |                  Value                  |                            Note                            |
| :--------------------: | :-------------------------------------: | :--------------------------------------------------------: |
| -max_muxing_queue_size |    512<br />999<br />4000<br />9999     | 解决错误：Too many packets buffered for output stream 0:0. |
|        -pix_fmt        | yuv420p<br />yuvj420p<br />yuv420p10le  |            设定像素格式，详见：ffmpeg -pix_fmts            |
|   -af<br />-filter:a   |                loudnorm                 |                         音量正常化                         |
|   -vf<br />-filter:v   |           subtitles=input.srt           |                          烧制字幕                          |
|           -h           | encoder=libx264<br />encoder=h264_nvenc |                     查阅编码器帮助信息                     |
|                        |                                         |                                                            |
|                        |                                         |                                                            |
|                        |                                         |                                                            |
|           8            |                    8                    |                             9                              |

