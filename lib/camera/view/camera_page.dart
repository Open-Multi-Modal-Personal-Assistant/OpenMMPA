import 'dart:developer';
import 'dart:math' as m;

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:inspector_gadget/camera/service/m_file.dart';
import 'package:inspector_gadget/camera/service/page_state.dart';
import 'package:inspector_gadget/camera/view/capture_state.dart';
import 'package:inspector_gadget/camera/view/thumbnail_carousel.dart';
import 'package:inspector_gadget/interaction/view/interaction_page.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/outlined_icon.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:watch_it/watch_it.dart';

class CameraPage extends WatchingStatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => CameraPageState();
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  return switch (direction) {
    CameraLensDirection.back => Icons.camera_rear,
    CameraLensDirection.front => Icons.camera_front,
    _ => Icons.camera, // CameraLensDirection.external
  };
}

/// Returns an icon indicating how many media is in stack.
IconData getNumberIcon(int number) {
  return switch (number) {
    0 => Icons.filter,
    1 => Icons.filter_1,
    2 => Icons.filter_2,
    3 => Icons.filter_3,
    4 => Icons.filter_4,
    5 => Icons.filter_5,
    6 => Icons.filter_6,
    7 => Icons.filter_7,
    8 => Icons.filter_8,
    9 => Icons.filter_9,
    _ => Icons.filter_9_plus
  };
}

class CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  AppLocalizations? l10n;
  double iconSize = 5;
  List<CameraDescription> cameras = <CameraDescription>[];
  CameraController? cameraController;
  List<MFile> files = [];
  bool enableAudio = false;
  double minAvailableExposureOffset = 0;
  double maxAvailableExposureOffset = 0;
  double currentExposureOffset = 0;
  late AnimationController settingsControlRowAnimationController;
  late Animation<double> settingsControlRowAnimation;
  late AnimationController flashModeControlRowAnimationController;
  late Animation<double> flashModeControlRowAnimation;
  late AnimationController exposureModeControlRowAnimationController;
  late Animation<double> exposureModeControlRowAnimation;
  late AnimationController focusModeControlRowAnimationController;
  late Animation<double> focusModeControlRowAnimation;
  double minAvailableZoom = 1;
  double maxAvailableZoom = 1;
  double currentScale = 1;
  double baseScale = 1;

  // Counting pointers (number of user fingers on screen)
  int pointers = 0;
  // For counting pages for files
  late final PageState pageState;

  @override
  void initState() {
    super.initState();

    pageState = GetIt.I.get<PageState>();
    pageState.setPageCount(files.length);

    GetIt.I.get<CaptureState>().setState(CaptureState.previewStateLabel);

    WidgetsBinding.instance.addObserver(this);

    settingsControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    settingsControlRowAnimation = CurvedAnimation(
      parent: settingsControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    flashModeControlRowAnimation = CurvedAnimation(
      parent: flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    exposureModeControlRowAnimation = CurvedAnimation(
      parent: exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    focusModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    focusModeControlRowAnimation = CurvedAnimation(
      parent: focusModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          await onNewCameraSelected(cameras[0]);
        }
      } on CameraException catch (e) {
        logError(e.code, e.description);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    settingsControlRowAnimationController.dispose();
    flashModeControlRowAnimationController.dispose();
    exposureModeControlRowAnimationController.dispose();
    focusModeControlRowAnimationController.dispose();
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
      initializeCameraController(cameraController!.description);
    }
  }
  // #enddocregion AppLifecycle

  @override
  Widget build(BuildContext context) {
    l10n = context.l10n;
    final size = MediaQuery.of(context).size;
    const appBarHeight = 56;
    // https://www.geeksforgeeks.org/flutter-set-the-height-of-the-appbar/
    iconSize = m.min(size.width, size.height - appBarHeight) / 10;

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
                  child: cameraPreviewWidget(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionConstruct(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget floatingActionConstruct(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        extraActionsRowWidget(context),
        captureControlRowWidget(context),
        modeControlRowWidget(context),
        camToggleRowWidget(context),
      ],
    );
  }

  Widget extraActionsRowWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: outlinedIcon(
            context,
            Icons.attach_file,
            iconSize,
            color: Colors.blue,
          ),
          color: Colors.transparent,
          onPressed: onAttachFileButtonPressed,
        ),
        IconButton(
          onPressed: () => onMoveOnButtonPressed(context),
          icon: outlinedIcon(
            context,
            Icons.arrow_forward,
            iconSize,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  /// Display the preview from the camera
  /// (or a message if the preview is not available).
  Widget cameraPreviewWidget() {
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
        onPointerDown: (_) => pointers++,
        onPointerUp: (_) => pointers--,
        child: CameraPreview(
          cameraController!,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: handleScaleStart,
                onScaleUpdate: handleScaleUpdate,
                onTapDown: (TapDownDetails details) =>
                    onViewFinderTap(details, constraints),
              );
            },
          ),
        ),
      );
    }
  }

  void handleScaleStart(ScaleStartDetails details) {
    baseScale = currentScale;
  }

  Future<void> handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (cameraController == null || pointers != 2) {
      return;
    }

    currentScale =
        (baseScale * details.scale).clamp(minAvailableZoom, maxAvailableZoom);

    await cameraController!.setZoomLevel(currentScale);
  }

  /// Display the thumbnail carousel in a bottom
  Future<void> onCardStackPressed() async {
    // https://stackoverflow.com/questions/48968176/how-do-you-adjust-the-height-and-borderradius-of-a-bottomsheet-in-flutter
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      enableDrag: false,
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize:
              0.90, // Initial height as a fraction of screen height
          builder: (BuildContext context, ScrollController scrollController) {
            return ThumbnailCarouselWidget(
              files,
            );
          },
        );
      },
    );
  }

  Widget cardStackWidget(BuildContext context) {
    final pageCount = watchPropertyValue((PageState p) => p.pageCount);
    return IconButton(
      icon: outlinedIcon(
        context,
        getNumberIcon(pageCount),
        iconSize,
        color: Colors.blue,
      ),
      color: Colors.transparent,
      onPressed: pageCount > 0 ? onCardStackPressed : null,
    );
  }

  /// Display a bar with buttons to change the flash and exposure modes
  Widget modeControlRowWidget(BuildContext context) {
    return SizeTransition(
      sizeFactor: settingsControlRowAnimation,
      child: ClipRect(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: outlinedIcon(
                    context,
                    Icons.flash_on,
                    iconSize,
                    color: Colors.blue,
                  ),
                  color: Colors.transparent,
                  onPressed: cameraController != null
                      ? onFlashModeButtonPressed
                      : null,
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
                    onPressed: cameraController != null
                        ? onFocusModeButtonPressed
                        : null,
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
                  onPressed: cameraController != null
                      ? onAudioModeButtonPressed
                      : null,
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
            flashModeControlRowWidget(context),
            exposureModeControlRowWidget(),
            focusModeControlRowWidget(),
          ],
        ),
      ),
    );
  }

  Widget flashModeControlRowWidget(BuildContext context) {
    return SizeTransition(
      sizeFactor: flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget exposureModeControlRowWidget() {
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
      sizeFactor: exposureModeControlRowAnimation,
      child: ClipRect(
        child: ColoredBox(
          color: Colors.transparent,
          child: Column(
            children: [
              const Center(
                child: Text('Exposure Mode'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(minAvailableExposureOffset.toString()),
                  Slider(
                    value: currentExposureOffset,
                    min: minAvailableExposureOffset,
                    max: maxAvailableExposureOffset,
                    label: currentExposureOffset.toString(),
                    onChanged:
                        minAvailableExposureOffset == maxAvailableExposureOffset
                            ? null
                            : setExposureOffset,
                  ),
                  Text(maxAvailableExposureOffset.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget focusModeControlRowWidget() {
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
      sizeFactor: focusModeControlRowAnimation,
      child: ClipRect(
        child: ColoredBox(
          color: Colors.transparent,
          child: Column(
            children: [
              const Center(
                child: Text('Focus Mode'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
  Widget captureControlRowWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
  List<Widget> cameraTogglesRowWidget(BuildContext context) {
    final toggles = <Widget>[];

    if (cameras.isEmpty) {
      log('Error: No camera found.');
      return [const Text('No camera')];
    } else {
      for (final cameraDescription in cameras) {
        toggles.add(
          IconButton(
            onPressed: () async => onNewCameraSelected(cameraDescription),
            icon: outlinedIcon(
              context,
              getCameraLensIcon(cameraDescription.lensDirection),
              iconSize,
              color: Colors.blue,
            ),
          ),
        );
      }
    }

    return toggles;
  }

  Widget settingsShowHideWidget(BuildContext context) {
    return IconButton(
      onPressed: cameraController != null ? onSettingsButtonPressed : null,
      icon: outlinedIcon(
        context,
        Icons.settings,
        iconSize,
        color: Colors.blue,
      ),
    );
  }

  Widget camToggleRowWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...cameraTogglesRowWidget(context),
        settingsShowHideWidget(context),
        cardStackWidget(context),
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
      return initializeCameraController(cameraDescription);
    }
  }

  Future<void> initializeCameraController(
    CameraDescription cameraDescription,
  ) async {
    final preferences = GetIt.I.get<PreferencesService>();
    cameraController = CameraController(
      cameraDescription,
      preferences.cameraResolutionPreset,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    if (cameraController == null) {
      return;
    }

    // If the controller is updated then update the UI.
    cameraController?.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (cameraController?.value.hasError ?? false) {
        log('Camera error ${cameraController?.value.errorDescription}');
      }
    });

    try {
      await cameraController?.initialize();
      await Future.wait(<Future<Object?>>[
        ...<Future<Object?>>[
          cameraController!
              .getMinExposureOffset()
              .then((double value) => minAvailableExposureOffset = value),
          cameraController!
              .getMaxExposureOffset()
              .then((double value) => maxAvailableExposureOffset = value),
        ],
        cameraController!
            .getMaxZoomLevel()
            .then((double value) => maxAvailableZoom = value),
        cameraController!
            .getMinZoomLevel()
            .then((double value) => minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      // ignore: unused_local_variable
      final unused = switch (e.code) {
        'CameraAccessDenied' =>
          showInSnackBar('You have denied camera access.'),
        'CameraAccessDeniedWithoutPrompt' => showInSnackBar(
            'Please go to Settings app to enable camera access.',
          ), // iOS only
        'CameraAccessRestricted' =>
          showInSnackBar('Camera access is restricted.'), // iOS only
        'AudioAccessDenied' => showInSnackBar('You have denied audio access.'),
        'AudioAccessDeniedWithoutPrompt' => showInSnackBar(
            'Please go to Settings app to enable audio access.',
          ), // iOS only
        'AudioAccessRestricted' =>
          showInSnackBar('Audio access is restricted.'), // iOS only
        _ => logError(e.code, e.description),
      };
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((XFile? file) async {
      log('Picture saved to ${file?.path}');
      if (file != null) {
        pageState.incrementPageCount(1);
        final mimeType =
            await MFile.obtainMimeType(file, contentInspection: false);
        files.add(MFile(file, mimeType));
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void onMoveOnButtonPressed(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => InteractionPage(
            InteractionMode.imageChat,
            mediaFiles: files,
          ),
        ),
      );
    });
  }

  void onSettingsButtonPressed() {
    if (settingsControlRowAnimationController.value == 1) {
      settingsControlRowAnimationController.reverse();
    } else {
      settingsControlRowAnimationController.forward();
    }
  }

  void onFlashModeButtonPressed() {
    if (flashModeControlRowAnimationController.value == 1) {
      flashModeControlRowAnimationController.reverse();
    } else {
      flashModeControlRowAnimationController.forward();
      exposureModeControlRowAnimationController.reverse();
      focusModeControlRowAnimationController.reverse();
    }
  }

  void onExposureModeButtonPressed() {
    if (exposureModeControlRowAnimationController.value == 1) {
      exposureModeControlRowAnimationController.reverse();
    } else {
      exposureModeControlRowAnimationController.forward();
      flashModeControlRowAnimationController.reverse();
      focusModeControlRowAnimationController.reverse();
    }
  }

  void onFocusModeButtonPressed() {
    if (focusModeControlRowAnimationController.value == 1) {
      focusModeControlRowAnimationController.reverse();
    } else {
      focusModeControlRowAnimationController.forward();
      flashModeControlRowAnimationController.reverse();
      exposureModeControlRowAnimationController.reverse();
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
    stopVideoRecording().then((XFile? file) async {
      log('Video recorded to ${file?.path}');
      if (file != null && file.path.trim().isNotEmpty) {
        pageState.incrementPageCount(1);
        final mimeType = await MFile.obtainMimeType(file);
        files.add(MFile(file, mimeType));
        if (mounted) {
          setState(() {});
        }
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
      if (appliedOffset != currentExposureOffset) {
        setState(() {
          currentExposureOffset = appliedOffset;
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
      logError(e.code, e.description);
      return null;
    }
  }

  Future<void> onAttachFileButtonPressed() async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: [
        // image formats
        'jpg',
        'jpeg',
        'png',
        // video formats
        'mov',
        'mpeg',
        'mp4',
        'mpg',
        'avi',
        'wmv',
        'mpegps',
        'flv',
        // document formats
        'txt',
        'pdf',
        'docx',
        // audio formats
        'wav',
        'mp3',
        'aiff',
        'aac',
        'ogg',
        'flac',
      ],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      var added = false;
      for (final file in result.files) {
        if (file.path != null && file.path!.isNotEmpty) {
          final mimeType = await MFile.obtainMimeType(file.xFile);
          final mFile = MFile(file.xFile, mimeType);
          if (!mFile.mimeTypeIsUnknown()) {
            files.add(mFile);
            pageState.incrementPageCount(1);
            added = true;
          }
        }
      }

      if (added) {
        setState(() {});
      }
    }
  }
}
