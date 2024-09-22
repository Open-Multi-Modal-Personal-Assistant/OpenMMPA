import 'dart:developer';
import 'dart:math' as m;

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:gap/gap.dart';
import 'package:inspector_gadget/camera/service/m_file.dart';
import 'package:inspector_gadget/camera/service/page_state.dart';
import 'package:inspector_gadget/camera/view/page_indicator.dart';
import 'package:inspector_gadget/common/ok_cancel_alert_dialog.dart';
import 'package:inspector_gadget/speech/view/tts_mixin.dart';
import 'package:video_player/video_player.dart';
import 'package:watch_it/watch_it.dart';

class ThumbnailCarouselWidget extends WatchingStatefulWidget {
  const ThumbnailCarouselWidget(this.files, {super.key});

  final List<MFile> files;

  @override
  State<ThumbnailCarouselWidget> createState() => ThumbnailCarouselState();
}

void logError(String code, String? message) {
  log('Error: $code${message == null ? '' : '\nError Message: $message'}');
}

class ThumbnailCarouselState extends State<ThumbnailCarouselWidget>
    with TtsMixin {
  static const controlIconSize = 64.0;
  late final PageState pageState;
  // Wonderous App also uses smooth_page_indicator
  // https://github.com/gskinnerTeam/flutter-wonderous-app/blob/main/lib/ui/screens/intro/intro_screen.dart#L27
  late final PageController pageController = PageController()
    ..addListener(handlePageChanged);

  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;

  @override
  void initState() {
    pageState = GetIt.I.get<PageState>();
    pageState.setPageIndex(m.max(0, pageState.pageIndex));
    initVideoPlayer();

    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    videoController?.dispose();
    super.dispose();
  }

  Future<void> handlePageChanged() async {
    final newPage = pageController.page?.round();
    if (newPage != null && newPage != pageState.currentPage) {
      pageState.setPageIndex(newPage);

      await initVideoPlayer();
    }
  }

  void handleSemanticSwipe(int dir) {
    pageController.animateToPage(
      (pageController.page ?? 0).round() + dir,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> incrementPage(int dir) async {
    final changed = pageState.incrementPageIndex(dir);
    if (changed) {
      await initVideoPlayer();
      pageController.jumpToPage(pageState.currentPage);
    }
  }

  /// Display the thumbnail of the captured image or video.
  Widget thumbnailWidget(BuildContext context, int pageCount, int currentPage) {
    const shrinkFactor = 0.8;
    final size = MediaQuery.of(context).size;
    final mediaSize = m.min(
          size.width - 2 * controlIconSize,
          size.height - 2 * controlIconSize,
        ) *
        shrinkFactor;
    final pages = List<Widget>.generate(pageCount, (_) => Container());
    final medium = widget.files[currentPage];

    return SizedBox(
      width: (size.width - 2 * controlIconSize) * shrinkFactor,
      height: (size.height - 2 * controlIconSize) * shrinkFactor,
      child: Center(
        child: Stack(
          children: [
            // Just to instantiate a dummy PageView for PageController to work
            MergeSemantics(
              child: Semantics(
                onIncrease: () => handleSemanticSwipe(1),
                onDecrease: () => handleSemanticSwipe(-1),
                child: PageView(
                  controller: pageController,
                  children: pages,
                  onPageChanged: (_) => HapticFeedback.lightImpact(),
                ),
              ),
            ),
            switch (medium.fileType) {
              MFileType.image => Image.file(medium.file, fit: BoxFit.fill),
              MFileType.video => videoController == null
                  ? Icon(Icons.hourglass_bottom, size: mediaSize)
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.pink),
                      ),
                      child: AspectRatio(
                        aspectRatio: videoController!.value.aspectRatio,
                        child: VideoPlayer(videoController!),
                      ),
                    ),
              MFileType.audio => Icon(Icons.audio_file, size: mediaSize),
              MFileType.pdf => Icon(Icons.picture_as_pdf, size: mediaSize),
              _ => Icon(
                  Icons.file_present,
                  size: mediaSize,
                ), // also MFileType.other
            },
          ],
        ),
      ),
    );
  }

  Future<bool> initVideoPlayer() async {
    if (widget.files.isEmpty ||
        pageState.pageIndex < 0 ||
        pageState.pageIndex > widget.files.length - 1) {
      return false;
    }

    final currentFile = widget.files[pageState.pageIndex];
    if (currentFile.fileType != MFileType.video) {
      return false;
    }

    final vController = VideoPlayerController.file(currentFile.file);

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
        videoController = vController;
      });
    }

    return true;
  }

  Future<void> onDeleteMediaClicked(int pageCount, int currentPage) async {
    if (pageCount <= 0) {
      return;
    }

    if (await okCancelAlertDialog(context) == OkCancelResult.ok) {
      final fileToRemove = widget.files[currentPage];
      await fileToRemove.file.delete();
      pageState.incrementPageCount(-1);
      widget.files.removeAt(currentPage);
      await initVideoPlayer();
      setState(() {});
    }
  }

  Widget commandRowWidget(int pageCount, int currentPage) {
    final commandButtons = <Widget>[
      if (pageCount > 0)
        IconButton.filledTonal(
          onPressed: () async => pageCount > 0
              ? onDeleteMediaClicked(pageCount, currentPage)
              : null,
          icon: const Icon(Icons.clear, color: Colors.red),
        )
      else
        const Icon(Icons.do_disturb),
    ];

    if (pageCount > 0) {
      final medium = widget.files[currentPage];
      if ([MFileType.audio, MFileType.video].contains(medium.fileType)) {
        commandButtons.add(const Gap(controlIconSize));
      }

      if (medium.fileType == MFileType.video) {
        if (videoController?.value != null) {
          final vPlayer = videoController!.value;
          final isPlaying = vPlayer.isPlaying;
          commandButtons.addAll([
            IconButton.filledTonal(
              onPressed: () async {
                isPlaying
                    ? await videoController?.pause()
                    : await videoController?.play();
                setState(() {});
              },
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            IconButton.filledTonal(
              onPressed: isPlaying
                  ? () async {
                      await videoController?.pause();
                      await videoController?.seekTo(Duration.zero);
                      setState(() {});
                    }
                  : null,
              icon: const Icon(Icons.stop),
            ),
          ]);
        }
      } else if (medium.fileType == MFileType.audio) {
        final isPlaying = isAudioPlaying();
        commandButtons.addAll([
          IconButton.filledTonal(
            onPressed: () async {
              await playOrPauseAudio(medium.xFile.path);
              setState(() {});
            },
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          ),
          IconButton.filledTonal(
            onPressed: isPlaying
                ? () async {
                    await stopAudio();
                    setState(() {});
                  }
                : null,
            icon: const Icon(Icons.stop),
          ),
        ]);
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: commandButtons,
    );
  }

  Widget stepButton(int currentPage, int dir) {
    final newPosition = currentPage + dir;
    return Center(
      child: IconButton.filledTonal(
        onPressed: newPosition >= 0 && newPosition < widget.files.length
            ? () async => incrementPage(dir)
            : null,
        icon: Icon(dir < 0 ? Icons.chevron_left : Icons.chevron_right),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mediaSize = m.min(size.width, size.height);
    final currentPage = watchPropertyValue((PageState p) => p.currentPage);
    final pageCount = watchPropertyValue((PageState p) => p.pageCount);
    return LayoutGrid(
      columnSizes: [controlIconSize.px, auto, controlIconSize.px],
      rowSizes: [controlIconSize.px, auto, controlIconSize.px],
      children: [
        Container(),
        commandRowWidget(pageCount, currentPage),
        Container(),
        stepButton(currentPage, -1),
        if (pageCount > 0)
          thumbnailWidget(context, pageCount, currentPage)
        else
          Center(child: Icon(Icons.do_disturb, size: mediaSize / 2)),
        stepButton(currentPage, 1),
        Container(),
        AppPageIndicator(controller: pageController),
        Container(),
      ],
    );
  }
}
