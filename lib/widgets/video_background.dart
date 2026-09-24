import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  const VideoBackground({super.key});

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/genki_background.mp4',
    );
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          _controller.setLooping(true);
          _controller.play();
          setState(() => _ready = true);
        })
        .catchError((Object e) {
          debugPrint('Video init failed: $e');
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _single() {
    final size = _controller.value.size;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  Widget _half() {
    final size = _controller.value.size;
    return Expanded(
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox.expand();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final aspectRatio = h > 0 ? w / h : 1.0;
        // 宽高比小于 2.1 的平板/常规横屏机型，只显示单个背景视频铺满
        final isNarrow = aspectRatio < 2.1;

        if (isNarrow) {
          return SizedBox.expand(child: _single());
        }

        return SizedBox.expand(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_half(), _half()],
          ),
        );
      },
    );
  }
}
