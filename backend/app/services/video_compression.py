import ffmpeg
import os

def compress_video(input_path: str, output_path: str) -> None:
    """
    Compresses a video to 360p resolution to minimize size before uploading.
    """
    try:
        (
            ffmpeg
            .input(input_path)
            .output(output_path, vf='scale=-1:360', vcodec='libx264', crf=28, preset='fast')
            .overwrite_output()
            .run(capture_stdout=True, capture_stderr=True)
        )
    except ffmpeg.Error as e:
        print('stdout:', e.stdout.decode('utf8'))
        print('stderr:', e.stderr.decode('utf8'))
        raise Exception("Video compression failed")
