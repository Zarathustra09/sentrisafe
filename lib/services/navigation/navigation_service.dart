// lib/services/navigation_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock/wakelock.dart';

class NavigationStep {
  final String instruction;
  final double distance;
  final LatLng location;
  final String maneuver;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.location,
    required this.maneuver,
  });
}

class NavigationService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  Timer? _locationTimer;

  bool _isNavigating = false;
  int _currentStepIndex = 0;
  List<NavigationStep> _steps = [];
  List<LatLng> _routePoints = [];
  LatLng? _currentLocation;
  double _distanceToNextStep = 0;
  String _currentInstruction = '';

  bool get isNavigating => _isNavigating;
  int get currentStepIndex => _currentStepIndex;
  List<NavigationStep> get steps => _steps;
  List<LatLng> get routePoints => _routePoints;
  LatLng? get currentLocation => _currentLocation;
  double get distanceToNextStep => _distanceToNextStep;
  String get currentInstruction => _currentInstruction;

  Future<void> startNavigation(List<LatLng> route, List<NavigationStep> steps) async {
    _isNavigating = true;
    _currentStepIndex = 0;
    _steps = steps;
    _routePoints = route;

    await Wakelock.enable();
    await _initializeTts();
    _startLocationTracking();

    if (_steps.isNotEmpty) {
      _currentInstruction = _steps[0].instruction;
      await _speak(_currentInstruction);
    }

    notifyListeners();
  }

  Future<void> stopNavigation() async {
    _isNavigating = false;
    _locationTimer?.cancel();
    await Wakelock.disable();
    await _tts.stop();
    notifyListeners();
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.9);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition();
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateNavigationProgress();
        notifyListeners();
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  void _updateNavigationProgress() {
    if (_currentLocation == null || _currentStepIndex >= _steps.length) return;

    NavigationStep currentStep = _steps[_currentStepIndex];
    double distanceToStep = _calculateDistance(
      _currentLocation!,
      currentStep.location,
    );

    _distanceToNextStep = distanceToStep;

    // Check if we've reached the current step (within 20 meters)
    if (distanceToStep < 20) {
      _currentStepIndex++;
      if (_currentStepIndex < _steps.length) {
        _currentInstruction = _steps[_currentStepIndex].instruction;
        _speak(_currentInstruction);
      } else {
        _currentInstruction = "You have arrived at your destination";
        _speak(_currentInstruction);
        stopNavigation();
      }
    }
    // Give advance warning for next instruction (100 meters)
    else if (distanceToStep < 100 && distanceToStep > 80) {
      _speak("In ${distanceToStep.round()} meters, ${currentStep.instruction}");
    }
  }

  double _calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    Wakelock.disable();
    _tts.stop();
    super.dispose();
  }
}