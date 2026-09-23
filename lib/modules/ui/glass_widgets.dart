import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_colors.dart';
import 'styles.dart';

// ── Mesh Orb & Background ──────────────────────────────────────────────────

class MeshOrb extends StatefulWidget {
  const MeshOrb({
    super.key,
    required this.color,
    required this.size,
    required this.duration,
    required this.travel,
  });

  final Color color;
  final double size;
  final Duration duration;
  final Offset travel;

  @override
  State<MeshOrb> createState() => _MeshOrbState();
}

class _MeshOrbState extends State<MeshOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        switch (state) {
          case AppLifecycleState.hidden:
          case AppLifecycleState.paused:
            _controller.stop();
          case AppLifecycleState.resumed:
            _controller.repeat(reverse: true);
          case AppLifecycleState.inactive:
          case AppLifecycleState.detached:
            break;
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOutSine.transform(_controller.value);
        return Transform.translate(
          offset: Offset(widget.travel.dx * t, widget.travel.dy * t),
          child: child,
        );
      },
      child: RepaintBoundary(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ambient mesh background: 3 drifting [MeshOrb]s behind the app content.
class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key, required this.colors, this.orbOpacity});

  final AppColors colors;
  final double? orbOpacity;

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = orbOpacity ?? colors.orbOpacity;
    return Stack(
      children: [
        Positioned(
          top: -160,
          left: -160,
          child: MeshOrb(
            color: colors.orb1.withValues(alpha: effectiveOpacity),
            size: 480,
            duration: const Duration(seconds: 16),
            travel: const Offset(60, 70),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -120,
          child: MeshOrb(
            color: colors.orb2.withValues(alpha: effectiveOpacity),
            size: 440,
            duration: const Duration(seconds: 18),
            travel: const Offset(-60, -60),
          ),
        ),
        Positioned(
          top: 180,
          right: 120,
          child: MeshOrb(
            color: colors.orb3.withValues(alpha: effectiveOpacity),
            size: 340,
            duration: const Duration(seconds: 20),
            travel: const Offset(-40, 45),
          ),
        ),
      ],
    );
  }
}

// ── Glass Scaffold ──────────────────────────────────────────────────────────

class GlassScaffold extends StatelessWidget {
  final Widget body;
  final Widget? header;
  final AppColors colors;
  final bool enableMeshOrbs;
  final bool enableGradientTint;
  final EdgeInsetsGeometry? padding;
  final double? orbOpacity;

