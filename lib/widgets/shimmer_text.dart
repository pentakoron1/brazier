import 'package:material_ui/material_ui.dart';

class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color baseColor;
  final Color glareColor;
  final Color secondGlareColor;
  final bool isShimmering;

  const ShimmerText({
    super.key,
    required this.text,
    required this.baseColor,
    required this.glareColor,
    required this.secondGlareColor,
    this.style,
    this.isShimmering = false,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool _isHoveredOrTapped = false;

  @override
  void initState() {
    super.initState();
    if (widget.isShimmering) {
      _start();
    }
  }

  @override
  void didUpdateWidget(ShimmerText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShimmering != oldWidget.isShimmering) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    if (widget.isShimmering || _isHoveredOrTapped) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    if (!_controller.isAnimating) _controller.value = 0;
    _controller.repeat();
  }

  // Finish the current sweep instead of freezing mid-text
  void _stop() {
    if (_controller.isAnimating) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _isHoveredOrTapped = true;
        _updateAnimationState();
      },
      onExit: (_) {
        _isHoveredOrTapped = false;
        _updateAnimationState();
      },
      child: GestureDetector(
        onTapDown: (_) {
          _isHoveredOrTapped = true;
          _updateAnimationState();
        },
        onTapUp: (_) {
          _isHoveredOrTapped = false;
          _updateAnimationState();
        },
        onTapCancel: () {
          _isHoveredOrTapped = false;
          _updateAnimationState();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  widget.baseColor,
                  widget.glareColor,
                  widget.secondGlareColor,
                  widget.baseColor,
                ],
                stops: const [0.25, 0.5, 0.6, 0.75],
                transform: _SlideGradientTransform(-1 + 2 * _controller.value),
              ).createShader(bounds),
              child: child,
            );
          },
          child: Text(widget.text, style: widget.style),
        ),
      ),
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double percent; // -1 = fully left of the text, 1 = fully right
  const _SlideGradientTransform(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0, 0);
  }
}