import 'dart:io';
import 'dart:async';
import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voice_and_video_task/views/video_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Recording? _recording;
  bool _isRecording = false;
  AnotherAudioRecorder? _audioRecorder;
  final bool _isPaused = false;
  AudioPlayer? _audioPlayer;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _timer;
  final List<File> _recordings = [];
  int _recordingCount = 0;
  bool _isPlaying = false;
  bool _isPlaybackPaused = false;
  File? _currentFile;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _prepareRecorder();
    _audioPlayer = AudioPlayer();
    _audioPlayer!.onDurationChanged.listen((Duration duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    _audioPlayer!.onPositionChanged.listen((Duration position) {
      setState(() {
        _currentPosition = position;
      });
    });

    _audioPlayer!.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    });
  }

  Future<void> _prepareRecorder() async {
    bool hasPermission = await AnotherAudioRecorder.hasPermissions;
    if (!hasPermission) {
      print('No microphone permission');
      return;
    }
    Directory appDirectory = await getApplicationDocumentsDirectory();
    String path =
        '${appDirectory.path}/audio_recording_${_recordingCount + 1}.aac';
    _audioRecorder = AnotherAudioRecorder(path, audioFormat: AudioFormat.WAV);
  }

  Future<void> _startRecording() async {
    if (_audioRecorder != null && !_isRecording) {
      await _audioRecorder!.start();
      _startTimer();
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_audioRecorder != null && _isRecording) {
      Recording? recording = await _audioRecorder!.stop();
      _stopTimer();

      File recordingFile = File(recording!.path!);
      setState(() {
        _recordingCount++;
        _isRecording = false;
        _recordings.add(recordingFile);
      });

      print('Recording saved at: ${recording.path}');
    }
  }

  Future<void> _playRecording(File file, int index) async {
    // إيقاف المقطع الحالي إذا كان يعمل
    if (_isPlaying && _currentFile != file) {
      await _audioPlayer!.stop();
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    }

    // تشغيل المقطع الجديد
    if (!_isPlaying || _isPlaybackPaused || _currentFile != file) {
      await _audioPlayer!.play(DeviceFileSource(file.path));
      setState(() {
        _isPlaying = true;
        _isPlaybackPaused = false;
        _currentFile = file;
      });
    }
  }

  Future<void> _pausePlayback() async {
    if (_isPlaying) {
      await _audioPlayer!.pause();
      setState(() {
        _isPlaybackPaused = true;
        _isPlaying = false;
      });
    }
  }

  Future<void> _resumePlayback() async {
    if (_isPlaybackPaused) {
      await _audioPlayer!.resume();
      setState(() {
        _isPlaying = true;
        _isPlaybackPaused = false;
      });
    }
  }

  Future<void> _deleteRecording(int index) async {
    File file = _recordings[index];

    if (await file.exists()) {
      await file.delete();

      setState(() {
        _recordings.removeAt(index);
        if (_currentFile == file) {
          _currentFile = null;
          _isPlaying = false;
          _isPlaybackPaused = false;
          _currentPosition = Duration.zero;
        }
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentPosition = Duration(seconds: timer.tick);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print('Microphone Permission denied');
    }

    var storageStatus = await Permission.storage.request();
    if (storageStatus != PermissionStatus.granted) {
      print('Storage Permission denied');
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return VideoPlayerScreen();
                  },
                ));
              },
              icon: Icon(Icons.video_call))
        ],
        title: const Text('Audio Recorder'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isRecording)
              Text(
                "${_currentPosition.inMinutes}:${_currentPosition.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                style:
                    const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                backgroundColor: _isRecording ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _recordings.length,
                itemBuilder: (context, index) {
                  File file = _recordings[index];
                  return ListTile(
                    title: Text('Recording ${index + 1}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteRecording(index),
                    ),
                    subtitle: _currentFile == file
                        ? Column(
                            children: [
                              Slider(
                                value: _currentPosition.inSeconds.toDouble(),
                                max: _totalDuration.inSeconds.toDouble(),
                                onChanged: (value) async {
                                  await _audioPlayer!
                                      .seek(Duration(seconds: value.toInt()));
                                },
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.pause),
                                    onPressed: _pausePlayback,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow),
                                    onPressed: _resumePlayback,
                                  ),
                                ],
                              ),
                            ],
                          )
                        : null,
                    onTap: () => _playRecording(file, index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