  const GlassScaffold({
    super.key,
    required this.body,
    required this.colors,
    this.header,
    this.enableMeshOrbs = true,
    this.enableGradientTint = true,
    this.padding,
    this.orbOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: Stack(
        children: [
          // 1. Mesh Gradient Base Tint (Translucent - exactly like JA_MES_Tool)
          if (enableGradientTint)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.bgSecondary,
                      colors.bgSecondary.withValues(alpha: 0.5),
                      colors.bgSecondary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),

          // 2. GPU-Composited Floating Mesh Orbs
          if (enableMeshOrbs)
            Positioned.fill(
              child: MeshBackground(colors: colors, orbOpacity: orbOpacity),
            ),

          // 3. Main Content Tree
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?header,
                Expanded(
                  child: padding != null
                      ? Padding(padding: padding!, child: body)
                      : body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bento Card ──────────────────────────────────────────────────────────────

class BentoCard extends StatelessWidget {
  final AppColors colors;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? blurSigma;
  final double? bgOpacity;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool isFeatured;
  final Color? customBg;
  final Color? customBorder;
  final Color? glowColor;
  final double? borderWidth;
  final bool showTopHighlight;

  const BentoCard({
    super.key,
    required this.colors,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.blurSigma,
    this.bgOpacity,
    this.onTap,
    this.onDoubleTap,
    this.isFeatured = false,
    this.customBg,
    this.customBorder,
    this.glowColor,
    this.borderWidth,
    this.showTopHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    AppTheme? theme;
    try {
      theme = context.watch<AppTheme>();
    } catch (_) {}

    final effectiveBlur = blurSigma ?? theme?.cardBlur ?? 20.0;
    final effectiveOpacity = bgOpacity ?? theme?.cardOpacity;
    final effectiveBg = customBg != null
        ? (effectiveOpacity != null
              ? customBg!.withValues(
                  alpha: (customBg!.a * (effectiveOpacity / 0.25)).clamp(
                    0.04,
                    0.98,
                  ),
                )
              : customBg!)
        : (effectiveOpacity != null
              ? colors.cardBg.withValues(alpha: effectiveOpacity)
              : colors.cardBg);
    final effectiveBorder =
        customBorder ??
        (isFeatured
            ? (glowColor ?? colors.accentCyan).withValues(alpha: 0.75)
            : colors.borderDefault);

    Widget content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        borderRadius: BorderRadius.circular(borderRadius),
        hoverColor: colors.cardHoverBg.withValues(alpha: 0.2),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: effectiveBorder,
              width: borderWidth ?? (isFeatured ? 2.0 : 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              if (isFeatured || glowColor != null)
                BoxShadow(
                  color: (glowColor ?? colors.primaryGlow).withValues(
                    alpha: isFeatured ? 0.35 : 0.20,
                  ),
                  blurRadius: isFeatured ? 24 : 16,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          foregroundDecoration: showTopHighlight
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border(
                    top: BorderSide(
                      color: isFeatured
                          ? (glowColor ?? colors.accentCyan).withValues(
                              alpha: 0.7,
                            )
                          : colors.glassHighlight,
                      width: 1.0,
                    ),
                  ),
                )
              : null,
          child: child,
        ),
      ),
    );

    if (effectiveBlur > 0) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: RepaintBoundary(child: content),
    );
  }
}

// ── Rotating Glow Border ────────────────────────────────────────────────────

/// A widget that paints an animated rotating glowing light beam around its perimeter
/// when [isActive] is true. Ideal for drawing strong visual attention to selected cards.
class RotatingGlowBorder extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color color;
  final double borderRadius;
  final double borderWidth;
  final double glowBlur;
  final Duration duration;

  const RotatingGlowBorder({
    super.key,
    required this.child,
    required this.isActive,
    required this.color,
    this.borderRadius = 16.0,
    this.borderWidth = 2.0,
    this.glowBlur = 6.0,
    this.duration = const Duration(milliseconds: 3000),
  });

  @override
  State<RotatingGlowBorder> createState() => _RotatingGlowBorderState();
}

class _RotatingGlowBorderState extends State<RotatingGlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    if (widget.isActive) {
      _controller.repeat();
    }

    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (!mounted || !widget.isActive) return;
        switch (state) {
          case AppLifecycleState.hidden:
          case AppLifecycleState.paused:
            _controller.stop();
          case AppLifecycleState.resumed:
            _controller.repeat();
          case AppLifecycleState.inactive:
          case AppLifecycleState.detached:
            break;
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant RotatingGlowBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return RepaintBoundary(
      child: Stack(
        children: [
          RepaintBoundary(child: widget.child),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: RotatingGlowBorderPainter(
                      animationProgress: _controller.value,
                      color: widget.color,
                      borderRadius: widget.borderRadius,
                      borderWidth: widget.borderWidth,
                      glowBlur: widget.glowBlur,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RotatingGlowBorderPainter extends CustomPainter {
  final double animationProgress;
  final Color color;
  final double borderRadius;
  final double borderWidth;
  final double glowBlur;

  RotatingGlowBorderPainter({
    required this.animationProgress,
    required this.color,
    required this.borderRadius,
    required this.borderWidth,
    required this.glowBlur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final halfWidth = borderWidth / 2.0;
    final rect = Rect.fromLTWH(
      halfWidth,
      halfWidth,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.max(0.0, borderRadius - halfWidth)),
    );

    final angle = animationProgress * 2 * math.pi;

    final sweepGradient = SweepGradient(
      center: Alignment.center,
      transform: GradientRotation(angle),
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.85),
        Colors.white,
        color,
        color.withValues(alpha: 0.65),
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.05, 0.12, 0.16, 0.20, 0.26, 0.34, 1.0],
    );

    // 1. Diffuse outer neon bloom
    if (glowBlur > 0) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth * 2.2
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur)
        ..shader = sweepGradient.createShader(rect);
      canvas.drawRRect(rrect, glowPaint);
    }

    // 2. Crisp stroke for the bright core beam
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = sweepGradient.createShader(rect);
    canvas.drawRRect(rrect, corePaint);
  }

  @override
  bool shouldRepaint(covariant RotatingGlowBorderPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.glowBlur != glowBlur;
  }
}

// ── SubCard ─────────────────────────────────────────────────────────────────

class SubCard extends StatelessWidget {
  final AppColors colors;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? customBg;
  final Color? customBorder;
  final double? bgOpacity;

  const SubCard({
    super.key,
    required this.colors,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.borderRadius = 10,
    this.customBg,
    this.customBorder,
    this.bgOpacity,
  });

  @override
  Widget build(BuildContext context) {
    AppTheme? theme;
    try {
      theme = context.watch<AppTheme>();
    } catch (_) {}

    final effectiveOpacity = bgOpacity ?? theme?.cardOpacity;
    final effectiveBg = customBg != null
        ? (effectiveOpacity != null
              ? customBg!.withValues(
                  alpha: (customBg!.a * (effectiveOpacity / 0.25)).clamp(
                    0.04,
                    0.98,
                  ),
                )
              : customBg!)
        : (effectiveOpacity != null
              ? colors.subCardBg.withValues(
                  alpha: (colors.subCardBg.a * (effectiveOpacity / 0.25)).clamp(
                    0.04,
                    0.98,
                  ),
                )
              : colors.subCardBg);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: customBorder ?? colors.subCardBorder),
      ),
      child: child,
    );
  }
}

