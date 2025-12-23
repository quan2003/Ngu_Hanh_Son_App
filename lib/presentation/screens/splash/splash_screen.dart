import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Bóng đen từ trên rớt xuống
  late Animation<double> _darkVeilOpacity;
  late Animation<double> _darkVeilPosition;

  // Frame 42-43: Bóng mờ xuất hiện
  late Animation<double> _shadowOpacity;

  // Frame 43-44: Logo fade-in và trồi lên
  late Animation<double> _logoOpacity;
  late Animation<double> _logoPosition; // Di chuyển từ dưới lên

  // Frame 44-46: Logo scale từ nhỏ → lớn → chuẩn
  late Animation<double> _logoScale;

  // Frame 46-47: Text hiện lên
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // Animation thời gian: 2.5 giây (rút ngắn từ 3.0s)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Giai đoạn 0: Bóng đen từ trên rớt xuống (0 - 0.3s)
    _darkVeilOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.1, curve: Curves.easeIn),
      ),
    );

    _darkVeilPosition = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.1, curve: Curves.easeOutCubic),
      ),
    );

    // Giai đoạn 1: Bóng xuất hiện (0 - 0.4s = 0.0 - 0.133)
    _shadowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.133, curve: Curves.linear),
      ),
    );

    // Giai đoạn 2: Logo fade-in (0.4 - 1.2s = 0.133 - 0.4)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.133, 0.4, curve: Curves.easeIn),
      ),
    );

    // Giai đoạn 2: Logo trồi lên từ dưới (0.4 - 1.2s)
    _logoPosition = Tween<double>(begin: 120.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.133, 0.4, curve: Curves.fastOutSlowIn),
      ),
    );

    // Giai đoạn 2-3: Logo scale (0.4 - 2.0s = 0.133 - 0.667)
    // Scale từ 0.3 → 1.1 → 1.0 (ease-out)
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.133, 0.667, curve: Curves.linear),
      ),
    );

    // Giai đoạn 4: Text hiện lên (2.0 - 2.6s = 0.667 - 0.867)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.667, 0.867, curve: Curves.easeInOut),
      ),
    );

    // Bắt đầu animation
    _controller.forward();

    // Navigate với logic thông minh
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // Chờ animation hoàn thành
    await Future.delayed(AppConstants.splashDuration);

    if (!mounted) return;

    // Kiểm tra trạng thái auth
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Chưa đăng nhập -> Welcome
      context.go(AppConstants.welcomeRoute);
    } else if (!user.emailVerified) {
      // Đã đăng nhập nhưng chưa verify
      context.go(AppConstants.emailVerificationRoute);
    } else {
      // Đã đăng nhập và verify -> Home
      context.go(AppConstants.homeRoute);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C), // Nền #0D102C theo Figma
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Giai đoạn 0: Bóng đen từ trên rớt xuống (Dark Veil)
              Positioned(
                top: MediaQuery.of(context).size.height *
                    _darkVeilPosition.value,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _darkVeilOpacity.value *
                      (1 - _logoOpacity.value).clamp(0.0, 1.0),
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Giai đoạn 1: Bóng oval xuất hiện rồi mờ dần
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.50,
                left: MediaQuery.of(context).size.width * 0.5 - 124,
                child: Opacity(
                  // Bóng xuất hiện (0-0.4s) rồi mờ dần khi logo scale lên (0.4-2.0s)
                  opacity: (_shadowOpacity.value * (1.5 - _logoScale.value))
                      .clamp(0.0, 1.0),
                  child: Container(
                    width: 248,
                    height: 97,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(124),
                      color: const Color(0xFF02051E),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF02051E).withOpacity(0.8),
                          blurRadius: 50,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Giai đoạn 2-3: Logo búa liềm trồi lên từ bóng (GIỮ GIỮ MÀN HÌNH)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Transform.translate(
                      offset: Offset(0, _logoPosition.value),
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red
                                      .withOpacity(0.4 * _logoOpacity.value),
                                  blurRadius: 50,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/co-dang.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Giai đoạn 4: Text xuất hiện BÊN DƯỚI logo
                    Transform.translate(
                      // Slide-up nhẹ từ +40px → 0
                      offset: Offset(0, 40 * (1 - _textOpacity.value)),
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            const Text(
                              'PHƯỜNG NGŨ HÀNH SƠN',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TRUNG TÂM DỮ LIỆU ĐẢNG BỘ',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.8),
                                letterSpacing: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Loading indicator và version (luôn hiển thị)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFD700), // Vàng sao
                        ),
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      AppConstants.appVersion,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
