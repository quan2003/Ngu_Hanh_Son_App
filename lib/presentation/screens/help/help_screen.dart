import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  int? _expandedIndex;

  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'Làm thế nào để đăng ký tài khoản?',
      answer:
          'Bạn có thể đăng ký tài khoản bằng cách nhấn vào nút "Đăng ký" trên màn hình chào mừng, sau đó điền đầy đủ thông tin email và mật khẩu. Hệ thống sẽ gửi email xác nhận đến địa chỉ email của bạn.',
    ),
    FAQItem(
      question: 'Tôi quên mật khẩu, phải làm sao?',
      answer:
          'Trên màn hình đăng nhập, nhấn vào "Quên mật khẩu". Nhập địa chỉ email đã đăng ký, hệ thống sẽ gửi link đặt lại mật khẩu đến email của bạn.',
    ),
    FAQItem(
      question: 'Làm thế nào để xem danh sách tổ chức đảng?',
      answer:
          'Từ màn hình chính, chọn tab "Đảng Bộ" để xem danh sách các tổ chức đảng. Bạn có thể nhấn vào từng tổ chức để xem thông tin chi tiết.',
    ),
    FAQItem(
      question: 'Làm thế nào để sử dụng bản đồ?',
      answer:
          'Chọn tab "Bản đồ" trên thanh điều hướng. Bạn có thể phóng to, thu nhỏ và di chuyển bản đồ để xem các khu vực khác nhau. Nhấn vào các điểm đánh dấu để xem thông tin chi tiết.',
    ),
    FAQItem(
      question: 'Làm thế nào để gửi góp ý?',
      answer:
          'Chọn tab "Góp ý" trên thanh điều hướng, sau đó nhập nội dung góp ý của bạn và nhấn "Gửi". Chúng tôi sẽ xem xét và phản hồi trong thời gian sớm nhất.',
    ),
    FAQItem(
      question: 'Quyền của quản trị viên là gì?',
      answer:
          'Quản trị viên có thể quản lý người dùng, thêm/sửa/xóa dữ liệu tổ chức đảng, xem thống kê hệ thống, và quản lý góp ý từ người dùng.',
    ),
    FAQItem(
      question: 'Làm thế nào để cập nhật thông tin cá nhân?',
      answer:
          'Mở menu bên trái, chọn "Thông tin cá nhân", sau đó nhấn nút chỉnh sửa để cập nhật tên hiển thị và các thông tin khác.',
    ),
    FAQItem(
      question: 'Ứng dụng có hỗ trợ chế độ ngoại tuyến không?',
      answer:
          'Hiện tại ứng dụng yêu cầu kết nối internet để truy cập dữ liệu. Tính năng ngoại tuyến đang được phát triển và sẽ có trong các phiên bản tiếp theo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ giúp'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search section (placeholder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.grey600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tìm kiếm trợ giúp...',
                    style: TextStyle(
                      color: AppColors.grey600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick actions
          _buildSectionTitle('Hỗ trợ nhanh'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.phone_outlined,
                  title: 'Gọi hotline',
                  color: AppColors.success,
                  onTap: () => _makePhoneCall('1900123456'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.email_outlined,
                  title: 'Gửi email',
                  color: AppColors.info,
                  onTap: () => _sendEmail(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // FAQs Section
          _buildSectionTitle('Câu hỏi thường gặp'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(_faqs.length, (index) {
                final isFirst = index == 0;
                final isLast = index == _faqs.length - 1;
                final isExpanded = _expandedIndex == index;

                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedIndex = isExpanded ? null : index;
                        });
                      },
                      borderRadius: BorderRadius.vertical(
                        top: isFirst ? const Radius.circular(12) : Radius.zero,
                        bottom:
                            isLast ? const Radius.circular(12) : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _faqs[index].question,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isExpanded
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: isExpanded
                                      ? AppColors.primary
                                      : AppColors.grey600,
                                ),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 12),
                              Text(
                                _faqs[index].answer,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grey700,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Contact section
          _buildSectionTitle('Liên hệ hỗ trợ'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primaryDark.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cần thêm trợ giúp?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Liên hệ với chúng tôi',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildContactItem(
                  icon: Icons.phone,
                  title: 'Hotline',
                  value: '1900 123 456',
                  onTap: () => _makePhoneCall('1900123456'),
                ),
                const SizedBox(height: 12),
                _buildContactItem(
                  icon: Icons.email,
                  title: 'Email',
                  value: 'support@nguhanhson.vn',
                  onTap: () => _sendEmail(),
                ),
                const SizedBox(height: 12),
                _buildContactItem(
                  icon: Icons.location_on,
                  title: 'Địa chỉ',
                  value: 'Phường Ngũ Hành Sơn, Đà Nẵng',
                  onTap: null,
                ),
                const SizedBox(height: 12),
                _buildContactItem(
                  icon: Icons.access_time,
                  title: 'Giờ làm việc',
                  value: 'T2-T6: 7:00 - 17:00',
                  onTap: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Feedback button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to feedback tab
                // This would need to be implemented based on your navigation structure
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.feedback_outlined),
              label: const Text(
                'Gửi góp ý',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.grey600,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          await Clipboard.setData(ClipboardData(text: phoneNumber));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã sao chép số điện thoại'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _sendEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@nguhanhson.vn',
      query: 'subject=Trợ giúp ứng dụng&body=',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          await Clipboard.setData(
            const ClipboardData(text: 'support@nguhanhson.vn'),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã sao chép địa chỉ email'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