// ── Pill Badge ──────────────────────────────────────────────────────────────

class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
    this.showDot = false,
    this.icon,
    this.fontSize = 11,
    this.padding,
  });

  final String label;
  final Color color;
  final Color bg;
  final Color border;
  final bool showDot;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [BoxShadow(color: color, blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glowing Action Button ───────────────────────────────────────────────────

class GlowingActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final AppColors colors;
  final double height;
  final Color? customStartColor;
  final Color? customEndColor;
  final Color? glowColor;

  const GlowingActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
    required this.colors,
    this.height = 38,
    this.customStartColor,
    this.customEndColor,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final start =
        customStartColor ??
        (isDestructive ? colors.accentRose : colors.accentColor);
    final end =
        customEndColor ??
        (isDestructive ? const Color(0xFFBE123C) : colors.accentCyan);

    final gradient = LinearGradient(
      colors: [start, end],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final effectiveGlow =
        glowColor ??
        (isDestructive
            ? colors.accentRose.withValues(alpha: 0.4)
            : (customStartColor != null
                  ? customStartColor!.withValues(alpha: 0.35)
                  : colors.primaryGlow));

    final isDisabled = onPressed == null;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: effectiveGlow,
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ).copyWith(elevation: WidgetStateProperty.all(0)),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(colors: [colors.subCardBg, colors.subCardBg])
                : gradient,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDisabled
                  ? colors.subCardBorder
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: height <= 30 ? 10 : 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isDisabled ? colors.textMuted : Colors.white,
                  size: height <= 30 ? 13 : 15,
                ),
                SizedBox(width: height <= 30 ? 5 : 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isDisabled ? colors.textMuted : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: height <= 30 ? 11 : 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass Icon Button ───────────────────────────────────────────────────────

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppColors colors;
  final Color? iconColor;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.colors,
    this.tooltip,
    this.iconColor,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      hoverColor: colors.cardHoverBg.withValues(alpha: 0.3),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: colors.borderDefault),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: size * 0.52,
          color: iconColor ?? colors.textPrimary,
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

// ── TopBar Expanding Button (Showcase Glass Style) ─────────────────────────

/// A modern Apple Liquid Glass Pill Button for the Topbar with smooth hover zoom & label expansion
class TopBarExpandingButton extends StatefulWidget {
  final Widget icon;
  final String? collapsedLabel;
  final String expandedLabel;
  final Color? textColor;
  final VoidCallback onTap;
  final String tooltip;
  final AppColors colors;
  final bool isCompact;

  const TopBarExpandingButton({
    super.key,
    required this.icon,
    this.collapsedLabel,
    required this.expandedLabel,
    this.textColor,
    required this.onTap,
    required this.tooltip,
    required this.colors,
    this.isCompact = false,
  });

  @override
  State<TopBarExpandingButton> createState() => _TopBarExpandingButtonState();
}

class _TopBarExpandingButtonState extends State<TopBarExpandingButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final showLabel =
        _isHovered || (!widget.isCompact && widget.collapsedLabel != null);
    final currentLabel = _isHovered
        ? widget.expandedLabel
        : (widget.collapsedLabel ?? '');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(100),
              splashFactory: NoSplash.splashFactory,
              hoverColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: showLabel ? 11 : 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? colors.cardHoverBg.withValues(alpha: 0.35)
                      : colors.subCardBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _isHovered
                        ? (widget.textColor ?? colors.accentCyan).withValues(
                            alpha: 0.65,
                          )
                        : colors.subCardBorder,
                    width: _isHovered ? 1.2 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? (widget.textColor ?? colors.primaryGlow).withValues(
                              alpha: 0.25,
                            )
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: _isHovered ? 10 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.icon,
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      clipBehavior: Clip.none,
                      child: showLabel && currentLabel.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 6),
                                Text(
                                  currentLabel,
                                  softWrap: false,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: TextStyle(
                                    color:
                                        widget.textColor ?? colors.textPrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Asymmetric Ping-Pong Marquee Text ───────────────────────────────────────

/// Asymmetric Ping-Pong Marquee Text widget (Showcase pattern):
/// - Only scrolls if text overflows the container constraints.
/// - Hold at start for [pauseStart] (e.g. 1400ms).
/// - Smoothly scrolls forward to the end with [forwardCurve].
/// - Hold at end for [pauseEnd] (e.g. 1400ms).
/// - Smoothly scrolls back to start with [returnCurve].
/// - Zero performance overhead when text fits within bounds.
class AsymmetricMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration pauseStart;
  final Duration pauseEnd;
  final double velocity; // px/sec
  final Curve forwardCurve;
  final Curve returnCurve;

  const AsymmetricMarqueeText({
    super.key,
    required this.text,
    this.style,
    this.pauseStart = const Duration(milliseconds: 1400),
    this.pauseEnd = const Duration(milliseconds: 1400),
    this.velocity = 35.0,
    this.forwardCurve = Curves.easeInOutCubic,
    this.returnCurve = Curves.easeInOutCubic,
  });

  @override
  State<AsymmetricMarqueeText> createState() => _AsymmetricMarqueeTextState();
}

class _AsymmetricMarqueeTextState extends State<AsymmetricMarqueeText> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _scheduleStart();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AsymmetricMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted) {
          _scheduleStart();
        }
      });
    }
  }

  void _scheduleStart() {
    _timer?.cancel();
    if (_isDisposed || !mounted) return;
    if (!_scrollController.hasClients) {
      _timer = Timer(const Duration(milliseconds: 150), _scheduleStart);
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    _timer = Timer(widget.pauseStart, _animateForward);
  }

  void _animateForward() {
    _timer?.cancel();
    if (_isDisposed || !mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final duration = Duration(
      milliseconds: ((maxScroll / widget.velocity) * 1000)
          .round()
          .clamp(600, 6000)
          .toInt(),
    );

    _scrollController
        .animateTo(maxScroll, duration: duration, curve: widget.forwardCurve)
        .then((_) {
          if (_isDisposed || !mounted) return;
          _timer = Timer(widget.pauseEnd, _animateReturn);
        });
  }

  void _animateReturn() {
    _timer?.cancel();
    if (_isDisposed || !mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final duration = Duration(
      milliseconds: ((maxScroll / (widget.velocity * 1.25)) * 1000)
          .round()
          .clamp(500, 5000)
          .toInt(),
    );

    _scrollController
        .animateTo(0, duration: duration, curve: widget.returnCurve)
        .then((_) {
          if (_isDisposed || !mounted) return;
          _timer = Timer(widget.pauseStart, _animateForward);
        });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

typedef MarqueeText = AsymmetricMarqueeText;
typedef BounceMarqueeText = AsymmetricMarqueeText;

// ── Smart Bounce Marquee Path Input Field ───────────────────────────────────

/// A smart path input field that automatically displays bouncing marquee
/// when unfocused and text is long, and seamlessly switches to editable
/// TextField upon focus/tap.
class GlassBouncePathField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final AppColors colors;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;

  const GlassBouncePathField({
    super.key,
    required this.controller,
    required this.colors,
    this.focusNode,
    this.hintText = '',
    this.onSubmitted,
    this.onChanged,
    this.style,
  });

  @override
  State<GlassBouncePathField> createState() => _GlassBouncePathFieldState();
}

class _GlassBouncePathFieldState extends State<GlassBouncePathField> {
  late FocusNode _focusNode;
  bool _internalFocus = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _internalFocus = true;
    }
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _onTextChange() {
    if (mounted && !_isFocused) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    if (_internalFocus) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final text = widget.controller.text;
    final defaultStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 11.0,
      color: c.textPrimary,
    );
    final effectiveStyle = widget.style ?? defaultStyle;

    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: c.subCardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _isFocused
              ? c.accentCyan.withValues(alpha: 0.6)
              : c.subCardBorder,
          width: _isFocused ? 1.2 : 1.0,
        ),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // 1. TextField (Always mounted so selection/focus works)
          Opacity(
            opacity: _isFocused || text.isEmpty ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_isFocused && text.isNotEmpty,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                style: effectiveStyle,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  border: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 10.5),
                ),
                onSubmitted: widget.onSubmitted,
                onChanged: widget.onChanged,
              ),
            ),
          ),

          // 2. Bounce Marquee Text (Displayed when NOT focused and has text)
          if (!_isFocused && text.isNotEmpty)
            Positioned.fill(
              child: Tooltip(
                message: text,
                waitDuration: const Duration(milliseconds: 500),
                child: InkWell(
                  onTap: () {
                    _focusNode.requestFocus();
                    widget.controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: widget.controller.text.length,
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: BounceMarqueeText(
                      text: text,
                      style: effectiveStyle,
                      velocity: 40.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
