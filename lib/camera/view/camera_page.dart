import 'dart:developer';
import 'dart:math' as m;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inspector_gadget/camera/cubit/capture_cubit.dart';
import 'package:inspector_gadget/camera/cubit/image_cubit.dart';
import 'package:inspector_gadget/interaction/interaction.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/main/cubit/main_cubit.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<ImageCubit>(),
      child: BlocProvider(
        create: (_) => CaptureCubit(),
        child: const CameraView(),
      ),
    );
  }
}

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
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

class _CameraViewState extends State<CameraView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  List<CameraDescription> _cameras = <CameraDescription>[];
  CameraController? controller;
  bool enableAudio = false;
  double _minAvailableZoom = 1;
  double _maxAvailableZoom = 1;
  double _currentScale = 1;
  double _baseScale = 1;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    super.dispose();
  }

  // #docregion AppLifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }
  // #enddocregion AppLifecycle

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.captureAppBarTitle),
      ),
      body: Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: Center(
                child: _cameraPreviewWidget(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _cameraTogglesRowWidget(context),
    );
  }

  /// Display the preview from the camera
  /// (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    final cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return Container();
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          controller!,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onTapDown: (TapDownDetails details) =>
                    onViewFinderTap(details, constraints),
                onTap: () => onTakePictureButtonPressed(context),
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
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  /// Display a row of toggle to select the camera
  /// (or a message if no camera is available).
  Widget _cameraTogglesRowWidget(BuildContext context) {
    final toggles = <Widget>[];

    if (_cameras.isEmpty) {
      log('Error: No camera found.');
      return Container();
    } else {
      final size = MediaQuery.of(context).size;
      const appBarHeight = 56;
      // https://www.geeksforgeeks.org/flutter-set-the-height-of-the-appbar/
      final iconSize = m.min(size.width, size.height - appBarHeight) / 3;

      for (final cameraDescription in _cameras) {
        toggles.add(
          IconButton.filledTonal(
            onPressed: () => onNewCameraSelected(cameraDescription),
            icon: Icon(
              getCameraLensIcon(cameraDescription.lensDirection),
              size: iconSize,
            ),
          ),
        );
      }
    }

    return Row(children: toggles);
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final cameraController = controller!;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController
      ..setExposurePoint(offset)
      ..setFocusPoint(offset);
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      return controller!.setDescription(cameraDescription);
    } else {
      return _initializeCameraController(cameraDescription);
    }
  }

  Future<void> _initializeCameraController(
    CameraDescription cameraDescription,
  ) async {
    final cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

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
          log('You have denied camera access.');
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          log('Please go to Settings app to enable camera access.');
        case 'CameraAccessRestricted':
          // iOS only
          log('Camera access is restricted.');
        case 'AudioAccessDenied':
          log('You have denied audio access.');
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          log('Please go to Settings app to enable audio access.');
        case 'AudioAccessRestricted':
          // iOS only
          log('Audio access is restricted.');
        default:
          _logError(e.code, e.description);
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed(BuildContext context) {
    takePicture().then((XFile? file) {
      if (mounted) {
        log('Picture saved to ${file?.path}');

        if (file != null && file.path.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            context
                .select((MainCubit cubit) => cubit)
                .setState(MainCubit.recordingStateLabel);
            context.select((ImageCubit cubit) => cubit).setPath(file.path);
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    const InteractionPage(InteractionMode.multiModalMode),
              ),
            );
          });
        }
      }
    });
  }

  Future<XFile?> takePicture() async {
    final cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      log('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      _logError(e.code, e.description);
      return null;
    }
  }
}
