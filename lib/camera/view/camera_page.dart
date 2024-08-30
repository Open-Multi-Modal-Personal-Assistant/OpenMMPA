import 'dart:developer';
import 'dart:io';
import 'dart:math' as m;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:inspector_gadget/camera/view/capture_state.dart';
import 'package:inspector_gadget/interaction/view/interaction_page.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/outlined_icon.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:video_player/video_player.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => CameraPageState();
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }

  // This enum is from a different package, so a new value could be added at
  // any time. The example should keep working if that happens.
  // ignore: dead_code
  return Icons.camera;
}

void _logError(String code, String? message) {
  log('Error: $code${message == null ? '' : '\nError Message: $message'}');
}

class CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool detailedCameraControl = PreferencesService.detailedCameraControlsDefault;
  AppLocalizations? l10n;
  double iconSize = 5;
  List<CameraDescription> _cameras = <CameraDescription>[];
  CameraController? cameraController;
  XFile? imageFile;
  XFile? videoFile;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  bool enableAudio = false;
  double _minAvailableExposureOffset = 0;
  double _maxAvailableExposureOffset = 0;
  double _currentExposureOffset = 0;
  late AnimationController _flashModeControlRowAnimationController;
  late Animation<double> _flashModeControlRowAnimation;
  late AnimationController _exposureModeControlRowAnimationController;
  late Animation<double> _exposureModeControlRowAnimation;
  late AnimationController _focusModeControlRowAnimationController;
  late Animation<double> _focusModeControlRowAnimation;
  double _minAvailableZoom = 1;
  double _maxAvailableZoom = 1;
  double _currentScale = 1;
  double _baseScale = 1;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  @override
  void initState() {
    super.initState();

    detailedCameraControl =
        GetIt.I.get<PreferencesService>().detailedCameraControls;
    GetIt.I.get<CaptureState>().setState(CaptureState.previewStateLabel);

    WidgetsBinding.instance.addObserver(this);

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureModeControlRowAnimation = CurvedAnimation(
      parent: _exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _focusModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusModeControlRowAnimation = CurvedAnimation(
      parent: _focusModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        _cameras = await availableCameras();
        if (_cameras.isNotEmpty) {
          await onNewCameraSelected(_cameras[0]);
        }
      } on CameraException catch (e) {
        _logError(e.code, e.description);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    _exposureModeControlRowAnimationController.dispose();
    _focusModeControlRowAnimationController.dispose();
    super.dispose();
  }

  // #docregion AppLifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController!.description);
    }
  }
  // #enddocregion AppLifecycle

  @override
  Widget build(BuildContext context) {
    l10n = context.l10n;
    final size = MediaQuery.of(context).size;
    const appBarHeight = 56;
    // https://www.geeksforgeeks.org/flutter-set-the-height-of-the-appbar/
    iconSize = m.min(size.width, size.height - appBarHeight) / 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n!.captureAppBarTitle),
      ),
      body: Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: cameraController != null &&
                          cameraController!.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _floatingActionConstruct(context),
    );
  }

  Widget _floatingActionConstruct(BuildContext context) {
    return Column(
      children: [
        _captureControlRowWidget(),
        _modeControlRowWidget(context),
        Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              _captureAndOpenWidget(context),
              _thumbnailWidget(),
            ],
          ),
        ),
      ],
    );
  }

  /// Display the preview from the camera
  /// (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Text(
        l10n!.cameraSelectionInstruction,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          cameraController!,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onTapDown: (TapDownDetails details) =>
                    onViewFinderTap(details, constraints),
                // onTap: onTakePictureButtonPressed,
              );
            },
          ),
        ),
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (cameraController == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await cameraController!.setZoomLevel(_currentScale);
  }

  /// Display the thumbnail of the captured image or video.
  Widget _thumbnailWidget() {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (videoController == null && imageFile == null)
              Container()
            else
              SizedBox(
                width: 64,
                height: 64,
                child: (videoController == null)
                    ? (Image.file(File(imageFile!.path)))
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.pink),
                        ),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: videoController!.value.aspectRatio,
                            child: VideoPlayer(videoController!),
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  /// Display a bar with buttons to change the flash and exposure modes
  Widget _modeControlRowWidget(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: outlinedIcon(
                context,
                Icons.flash_on,
                iconSize,
                color: Colors.blue,
              ),
              color: Colors.transparent,
              onPressed:
                  cameraController != null ? onFlashModeButtonPressed : null,
            ),
            ...[
              IconButton(
                icon: outlinedIcon(
                  context,
                  Icons.exposure,
                  iconSize,
                  color: Colors.blue,
                ),
                color: Colors.transparent,
                onPressed: cameraController != null
                    ? onExposureModeButtonPressed
                    : null,
              ),
              IconButton(
                icon: outlinedIcon(
                  context,
                  Icons.filter_center_focus,
                  iconSize,
                  color: Colors.blue,
                ),
                color: Colors.transparent,
                onPressed:
                    cameraController != null ? onFocusModeButtonPressed : null,
              ),
            ],
            IconButton(
              icon: outlinedIcon(
                context,
                enableAudio ? Icons.volume_up : Icons.volume_mute,
                iconSize,
                color: Colors.blue,
              ),
              color: Colors.transparent,
              onPressed:
                  cameraController != null ? onAudioModeButtonPressed : null,
            ),
            IconButton(
              icon: outlinedIcon(
                context,
                cameraController?.value.isCaptureOrientationLocked ?? false
                    ? Icons.screen_lock_rotation
                    : Icons.screen_rotation,
                iconSize,
                color: Colors.blue,
              ),
              color: Colors.transparent,
              onPressed: cameraController != null
                  ? onCaptureOrientationLockButtonPressed
                  : null,
            ),
          ],
        ),
        _flashModeControlRowWidget(),
        _exposureModeControlRowWidget(),
        _focusModeControlRowWidget(),
      ],
    );
  }

  Widget _flashModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: outlinedIcon(
                context,
                Icons.flash_off,
                iconSize,
                color: cameraController?.value.flashMode == FlashMode.off
                    ? Colors.orange
                    : Colors.blue,
              ),
              color: Colors.blue,
              onPressed: cameraController != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.off)
                  : null,
            ),
            IconButton(
              icon: outlinedIcon(
                context,
                Icons.flash_auto,
                iconSize,
                color: cameraController?.value.flashMode == FlashMode.auto
                    ? Colors.orange
                    : Colors.blue,
              ),
              color: Colors.transparent,
              onPressed: cameraController != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.auto)
                  : null,
            ),
            IconButton(
              icon: outlinedIcon(
                context,
                Icons.flash_on,
                iconSize,
                color: cameraController?.value.flashMode == FlashMode.always
                    ? Colors.orange
                    : Colors.blue,
              ),
              color: Colors.transparent,
              onPressed: cameraController != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.always)
                  : null,
            ),
            IconButton(
              icon: outlinedIcon(
                context,
                Icons.highlight,
                iconSize,
                color: cameraController?.value.flashMode == FlashMode.torch
                    ? Colors.orange
                    : Colors.blue,
              ),
              color: Colors.transparent,
              onPressed: cameraController != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.torch)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _exposureModeControlRowWidget() {
    final styleAuto = TextButton.styleFrom(
      foregroundColor: cameraController?.value.exposureMode == ExposureMode.auto
          ? Colors.orange
          : Colors.blue,
    );
    final styleLocked = TextButton.styleFrom(
      foregroundColor:
          cameraController?.value.exposureMode == ExposureMode.locked
              ? Colors.orange
              : Colors.blue,
    );

    return SizeTransition(
      sizeFactor: _exposureModeControlRowAnimation,
      child: ClipRect(
        child: ColoredBox(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              const Center(
                child: Text('Exposure Mode'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: styleAuto,
                    onPressed: cameraController != null
                        ? () =>
                            onSetExposureModeButtonPressed(ExposureMode.auto)
                        : null,
                    onLongPress: () {
                      if (cameraController != null) {
                        cameraController!.setExposurePoint(null);
                        log('Resetting exposure point');
                      }
                    },
                    child: const Text('AUTO'),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: cameraController != null
                        ? () =>
                            onSetExposureModeButtonPressed(ExposureMode.locked)
                        : null,
                    child: const Text('LOCKED'),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: cameraController != null
                        ? () => cameraController!.setExposureOffset(0)
                        : null,
                    child: const Text('RESET OFFSET'),
                  ),
                ],
              ),
              const Center(
                child: Text('Exposure Offset'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(_minAvailableExposureOffset.toString()),
                  Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    label: _currentExposureOffset.toString(),
                    onChanged: _minAvailableExposureOffset ==
                            _maxAvailableExposureOffset
                        ? null
                        : setExposureOffset,
                  ),
                  Text(_maxAvailableExposureOffset.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _focusModeControlRowWidget() {
    final styleAuto = TextButton.styleFrom(
      foregroundColor: cameraController?.value.focusMode == FocusMode.auto
          ? Colors.orange
          : Colors.blue,
    );
    final styleLocked = TextButton.styleFrom(
      foregroundColor: cameraController?.value.focusMode == FocusMode.locked
          ? Colors.orange
          : Colors.blue,
    );

    return SizeTransition(
      sizeFactor: _focusModeControlRowAnimation,
      child: ClipRect(
        child: ColoredBox(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              const Center(
                child: Text('Focus Mode'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: styleAuto,
                    onPressed: cameraController != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.auto)
                        : null,
                    onLongPress: () {
                      if (cameraController != null) {
                        cameraController!.setFocusPoint(null);
                      }
                      log('Resetting focus point');
                    },
                    child: const Text('AUTO'),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: cameraController != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.locked)
                        : null,
                    child: const Text('LOCKED'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: outlinedIcon(
            context,
            Icons.camera_alt,
            iconSize,
            color: Colors.blue,
          ),
          color: Colors.transparent,
          onPressed: cameraController != null &&
                  cameraController!.value.isInitialized &&
                  !cameraController!.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
        IconButton(
          icon: outlinedIcon(
            context,
            Icons.videocam,
            iconSize,
            color: Colors.blue,
          ),
          color: Colors.transparent,
          onPressed: cameraController != null &&
                  cameraController!.value.isInitialized &&
                  !cameraController!.value.isRecordingVideo
              ? onVideoRecordButtonPressed
              : null,
        ),
        IconButton(
          icon: outlinedIcon(
            context,
            cameraController != null &&
                    cameraController!.value.isRecordingPaused
                ? Icons.play_arrow
                : Icons.pause,
            iconSize,
            color: Colors.blue,
          ),
          color: Colors.transparent,
          onPressed: cameraController != null &&
                  cameraController!.value.isInitialized &&
                  cameraController!.value.isRecordingVideo
              ? (cameraController!.value.isRecordingPaused)
                  ? onResumeButtonPressed
                  : onPauseButtonPressed
              : null,
        ),
        IconButton(
          icon: outlinedIcon(context, Icons.stop, iconSize, color: Colors.red),
          color: Colors.transparent,
          onPressed: cameraController != null &&
                  cameraController!.value.isInitialized &&
                  cameraController!.value.isRecordingVideo
              ? onStopButtonPressed
              : null,
        ),
        IconButton(
          icon: outlinedIcon(
            context,
            Icons.pause_presentation,
            iconSize,
            color: cameraController != null &&
                    cameraController!.value.isPreviewPaused
                ? Colors.red
                : Colors.blue,
          ),
          color: Colors.transparent,
          onPressed:
              cameraController == null ? null : onPausePreviewButtonPressed,
        ),
      ],
    );
  }

  /// Display a row of toggle to select the camera
  /// (or a message if no camera is available).
  Widget _cameraTogglesRowWidget(BuildContext context) {
    final toggles = <Widget>[];

    if (_cameras.isEmpty) {
      log('Error: No camera found.');
      return const Text('No camera');
    } else {
      for (final cameraDescription in _cameras) {
        toggles.add(
          IconButton.filledTonal(
            onPressed: () async => onNewCameraSelected(cameraDescription),
            icon: outlinedIcon(
              context,
              getCameraLensIcon(cameraDescription.lensDirection),
              iconSize,
            ),
          ),
        );
      }
    }

    return Row(children: toggles);
  }

  Widget _captureAndOpenWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _cameraTogglesRowWidget(context),
        IconButton.filledTonal(
          onPressed: () async => onAttachImageSelected(),
          icon: outlinedIcon(context, Icons.folder_open, iconSize),
        ),
      ],
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    log(message);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (cameraController == null) {
      return;
    }

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController!
      ..setExposurePoint(offset)
      ..setFocusPoint(offset);
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      return cameraController!.setDescription(cameraDescription);
    } else {
      return _initializeCameraController(cameraDescription);
    }
  }

  Future<void> onAttachImageSelected() async {}

  Future<void> _initializeCameraController(
    CameraDescription cameraDescription,
  ) async {
    final cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (cameraController.value.hasError) {
        log('Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait(<Future<Object?>>[
        ...<Future<Object?>>[
          cameraController
              .getMinExposureOffset()
              .then((double value) => _minAvailableExposureOffset = value),
          cameraController
              .getMaxExposureOffset()
              .then((double value) => _maxAvailableExposureOffset = value),
        ],
        cameraController
            .getMaxZoomLevel()
            .then((double value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((double value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          showInSnackBar('You have denied camera access.');
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable camera access.');
        case 'CameraAccessRestricted':
          // iOS only
          showInSnackBar('Camera access is restricted.');
        case 'AudioAccessDenied':
          showInSnackBar('You have denied audio access.');
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable audio access.');
        case 'AudioAccessRestricted':
          // iOS only
          showInSnackBar('Audio access is restricted.');
        default:
          _logError(e.code, e.description);
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((XFile? file) {
      if (mounted) {
        log('Picture saved to ${file?.path}');
        setState(() {
          imageFile = file;
          videoController?.dispose();
          videoController = null;
        });

        if (file != null && file.path.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (context) => InteractionPage(
                  InteractionMode.multiModalMode,
                  mediaPath: file.path,
                ),
              ),
            );
          });
        }
      }
    });
  }

  void onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
      _exposureModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onExposureModeButtonPressed() {
    if (_exposureModeControlRowAnimationController.value == 1) {
      _exposureModeControlRowAnimationController.reverse();
    } else {
      _exposureModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onFocusModeButtonPressed() {
    if (_focusModeControlRowAnimationController.value == 1) {
      _focusModeControlRowAnimationController.reverse();
    } else {
      _focusModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _exposureModeControlRowAnimationController.reverse();
    }
  }

  void onAudioModeButtonPressed() {
    enableAudio = !enableAudio;
    if (cameraController != null) {
      onNewCameraSelected(cameraController!.description);
    }
  }

  Future<void> onCaptureOrientationLockButtonPressed() async {
    try {
      if (cameraController != null) {
        if (cameraController!.value.isCaptureOrientationLocked) {
          await cameraController?.unlockCaptureOrientation();
          log('Capture orientation unlocked');
        } else {
          await cameraController?.lockCaptureOrientation();
          final lockedTo = cameraController?.value.lockedCaptureOrientation
              .toString()
              .split('.')
              .last;
          log('Capture orientation locked to $lockedTo');
        }
      }
    } on CameraException catch (e) {
      log('onCaptureOrientationLockButtonPressed error', error: e);
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }

      log('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetExposureModeButtonPressed(ExposureMode mode) {
    setExposureMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }

      log('Exposure mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetFocusModeButtonPressed(FocusMode mode) {
    setFocusMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }

      log('Focus mode set to ${mode.toString().split('.').last}');
    });
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((XFile? file) {
      if (mounted) {
        setState(() {
          imageFile = null;
        });
      }

      if (file != null && file.path.isNotEmpty) {
        log('Video recorded to ${file.path}');
        videoFile = file;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (context) => InteractionPage(
                InteractionMode.multiModalMode,
                mediaPath: file.path,
              ),
            ),
          );
        });

        // _startVideoPlayer();
      }
    });
  }

  Future<void> onPausePreviewButtonPressed() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return;
    }

    if (cameraController!.value.isPreviewPaused) {
      await cameraController?.resumePreview();
    } else {
      await cameraController?.pausePreview();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) {
        setState(() {});
      }

      log('Video recording paused');
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) {
        setState(() {});
      }

      log('Video recording resumed');
    });
  }

  Future<void> startVideoRecording() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return;
    }

    if (cameraController!.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return;
    }

    try {
      await cameraController?.startVideoRecording();
    } on CameraException catch (e) {
      log('startVideoRecording error', error: e);
      return;
    }
  }

  Future<XFile?> stopVideoRecording() async {
    if (cameraController == null || !cameraController!.value.isRecordingVideo) {
      return null;
    }

    try {
      return cameraController?.stopVideoRecording();
    } on CameraException catch (e) {
      log('stopVideoRecording error', error: e);
      return null;
    }
  }

  Future<void> pauseVideoRecording() async {
    if (cameraController == null || !cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      await cameraController?.pauseVideoRecording();
    } on CameraException catch (e) {
      log('pauseVideoRecording error', error: e);
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    if (cameraController == null || !cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      await cameraController?.resumeVideoRecording();
    } on CameraException catch (e) {
      log('resumeVideoRecording error', error: e);
      rethrow;
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (cameraController == null) {
      return;
    }

    try {
      await cameraController!.setFlashMode(mode);
    } on CameraException catch (e) {
      log('setFlashMode error', error: e);
      rethrow;
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    if (cameraController == null) {
      return;
    }

    try {
      await cameraController?.setExposureMode(mode);
    } on CameraException catch (e) {
      log('setExposureMode error', error: e);
      rethrow;
    }
  }

  Future<void> setExposureOffset(double offset) async {
    if (cameraController == null) {
      return;
    }

    try {
      final appliedOffset = await cameraController!.setExposureOffset(offset);
      if (appliedOffset != _currentExposureOffset) {
        setState(() {
          _currentExposureOffset = appliedOffset;
        });
      }
    } on CameraException catch (e) {
      log('setExposureOffset error', error: e);
      rethrow;
    }
  }

  Future<void> setFocusMode(FocusMode mode) async {
    if (cameraController == null) {
      return;
    }

    try {
      await cameraController?.setFocusMode(mode);
    } on CameraException catch (e) {
      log('setFocusMode error', error: e);
      rethrow;
    }
  }

  // ignore: unused_element
  Future<void> _startVideoPlayer() async {
    if (videoFile == null) {
      return;
    }

    final vController = VideoPlayerController.file(File(videoFile!.path));

    videoPlayerListener = () {
      if (videoController != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) {
          setState(() {});
        }

        videoController!.removeListener(videoPlayerListener!);
      }
    };

    vController.addListener(videoPlayerListener!);
    await vController.setLooping(true);
    await vController.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        imageFile = null;
        videoController = vController;
      });
    }

    await vController.play();
  }

  Future<XFile?> takePicture() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final file = await cameraController?.takePicture();
      return file;
    } on CameraException catch (e) {
      _logError(e.code, e.description);
      return null;
    }
  }
}
