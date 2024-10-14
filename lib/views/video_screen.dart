import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickVideo(ImageSource source) async {
    final XFile? video = await _picker.pickVideo(source: source);
    if (video != null) {
      _initializeVideoPlayer(File(video.path));
    }
  }

  void _initializeVideoPlayer(File videoFile) {
    _controller = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {});
        _controller!.play(); // يمكننا تشغيل الفيديو تلقائيًا بعد التحميل
      });
  }

  @override
  void dispose() {
    _controller?.dispose(); // تحرير مشغل الفيديو عند التخلص من الشاشة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _pickVideo(ImageSource.gallery),
                child: const Text('Pick Video from Gallery'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _pickVideo(ImageSource.camera),
                child: const Text('Record Video with Camera'),
              ),
              const SizedBox(height: 32),
              if (_controller != null && _controller!.value.isInitialized)
                Column(
                  children: [
                    // ضبط حجم مشغل الفيديو
                    SizedBox(
                      width: 300, // عرض المشغل
                      height: 200, // ارتفاع المشغل
                      child: VideoPlayer(_controller!),
                    ),
                    const SizedBox(height: 16),
                    VideoProgressIndicator(_controller!, allowScrubbing: true),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _controller!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          onPressed: () {
                            setState(() {
                              _controller!.value.isPlaying
                                  ? _controller!.pause()
                                  : _controller!.play();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop),
                          onPressed: () {
                            setState(() {
                              _controller!.pause();
                              _controller!
                                  .seekTo(Duration.zero); // إعادة تشغيل الفيديو
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
