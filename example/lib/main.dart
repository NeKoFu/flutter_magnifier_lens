import 'package:flutter/material.dart';
import 'package:flutter_magnifier_lens/flutter_magnifier_lens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magnifier Lens Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey _contentKey = GlobalKey();
  
  Offset _lensPosition = const Offset(200, 200);
  bool _activated = true;
  double _lensRadius = 100;
  double _baseLensRadius = 100;
  double _magnification = 1.5;
  double _aberration = 0.05;
  double _distortion = 0.5;
  bool _showBorder = true;
  bool _showShadow = true;
  final double _borderWidth = 3.0;



  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Magnifier Lens'),
      ),
      body: GestureDetector(
        onScaleStart: (details) {
          _baseLensRadius = _lensRadius;
        },
        onScaleUpdate: (details) {
          setState(() {
            _lensPosition += details.focalPointDelta;
            if (details.scale != 1.0) {
              _lensRadius = (_baseLensRadius * details.scale).clamp(50.0, 300.0);
              // Link magnification to lens size: A bigger lens zoom more
              // (e.g. 1.0 is no zoom, at 100 radius it is 1.5x, at 200 radius it is 2.0x, etc)
              _magnification = 1.0 + (_lensRadius / 200.0);
            }
          });
        },
        child: MagnifierLens(
          contentKey: _contentKey,
          activated: _activated,
          lensPosition: _lensPosition,
          lensRadius: _lensRadius,
          distortion: _distortion,
          magnification: _magnification,
          aberration: _aberration,
          showBorder: _showBorder,
          borderColor: Colors.indigo,
          borderWidth: _borderWidth,
          showShadow: _showShadow,
          child: RepaintBoundary(
            key: _contentKey,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Center(
                // A centered image as requested
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/flamingos.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
               decoration: BoxDecoration(color: Colors.blue),
               child: Text('Settings', style: TextStyle(color: Colors.white)),
            ),
            SwitchListTile(
              title: const Text('Activated'),
              value: _activated,
              onChanged: (val) => setState(() => _activated = val),
            ),
            SwitchListTile(
              title: const Text('Show Border'),
              value: _showBorder,
              onChanged: (val) => setState(() => _showBorder = val),
            ),
            SwitchListTile(
              title: const Text('Show Shadow'),
              value: _showShadow,
              onChanged: (val) => setState(() => _showShadow = val),
            ),
            ListTile(
              title: const Text('Lens Radius'),
              subtitle: Slider(
                min: 50, max: 300,
                value: _lensRadius,
                onChanged: (val) => setState(() => _lensRadius = val),
              ),
            ),
            ListTile(
              title: const Text('Magnification'),
              subtitle: Slider(
                min: 1.0, max: 3.0,
                value: _magnification,
                onChanged: (val) => setState(() => _magnification = val),
              ),
            ),
            ListTile(
              title: const Text('Distortion'),
              subtitle: Slider(
                min: 0.0, max: 2.0,
                value: _distortion,
                onChanged: (val) => setState(() => _distortion = val),
              ),
            ),
            ListTile(
              title: const Text('Aberration'),
              subtitle: Slider(
                min: 0.0, max: 0.2,
                value: _aberration,
                onChanged: (val) => setState(() => _aberration = val),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
