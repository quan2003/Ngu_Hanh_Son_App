import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 33.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Logo Bác Hồ + Cờ Đảng
                Image.asset(
                  'assets/images/bac-ho.png',
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                ),

                // Title & Subtitle
                Column(
                  children: const [
                    Text(
                      'ĐẢNG BỘ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFCEC62A),
                        fontSize: 22,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'PHƯỜNG NGŨ HÀNH SƠN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFCEC62A),
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // Description
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Ứng dụng trung tâm dữ liệu Đảng bộ phường Ngũ Hành Sơn thể hiện thông tin và cung cấp các tiện ích trong công tác hoạt động quản lý cơ sở đảng, đảng viên trên nền tảng số.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),

                // Buttons
                Column(
                  children: [
                    // Đăng nhập Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => context.go(AppConstants.loginRoute),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBC0D0D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 22,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Đăng ký Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => context.go(AppConstants.registerRoute),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBC0D0D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Đăng ký',
                          style: TextStyle(
                            fontSize: 22,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Footer
                Column(
                  children: [
                    // Hotline
                    TextButton(
                      onPressed: () => _launchPhone(AppConstants.hotline),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Hotline hỗ trợ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const TextSpan(
                              text: ': ',
                              style: TextStyle(
                                color: Color(0xFFC0B2B2),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text: AppConstants.hotline,
                              style: const TextStyle(
                                color: Color(0xFFE32929),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Privacy Policy
                    TextButton(
                      onPressed: () =>
                          _launchUrl(AppConstants.privacyPolicyUrl),
                      child: const Text(
                        'Chính sách quyền riêng tư',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    // Version
                    Text(
                      'Phiên bản ${AppConstants.appVersion}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE4CDCD),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
