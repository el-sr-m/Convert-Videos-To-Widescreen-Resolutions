# Convert-Videos-To-Widescreen-Resolutions
A PowerShell script to bulk convert videos to standard widescreen resolutions using ffmpeg

FFMpeg is a great tool for video conversions, however it outputs a lot of unnecessary text to the screen. This script works to minimize the output to a smaller set of useful data:
- The full path and filename of the current input video
- The total time length of the current video
- The total file size of the current video
- The current video time position being processed
- The current video processing percentage completed
- The time it took for ffmpeg to complete the current video conversion
- The full path and filename of the current output video

The script also performs a simplistic check for file path and filename collisions between input videos and output videos before any attempt at processing is started such that the user can address those collisions before starting the bulk conversion process.
