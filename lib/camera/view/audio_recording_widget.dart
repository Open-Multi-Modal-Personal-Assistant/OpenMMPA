import 'dart:math' as m;

import 'package:flutter/material.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:inspector_gadget/speech/view/stt_mixin.dart';
import 'package:watch_it/watch_it.dart';

class AudioRecordingWidget extends WatchingStatefulWidget {
  const AudioRecordingWidget({super.key});

  @override
  State<AudioRecordingWidget> createState() => AudioRecordingState();
}

class AudioRecordingState extends State<AudioRecordingWidget>
    with SingleTickerProviderStateMixin, SttMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    startRecording(forSpeech: false);

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mediaSize = m.min(size.width, size.height);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimateStyles.swing(
          _animationController,
          Icon(Icons.earbuds, size: mediaSize / 2.5),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: () async {
                await stopAudioRecording();
                if (context.mounted) {
                  Navigator.pop(context, '');
                }
              },
              icon: const Icon(Icons.do_disturb),
            ),
            IconButton.filledTonal(
              onPressed: () async {
                final path = await stopAudioRecording();
                if (context.mounted) {
                  Navigator.pop(context, path);
                }
              },
              icon: const Icon(Icons.stop),
            ),
          ],
        ),
      ],
    );
  }
}
