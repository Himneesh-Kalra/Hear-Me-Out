import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:io';

class CameraStreamPage extends StatefulWidget {
  const CameraStreamPage({super.key});

  @override
  _CameraStreamPageState createState() => _CameraStreamPageState();
}

class _CameraStreamPageState extends State<CameraStreamPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  IO.Socket? _socket;
  bool _isStreaming = false;
  bool _isConnected = false;
  bool _isCameraLoading = true;
  String _translatedText = "Waiting for translation...";
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initCameras();
    _connectToSocketIO();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("🔄 Translation Screen Re-entered: Reconnecting Socket...");
    _connectToSocketIO(); // Ensure reconnection
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        await _initializeCamera(_selectedCameraIndex);
      } else {
        print("No cameras available");
      }
    } catch (e) {
      print("Error fetching cameras: $e");
    }
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    setState(() {
      _isCameraLoading = true;
    });

    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    _controller =
        CameraController(_cameras![cameraIndex], ResolutionPreset.medium);

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraLoading = false;
        });
      }
    } catch (e) {
      print("Error initializing camera: $e");
      setState(() {
        _isCameraLoading = false;
      });
    }
  }

  void _switchCamera() async {
    if (_cameras != null && _cameras!.length > 1) {
      int newCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
      setState(() {
        _selectedCameraIndex = newCameraIndex;
      });
      await _initializeCamera(newCameraIndex);
    }
  }

  void _connectToSocketIO() {
    if (_socket != null) {
      print("🔄 Closing previous socket connection...");
      _socket!.dispose(); // Dispose previous socket instance
    }

    print("Connecting to Socket.IO at http://127.0.0.1:5000");
    _socket = IO.io('http://127.0.0.1:5000/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.on('connect', (_) {
      print('✅ Connected to Socket.IO server');
      setState(() {
        _isConnected = true;
      });
    });

    _socket!.on('translation', (data) {
      setState(() {
        _translatedText = data;
      });
      _speakText(data);
    });

    _socket!.on('disconnect', (_) {
      print('❌ Disconnected from Socket.IO server');
      setState(() {
        _isConnected = false;
      });
      _reconnectSocketIO();
    });

    _socket!.on('error', (error) {
      print('⚠️ Socket.IO error: $error');
      setState(() {
        _isConnected = false;
      });
      _reconnectSocketIO();
    });

    _socket!.connect(); // Explicitly call connect()
  }

  void _reconnectSocketIO() {
    Future.delayed(Duration(seconds: 5), () {
      if (!_isConnected) {
        print('Attempting to reconnect to Socket.IO server...');
        _connectToSocketIO();
      }
    });
  }

  Future<void> _speakText(String text) async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.speak(text);
    } catch (e) {
      print("Error speaking text: $e");
    }
  }

  Future<void> _startStreaming() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_isConnected) {
      return;
    }

    setState(() {
      _isStreaming = true;
    });

    while (_isStreaming) {
      try {
        // Capture a frame from the camera
        XFile image = await _controller!.takePicture();
        Uint8List imageBytes = await image.readAsBytes();

        // Send the frame to the server
        _socket!.emit('frame', base64Encode(imageBytes));

        // Delete the temporary file
        File(image.path).deleteSync();
      } catch (e) {
        print("Error streaming frame: $e");
      }

      if (!_isStreaming) break;

      // Add a small delay to control the frame rate
      await Future.delayed(Duration(milliseconds: 230));
    }
  }

  void _stopStreaming() {
    if (_isStreaming) {
      setState(() {
        _isStreaming = false;
      });
      print("Streaming stopped.");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hear Me Out!"),
        centerTitle: true,
      ),
      backgroundColor: Color.fromRGBO(234, 224, 204, 1),
      body: Column(
        children: [
          Expanded(
            child: _isCameraLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller == null || !_controller!.value.isInitialized
                    ? const Center(child: Text("No Camera Available"))
                    : AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: CameraPreview(_controller!),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _translatedText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isStreaming ? null : _startStreaming,
                child: const Text("Start Translation"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _isStreaming ? _stopStreaming : null,
                child: const Text("Stop"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _switchCamera,
            child: const Text("Switch Camera"),
          ),
        ],
      ),
    );
  }
}
