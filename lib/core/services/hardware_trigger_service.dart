import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// Hardware Trigger Service: Listens to Volume Button presses
/// Triple Volume Up press triggers Emergency SOS
/// Web-compatible stub - full functionality available on mobile
class HardwareTriggerService {
  static final HardwareTriggerService instance =
      HardwareTriggerService._internal();
  factory HardwareTriggerService() => instance;
  HardwareTriggerService._internal();

  Timer? _resetTimer;
  int _volumeUpPressCount = 0;

  static const int TRIGGER_COUNT = 3;
  static const Duration RESET_DURATION = Duration(seconds: 2);

  // Callback to trigger SOS
  Function()? onEmergencyTriggered;

  StreamSubscription<double>? _volumeSubscription;
  double? _lastVolume;

  Future<void> initialize() async {
    try {
      developer.log('HardwareTriggerService initializing...');
      
      // Initialize Volume Controller
      await FlutterVolumeController.updateShowSystemUI(false);
      
      // Listen to volume changes
      _volumeSubscription = FlutterVolumeController.addListener((volume) {
        _handleVolumeChange(volume);
      });
      
      // Get initial volume
      _lastVolume = await FlutterVolumeController.getVolume();
      
      developer.log('HardwareTriggerService initialized and listening');
    } catch (e) {
      developer.log('Error initializing hardware trigger: $e');
    }
  }

  void _handleVolumeChange(double newVolume) {
    // Detect change (press)
    if (_lastVolume != null && newVolume != _lastVolume) {
        simulateVolumePress();
    }
    _lastVolume = newVolume;
  }

  void simulateVolumePress() {
    _volumeUpPressCount++;
    developer.log('Volume button pressed (detected): $_volumeUpPressCount/$TRIGGER_COUNT');

    // Cancel previous reset timer
    _resetTimer?.cancel();

    if (_volumeUpPressCount >= TRIGGER_COUNT) {
      developer.log('🚨 EMERGENCY TRIGGERED via Volume Button!');
      _triggerEmergency();
      _volumeUpPressCount = 0;
    } else {
      // Reset counter after timeout
      _resetTimer = Timer(RESET_DURATION, () {
        developer.log('Volume button counter reset');
        _volumeUpPressCount = 0;
      });
    }
  }

  void _triggerEmergency() {
    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Trigger callback
    if (onEmergencyTriggered != null) {
      onEmergencyTriggered!();
    }
  }

  void dispose() {
    _resetTimer?.cancel();
    _volumeSubscription?.cancel();
    FlutterVolumeController.removeListener();
    FlutterVolumeController.updateShowSystemUI(true);
  }
}

/// Alternative Implementation using Method Channel (for production)
class VolumeButtonListener {
  static const MethodChannel _channel =
      MethodChannel('com.sahay.volume_listener');

  static Future<void> initialize(Function() onTriplePress) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'volumeTriplePress') {
        developer.log('🚨 Volume Triple Press Detected!');
        onTriplePress();
      }
    });
  }
}
/*
    override fun onCreate(savedInstanceState = Bundle?) {
        super.onCreate(savedInstanceState)
        
        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL)
            .setMethodCallHandler { call, result ->
                // Handle method calls if needed
            }
    }
    
    override fun onKeyDown(keyCode = Int, event = KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            volumeUpPressCount++
            resetHandler.removeCallbacksAndMessages(null)
            
            if (volumeUpPressCount >= 3) {
                // Trigger Flutter method
                MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL)
                    .invokeMethod("volumeTriplePress", null)
                volumeUpPressCount = 0
                return true
            }
            
            resetHandler.postDelayed({
                volumeUpPressCount = 0
            }, 2000)
            
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}

iOS NATIVE CODE (AppDelegate.swift):

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let CHANNEL = "com.sahay.volume_listener"
    private var volumeUpPressCount = 0
    private var resetTimer: Timer?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)
        
        // Listen to volume button via AVAudioSession
        setupVolumeListener(channel: channel)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func setupVolumeListener(channel = FlutterMethodChannel) {
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath = String?, of object = Any?, change = [NSKeyValueChangeKey : Any]?, context = UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            volumeUpPressCount += 1
            resetTimer?.invalidate()
            
            if volumeUpPressCount >= 3 {
                channel.invokeMethod("volumeTriplePress", arguments: nil)
                volumeUpPressCount = 0
                return
            }
            
            resetTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                self.volumeUpPressCount = 0
            }
        }
    }
}
*/
