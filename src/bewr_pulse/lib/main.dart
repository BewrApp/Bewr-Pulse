import 'dart:async';
import 'dart:math';
import 'dart:core';

import 'package:flutter/material.dart';

import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

enum Command {
  start,
  stop,
  change,
}

const audioFormat = AudioFormat.ENCODING_PCM_16BIT;

void main() => runApp(const MicStreamExampleApp());

class MicStreamExampleApp extends StatefulWidget {
  const MicStreamExampleApp({super.key});

  @override
  MicStreamExampleAppState createState() => MicStreamExampleAppState();
}

class MicStreamExampleAppState extends State<MicStreamExampleApp>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Stream? stream;
  late StreamSubscription listener;
  List<int>? currentSamples = [];
  List<int> visibleSamples = [];
  int? localMax;
  int? localMin;
  double threshold = 0.0083;
  bool autoIntensity = true;
  bool useIntensityAmplitude = true;

  Random rng = Random();

  // Refreshes the Widget for every possible tick to force a rebuild of the sound wave
  late AnimationController controller;

  final Color _iconColor = Colors.white;
  bool isRecording = false;
  bool memRecordingState = false;
  late bool isActive;
  DateTime? startTime;

  int page = 0;
  List state = ["IntensityWavePage", "InformationPage"];

  @override
  void initState() {
    debugPrint("Init application");
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setState(() {
      initPlatformState();
    });
  }

  void _controlPage(int index) => setState(() => page = index);

  // Responsible for switching between recording / idle state
  void _controlMicStream({Command command = Command.change}) async {
    switch (command) {
      case Command.change:
        _changeListening();
        break;
      case Command.start:
        _startListening();
        break;
      case Command.stop:
        _stopListening();
        break;
    }
  }

  Future<bool> _changeListening() async =>
      !isRecording ? await _startListening() : _stopListening();

  late int bytesPerSample;
  late int samplesPerSecond;

  Future<bool> _startListening() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return false;
    }
    debugPrint("Start listening");
    if (isRecording) return false;
    // if this is the first time invoking the microphone()
    // method to get the stream, we don't yet have access
    // to the sampleRate and bitDepth properties
    debugPrint("Wait for stream");

    // Default option. Set to false to disable request permission dialogue
    MicStream.shouldRequestPermission(true);

    stream = await MicStream.microphone(
        audioSource: AudioSource.DEFAULT,
        sampleRate: 1000 * (rng.nextInt(50) + 30),
        channelConfig: ChannelConfig.CHANNEL_IN_STEREO,
        audioFormat: audioFormat);
    // after invoking the method for the first time, though, these will be available;
    // It is not necessary to setup a listener first, the stream only needs to be returned first
    debugPrint(
        "Start Listening to the microphone, sample rate is ${await MicStream.sampleRate}, bit depth is ${await MicStream.bitDepth}, bufferSize: ${await MicStream.bufferSize}");
    bytesPerSample = (await MicStream.bitDepth)! ~/ 8;
    samplesPerSecond = (await MicStream.sampleRate)!.toInt();
    localMax = null;
    localMin = null;

    setState(() {
      isRecording = true;
      startTime = DateTime.now();
    });
    visibleSamples = [];
    listener = stream!.listen(_calculateSamples);
    return true;
  }

  void _calculateSamples(samples) {
    _calculateIntensitySamples(samples);
  }

  Future<void> _calculateIntensitySamples(samples) async {
    currentSamples ??= [];
    int currentSample = 0;
    eachWithIndex(samples, (i, int sample) {
      currentSample += sample;
      if ((i % bytesPerSample) == bytesPerSample - 1) {
        currentSamples!.add(currentSample);
        currentSample = 0;
      }
    });

    // Calculer l'intensité des échantillons
    double intensity = calculateIntensity(currentSamples!);
    // debugPrint("Current Intensity ${intensity.toStringAsFixed(10)}");

    // debugPrint("Current threshold ${threshold.toStringAsFixed(10)}");

    // Ajuster l'amplitude en fonction de l'intensité
    double amplitude =
        useIntensityAmplitude ? pow(1 - intensity, 2) * 255 : 255;

    if (autoIntensity) {
      updateIntensity(intensity);
    } else if (intensity > threshold) {
      Vibration.vibrate(duration: 50, amplitude: amplitude.toInt());
    }

    if (currentSamples!.length >= samplesPerSecond / 10) {
      visibleSamples
          .add(currentSamples!.map((i) => i).toList().reduce((a, b) => a + b));
      localMax ??= visibleSamples.last;
      localMin ??= visibleSamples.last;
      localMax = max(localMax!, visibleSamples.last);
      localMin = min(localMin!, visibleSamples.last);
      currentSamples = [];
      setState(() {});
    }
  }

  double calculateIntensity(List<int> samples) {
    // Calculer l'intensité en fonction des échantillons
    double sum = 0;
    for (int sample in samples) {
      sum += sample.abs();
    }
    double average = sum / samples.length;
    double intensity = average / 520; // Normaliser l'intensité entre 0 et 1
    return intensity;
  }

  double? currentMin;
  double? currentMax;

  void updateIntensity(double intensity) {
    int updateCounter = 0;

    if (threshold > 0.6) threshold = 0.6;
    if (threshold < 0.4) threshold = 0.4;

    // Mettre à jour currentMin et currentMax
    if (currentMin == null || intensity < currentMin!) {
      currentMin = intensity;
    }

    if (currentMax == null || intensity > currentMax!) {
      currentMax = intensity;
    }

    if (currentMin != null && currentMax != null) {
      threshold = currentMin! + (currentMax! - currentMin!) * 0.807;

      if (intensity > threshold) {
        double amplitude =
            useIntensityAmplitude ? pow(1 - intensity, 2) * 255 : 255;
        if (amplitude > 255) amplitude = 255;
        Vibration.vibrate(duration: 50, amplitude: amplitude.toInt());
      }
    }

    updateCounter++; // Incrémenter le compteur

    // Si le compteur dépasse, disons, 1000 mises à jour, réinitialiser currentMin et currentMax
    if (updateCounter >= 500) {
      currentMin = null;
      currentMax = null;
      updateCounter = 0; // Réinitialiser le compteur
    }
  }

  bool _stopListening() {
    if (!isRecording) return false;
    debugPrint("Stop Listening to the microphone");
    listener.cancel();

    setState(() {
      isRecording = false;
      currentSamples = null;
      startTime = null;
    });
    return true;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (!mounted) return;
    isActive = true;

    const Statistics(
      false,
    );

    controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this)
          ..addListener(() {
            if (isRecording) setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              controller.reverse();
            } else if (status == AnimationStatus.dismissed) {
              controller.forward();
            }
          })
          ..forward();
  }

  Color _getBgColor() => (isRecording) ? Colors.red : Colors.cyan;
  Icon _getIcon() =>
      (isRecording) ? const Icon(Icons.stop) : const Icon(Icons.keyboard_voice);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData.dark().copyWith(
      colorScheme: ThemeData.dark().colorScheme.copyWith(
            primary: _getBgColor(),
            secondary: Colors.white,
          ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image(
                image: (isRecording)
                    ? const AssetImage('assets/images/icon_red.png')
                    : const AssetImage('assets/images/icon.png'),
              ),
            ),
            centerTitle: true,
            title: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 20,
                ),
                children: [
                  const TextSpan(
                    text: 'Bewr ',
                  ),
                  TextSpan(
                    text: 'Pulse',
                    style: TextStyle(
                      color: _getBgColor(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _controlMicStream,
            foregroundColor: _iconColor,
            backgroundColor: _getBgColor(),
            tooltip: (isRecording) ? "Stop recording" : "Start recording",
            child: _getIcon(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.monitor_heart),
                label: "Pulse",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.data_saver_off),
                label: "Statistics",
              )
            ],
            backgroundColor: Colors.black26,
            elevation: 20,
            currentIndex: page,
            onTap: _controlPage,
          ),
          body: (page == 0)
              ? Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Auto sensitivity'),
                      value: autoIntensity,
                      onChanged: (value) {
                        setState(() {
                          autoIntensity = value;
                        });
                      },
                      activeColor: _getBgColor(),
                    ),
                    SwitchListTile(
                      title: const Text('Use Intensity Amplitude'),
                      value: useIntensityAmplitude,
                      onChanged: (value) {
                        setState(() {
                          useIntensityAmplitude = value;
                        });
                      },
                      activeColor: _getBgColor(),
                    ),
                    Row(
                      children: [
                        Opacity(
                          opacity: autoIntensity
                              ? 0.6
                              : 1.0, // 0.4 opacité lorsque autoIntensity est activé, sinon 1.0
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Sensitivity'),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: (1 - ((threshold - 0.4) / 0.2)).clamp(0.0,
                                1.0), // Clamp the value between 0.0 and 1.0
                            min: 0.0,
                            max: 1.0,
                            divisions: 100,
                            onChanged: autoIntensity
                                ? null
                                : (value) {
                                    setState(() {
                                      threshold = 0.4 + (1 - value) * 0.2;
                                    });
                                  },
                            label:
                                '${(100 - (threshold - 0.4) / 0.2 * 100).round()} %',
                            activeColor: autoIntensity ? Colors.grey : null,
                            inactiveColor: autoIntensity ? Colors.grey : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: CustomPaint(
                          painter: WavePainter(
                            samples: visibleSamples,
                            color: _getBgColor(),
                            localMax: localMax,
                            localMin: localMin,
                            context: context,
                          ),
                        )),
                  ],
                )
              : Statistics(
                  isRecording,
                  startTime: startTime,
                  threshold:
                      '${(100 - (threshold - 0.4) / 0.2 * 100).round()} %',
                )),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      isActive = true;
      debugPrint("Resume app");

      _controlMicStream(
          command: memRecordingState ? Command.start : Command.stop);
    } else if (isActive) {
      memRecordingState = isRecording;
      _controlMicStream(command: Command.stop);

      debugPrint("Pause app");
      isActive = false;
    }
  }

  @override
  void dispose() {
    listener.cancel();
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class WavePainter extends CustomPainter {
  int? localMax;
  int? localMin;
  List<int>? samples;
  late List<Offset> points;
  Color? color;
  BuildContext? context;
  Size? size;

  // Set max val possible in stream, depending on the config
  // int absMax = 255*4; //(audioFormat == AudioFormat.ENCODING_PCM_8BIT) ? 127 : 32767;
  // int absMin; //(audioFormat == AudioFormat.ENCODING_PCM_8BIT) ? 127 : 32767;

  WavePainter(
      {this.samples, this.color, this.context, this.localMax, this.localMin});

  @override
  void paint(Canvas canvas, Size? size) {
    this.size = context!.size;
    size = this.size;

    Paint paint = Paint()
      ..color = color!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    if (samples!.isEmpty) return;

    points = toPoints(samples);

    Path path = Path();
    path.addPolygon(points, false);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  // Maps a list of ints and their indices to a list of points on a cartesian grid
  List<Offset> toPoints(List<int>? samples) {
    List<Offset> points = [];
    samples ??= List<int>.filled(size!.width.toInt(), (0.5).toInt());
    double pixelsPerSample = size!.width / samples.length;
    for (int i = 0; i < samples.length; i++) {
      var point = Offset(
          i * pixelsPerSample,
          0.5 *
              size!.height *
              pow((samples[i] - localMin!) / (localMax! - localMin!), 5));
      points.add(point);
    }
    return points;
  }

  double project(int val, int max, double height) {
    double waveHeight =
        (max == 0) ? val.toDouble() : (val / max) * 0.5 * height;
    return waveHeight + 0.5 * height;
  }
}

class Statistics extends StatelessWidget {
  final bool isRecording;
  final DateTime? startTime;
  final String? threshold;

  const Statistics(this.isRecording,
      {super.key, this.startTime, this.threshold});

  @override
  Widget build(BuildContext context) {
    return ListView(children: <Widget>[
      ListTile(
        leading: const Icon(Icons.keyboard_voice),
        title: Text((isRecording ? "Recording" : "Not recording")),
      ),
      ListTile(
          leading: const Icon(Icons.access_time),
          title: Text((isRecording
              ? DateTime.now().difference(startTime!).toString()
              : "Not recording"))),
      ListTile(
        leading: const Icon(Icons.sensors_rounded),
        title: Text((isRecording ? "Threshold: $threshold" : "Not recording")),
      ),
    ]);
  }
}

Iterable<T> eachWithIndex<E, T>(
    Iterable<T> items, E Function(int index, T item) f) {
  var index = 0;

  for (final item in items) {
    f(index, item);
    index = index + 1;
  }

  return items;
}
