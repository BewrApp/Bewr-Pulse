import 'package:noise_meter/noise_meter.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool _isRecording = false;
  NoiseReading? _latestReading;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  NoiseMeter? _noiseMeter;
  double? _lastDecibelLevel;
  double _dbDiffThreshold = 0.25;
  double? _dbDiff;
  double _minDecibelLevel = 60.0; // Valeur initiale du seuil de volume minimum
  double _previousMinDecibelLevel = 10.0;
  int _vibrationCount = 0; // Compte le nombre de vibrations
  DateTime _lastVibrationTime =
      DateTime.now(); // Dernière fois que le système a vibré
  bool _autoSensitivity = true;
// Valeur maximale pour le seuil de différence de décibels
  final List<double> _recentDbLevels =
      []; // Pour stocker les niveaux de décibels récents
  bool _autoVolume = true;
  double _vibrationIntensity = 0.5; // Intensité initiale des vibrations
  final int _vibrationDuration =
      20; // Durée initiale des vibrations en millisecondes
  bool _vibrationPeak = true; // Ajustement automatique des vibrations

  @override
  void initState() {
    super.initState();
    _noiseMeter = NoiseMeter(onError);
  }

  @override
  void dispose() {
    _noiseSubscription?.cancel();
    super.dispose();
  }

  void onData(NoiseReading noiseReading) {
    setState(() {
      if (_lastDecibelLevel != null && _lastDecibelLevel! > 60) {
        _dbDiff = (_lastDecibelLevel! - noiseReading.meanDecibel).abs();
        if (_dbDiff! > _dbDiffThreshold &&
            noiseReading.meanDecibel > _minDecibelLevel) {
          if (_vibrationPeak) {
            if (_dbDiff! > 10.0) {
              Vibration.vibrate(
                duration: _vibrationDuration,
                amplitude: (255).toInt(),
              );
            } else {
              Vibration.vibrate(
                duration: _vibrationDuration,
                amplitude: (255 * _vibrationIntensity).toInt(),
              );
            }
          } else {
            Vibration.vibrate(
              duration: _vibrationDuration,
              amplitude: (255 * _vibrationIntensity).toInt(),
            );
          }
          _vibrationCount++;
          if (_autoSensitivity) {
            _adjustSensitivity();
          }
        }
        _recentDbLevels.add(noiseReading.meanDecibel);
        if (_recentDbLevels.length > 100) {
          _recentDbLevels.removeAt(0);
          if (_autoVolume) {
            double averageDbLevel = _recentDbLevels.reduce((a, b) => a + b) /
                _recentDbLevels.length;

            if (averageDbLevel < _previousMinDecibelLevel) {
              double diff = _previousMinDecibelLevel - averageDbLevel;
              double maxDecrease =
                  diff * 0.1; // Déterminez la diminution maximale autorisée
              double decreaseAmount = min(
                  maxDecrease, 10.0); // Déterminez la quantité de diminution
              _minDecibelLevel = _previousMinDecibelLevel - decreaseAmount;
            } else {
              _minDecibelLevel = averageDbLevel - 10.0;
            }
            _previousMinDecibelLevel = _minDecibelLevel;
          }
        }
      } else {
        _minDecibelLevel = noiseReading
            .meanDecibel; // Utiliser la première valeur enregistrée comme volume minimum
      }
      _lastDecibelLevel = noiseReading.meanDecibel;
      _latestReading = noiseReading;
      if (!_isRecording) _isRecording = true;
    });
  }

  void _adjustSensitivity() {
    final currentTime = DateTime.now();
    final diffInSeconds = currentTime.difference(_lastVibrationTime).inSeconds;

    if (diffInSeconds >= 5) {
      if (_vibrationCount > 20 && _dbDiffThreshold < 2.0) {
        _dbDiffThreshold = min(_dbDiffThreshold + 0.05,
            2.0); // Augmenter la sensibilité de 5% jusqu'à 2 dB
      } else if (_vibrationCount < 5 && _dbDiffThreshold > 0.0) {
        _dbDiffThreshold = max(_dbDiffThreshold - 0.05,
            0.0); // Diminuer la sensibilité de 5% jusqu'à 0 dB
      }
      _vibrationCount = 0;
      _lastVibrationTime = currentTime;
    }
  }

  void onError(Object error) {
    debugPrint(error as String?);
    _isRecording = false;
  }

  Future<void> start() async {
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return;
      }
      _noiseSubscription = _noiseMeter?.noise.listen(onData);
    } catch (err) {
      debugPrint(err as String?);
    }
  }

  void stop() {
    try {
      _noiseSubscription!.cancel();
      setState(() {
        _isRecording = false;
      });
    } catch (err) {
      debugPrint(err as String?);
    }
  }

  List<Widget> getContent() => <Widget>[
        Container(
            margin: const EdgeInsets.all(25),
            child: Column(children: [
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Text(_isRecording ? "Mic: ON" : "Mic: OFF",
                    style: const TextStyle(fontSize: 25, color: Colors.blue)),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Text(
                  'Noise: ${_latestReading?.meanDecibel} dB',
                ),
              ),
              Text(
                'Max: ${_latestReading?.maxDecibel} dB',
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Text(
                  'DB Diff: ${_dbDiff?.toStringAsFixed(2)} dB',
                ),
              ),
              SwitchListTile(
                title: const Text('Auto Sensitivity'),
                value: _autoSensitivity,
                onChanged: (bool value) {
                  setState(() {
                    _autoSensitivity = value;
                  });
                },
              ),
              Text('Sensitivity: ${_dbDiffThreshold.toStringAsFixed(2)} dB'),
              Slider(
                value: _dbDiffThreshold,
                min: 0,
                max: 2,
                divisions:
                    40, // Change this to increase the precision of the slider
                label: _dbDiffThreshold.toStringAsFixed(2),
                onChanged: (double value) {
                  setState(() {
                    _dbDiffThreshold = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Auto Volume'),
                value: _autoVolume,
                onChanged: (bool value) {
                  setState(() {
                    _autoVolume = value;
                  });
                },
              ),
              Text('Minimum Volume: ${_minDecibelLevel.toStringAsFixed(1)} dB'),
              Slider(
                value: _minDecibelLevel,
                min: 40,
                max: 120,
                divisions: 80,
                label: _minDecibelLevel.toStringAsFixed(1),
                onChanged: (double value) {
                  setState(() {
                    _minDecibelLevel = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Vibration Peak'),
                value: _vibrationPeak,
                onChanged: (bool value) {
                  setState(() {
                    _vibrationPeak = value;
                  });
                },
              ),
              Text(
                  'Vibration Intensity: ${(_vibrationIntensity * 100).toStringAsFixed(0)}%'),
              Slider(
                value: _vibrationIntensity * 100,
                min: 10,
                max: 100,
                divisions: 9,
                label: '${(_vibrationIntensity * 100).toStringAsFixed(0)}%',
                onChanged: (double value) {
                  setState(() {
                    _vibrationIntensity = value / 100;
                  });
                },
              ),
            ])),
      ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bewr Pulse',
      home: Scaffold(
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: getContent())),
        floatingActionButton: FloatingActionButton(
            backgroundColor: _isRecording ? Colors.red : Colors.cyan,
            onPressed: _isRecording ? stop : start,
            child:
                _isRecording ? const Icon(Icons.stop) : const Icon(Icons.mic)),
      ),
    );
  }
}
