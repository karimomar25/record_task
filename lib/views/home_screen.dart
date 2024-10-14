import 'dart:io';
import 'dart:async'; // مكتبة لتشغيل مؤقت

import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermission();
    _prepareRecorder();
    _audioPlayer = AudioPlayer(); // تهيئة مشغل الصوت
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
  }

  Recording? _recording;
  bool _isRecording = false;
  AnotherAudioRecorder? _audioRecorder;
  bool _isPaused = false;
  AudioPlayer? _audioPlayer; // مشغل الصوت
  Duration _currentPosition = Duration.zero; // لعرض التقدم
  Duration _totalDuration = Duration.zero; // مدة التسجيل أو التشغيل
  Timer? _timer;

// تاني حاجه بتأكد من اذون الميكروفون
  Future<void> _prepareRecorder() async {
    bool hasPermission = await AnotherAudioRecorder.hasPermissions;
    if (!hasPermission) {
      print('no microphone permission');
      return;
    }
    // بحدد مسار التسجيل
    Directory appDirectory = await Directory.systemTemp.createTemp();
    String path = '${appDirectory.path}/audio_recording.aac';

    // تهيئة المسجل نفسه
    _audioRecorder = AnotherAudioRecorder(path, audioFormat: AudioFormat.WAV);
  }

  Future<void> _startRecording() async {
    if (_audioRecorder != null && !_isRecording) {
      await _audioRecorder!.start();
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_audioRecorder != null && _isRecording) {
      Recording? recording = await _audioRecorder!.stop();
      _stopTimer();

      setState(() {
        _isRecording = false;
        _recording = recording;
      });
      print('Recording saved at: ${_recording!.path}');
    }
  }

  Future<void> _pauseRecording() async {
    if (_audioRecorder != null && _isRecording && !_isPaused) {
      await _audioRecorder!.pause();
      _stopTimer();

      setState(() {
        _isPaused = true;
      });
    }
  }

  Future<void> _resumeRecording() async {
    if (_audioRecorder != null && _isPaused) {
      await _audioRecorder!.resume();
      _startTimer();

      setState(() {
        _isPaused = false;
      });
    }
  }

  Future<void> _playRecording() async {
    if (_recording != null && _recording!.path != null) {
      await _audioPlayer!.play(DeviceFileSource(_recording!.path!));
    }
  }

// اول حاجه اشوف اهاندل الاذونات
  Future<void> _requestPermission() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print('Microphone Permission denied');
    }

    var storageStatus = await Permission.storage.request();
    if (status != PermissionStatus.granted) {
      print('Storage Permission denied');
    }
  }

  Future<void> _pausePlayback() async {
    await _audioPlayer!.pause();
  }

  Future<void> _resumePlayback() async {
    await _audioPlayer!.resume();
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

  @override
  void dispose() {
    _audioPlayer?.dispose(); // تحرير مشغل الصوت عند التخلص من الشاشة
    _stopTimer(); // تحرير المؤقت

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isRecording
                ? (_isPaused ? 'Paused...' : 'Recording...')
                : 'Press to Record'),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            if (_isRecording && !_isPaused)
              ElevatedButton(
                onPressed: _pauseRecording,
                child: const Text('Pause Recording'),
              ),
            if (_isPaused)
              ElevatedButton(
                onPressed: _resumeRecording,
                child: const Text('Resume Recording'),
              ),
            if (_recording != null)
              Column(
                children: [
                  Text('Recording saved at: ${_recording!.path}'),
                  Slider(
                    value: _currentPosition.inSeconds.toDouble(),
                    max: _totalDuration.inSeconds.toDouble(),
                    onChanged: (value) {},
                  ),
                  ElevatedButton(
                    onPressed: _playRecording, // زر لتشغيل التسجيل
                    child: const Text('Play Recording'),
                  ),
                  ElevatedButton(
                    onPressed: _pausePlayback, // زر لإيقاف التشغيل مؤقتًا
                    child: const Text('Pause Playback'),
                  ),
                  ElevatedButton(
                    onPressed: _resumePlayback, // زر لاستئناف التشغيل
                    child: const Text('Resume Playback'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
