import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Logo: slide-up + fade
  late final AnimationController _logoCtrl;
  late final Animation<double>   _logoOpacity;
  late final Animation<Offset>   _logoSlide;

  // Halo pulse that fires once after logo lands
  late final AnimationController _haloCtrl;
  late final Animation<double>   _haloScale;
  late final Animation<double>   _haloOpacity;

  // "LH INVOICE" text + underline draw
  late final AnimationController _textCtrl;
  late final Animation<double>   _textOpacity;
  late final Animation<double>   _underlineWidth;

  // Gold progress bar fill (loops)
  late final AnimationController _progressCtrl;

  // Shimmer sweep across the bar fill
  late final AnimationController _shimmerCtrl;

  static const _bg   = Color(0xFF060F09);
  static const _gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));

    _haloCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();

    // ── Logo ────────────────────────────────────────────────────────────────
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoSlide   = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    // ── Halo ────────────────────────────────────────────────────────────────
    _haloScale   = Tween<double>(begin: 0.55, end: 1.70)
        .animate(CurvedAnimation(parent: _haloCtrl, curve: Curves.easeOut));
    _haloOpacity = Tween<double>(begin: 0.45, end: 0.0)
        .animate(CurvedAnimation(parent: _haloCtrl, curve: Curves.easeIn));

    // ── Text / underline ────────────────────────────────────────────────────
    _textOpacity    = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _underlineWidth = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);

    // ── Sequence ────────────────────────────────────────────────────────────
    _logoCtrl.forward().then((_) {
      if (!mounted) return;
      _haloCtrl.forward();
      _textCtrl.forward();
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _haloCtrl.dispose();
    _textCtrl.dispose();
    _progressCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // Animate the trailing dots with the progress loop
  String get _dotsText {
    final v = CurvedAnimation(
            parent: _progressCtrl, curve: Curves.linear)
        .value;
    final count = (v * 5).floor().clamp(0, 4) + 1;
    return 'LOADING${'.' * count}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [

          // ── Dual background glow (logo zone + bar zone) ───────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _progressCtrl,
              builder: (_, __) => CustomPaint(
                painter: _DualGlowPainter(
                  logoGlow:  _logoCtrl.value,
                  barGlow:   CurvedAnimation(
                    parent: _progressCtrl,
                    curve: Curves.easeInOut,
                  ).value,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                const Spacer(flex: 2),

                // ── Logo + halo ──────────────────────────────────────────────
                SizedBox(
                  height: 190,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      // Halo ring behind logo
                      AnimatedBuilder(
                        animation: _haloCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: _haloScale.value,
                          child: Opacity(
                            opacity: _haloOpacity.value,
                            child: Container(
                              width: 185,
                              height: 185,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _gold.withAlpha(120),
                                    _gold.withAlpha(30),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Logo
                      SlideTransition(
                        position: _logoSlide,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: Image.asset(
                            'assets/invoice-image/logo.png',
                            width: 165,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── App name ─────────────────────────────────────────────────
                FadeTransition(
                  opacity: _textOpacity,
                  child: const Text(
                    'LH INVOICE',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 5.5,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Gold underline that draws outward ─────────────────────────
                AnimatedBuilder(
                  animation: _underlineWidth,
                  builder: (_, __) => SizedBox(
                    width: 140,
                    child: Center(
                      child: Container(
                        width: 140 * _underlineWidth.value,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _gold.withAlpha(180),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Loading label (animated dots) ─────────────────────────────
                FadeTransition(
                  opacity: _textOpacity,
                  child: AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (_, __) => Text(
                      _dotsText,
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 11,
                        letterSpacing: 3.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Gold progress bar ─────────────────────────────────────────
                FadeTransition(
                  opacity: _textOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AnimatedBuilder(
                      animation:
                          Listenable.merge([_progressCtrl, _shimmerCtrl]),
                      builder: (_, __) => _GoldBar(
                        progress: CurvedAnimation(
                          parent: _progressCtrl,
                          curve: Curves.easeInOut,
                        ).value,
                        shimmer: _shimmerCtrl.value,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gold progress bar ─────────────────────────────────────────────────────────

class _GoldBar extends StatelessWidget {
  final double progress;
  final double shimmer;

  const _GoldBar({required this.progress, required this.shimmer});

  static const _gold    = Color(0xFFD4AF37);
  static const _goldTop = Color(0xFFFFF8D6);
  static const _goldBot = Color(0xFF7A5700);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.black.withAlpha(90),
        border: Border.all(
          color: _gold.withAlpha(90),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withAlpha((30 + (80 * progress)).round()),
            blurRadius: 28,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: _gold.withAlpha((10 + (30 * progress)).round()),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [

            // Gold gradient fill
            FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_goldTop, _gold, _goldBot],
                    stops: [0.0, 0.40, 1.0],
                  ),
                ),
              ),
            ),

            // Diagonal stripe texture
            if (progress > 0.03)
              FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: ClipRect(
                  child: CustomPaint(painter: _StripePainter()),
                ),
              ),

            // Shimmer light sweep
            if (progress > 0.03)
              FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.25,
                  alignment: Alignment(shimmer * 2 - 1, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withAlpha(0),
                          Colors.white.withAlpha(80),
                          Colors.white.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Top gloss highlight (thin bright strip along the top edge)
            FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(0),
                        Colors.white.withAlpha(100),
                        Colors.white.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ── Diagonal stripe texture ───────────────────────────────────────────────────

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = Colors.white.withAlpha(16)
      ..strokeWidth = 5.0
      ..style       = PaintingStyle.stroke;

    const spacing = 12.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter _) => false;
}

// ── Dual background glow ──────────────────────────────────────────────────────

class _DualGlowPainter extends CustomPainter {
  final double logoGlow;
  final double barGlow;
  _DualGlowPainter({required this.logoGlow, required this.barGlow});

  @override
  void paint(Canvas canvas, Size size) {
    // Glow behind logo (upper-center)
    final logoPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.25),
        radius: 0.55,
        colors: [
          const Color(0xFFD4AF37).withAlpha((18 * logoGlow).round()),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), logoPaint);

    // Glow behind progress bar (lower-center)
    final barPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.75),
        radius: 0.65,
        colors: [
          const Color(0xFFD4AF37).withAlpha((12 + (22 * barGlow)).round()),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), barPaint);
  }

  @override
  bool shouldRepaint(_DualGlowPainter old) =>
      old.logoGlow != logoGlow || old.barGlow != barGlow;
}
