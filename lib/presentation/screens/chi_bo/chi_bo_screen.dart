import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/chi_bo_repository.dart';
import '../../../domain/entities/to_chuc_dang.dart';

class ChiBoScreen extends StatefulWidget {
  const ChiBoScreen({super.key});

  @override
  State<ChiBoScreen> createState() => _ChiBoScreenState();
}

class _ChiBoScreenState extends State<ChiBoScreen> {
  final ChiBoRepository _repository = ChiBoRepository();
  List<ToChucDang> _chiBoList = [];
  List<ToChucDang> _filteredList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Debug: Check all documents
      await _repository.debugAllDocuments();

      final data = await _repository.getAllChiBo();
      print('🎯 Loaded ${data.length} Chi Bộ records');

      setState(() {
        _chiBoList = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error in _loadData: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<ToChucDang> filtered = _chiBoList;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((cb) =>
              cb.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (cb.secretary.isNotEmpty &&
                  cb.secretary
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())) ||
              (cb.officerInCharge.isNotEmpty &&
                  cb.officerInCharge
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())))
          .toList();
    }

    setState(() => _filteredList = filtered);
  }

  // Make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thực hiện cuộc gọi')),
        );
      }
    }
  }

  // Open Google Maps search (similar to map_screen.dart but using search since we don't have exact coordinates)
  Future<void> _openMaps(String chiBoName) async {
    try {
      // Build search query with location context for better results
      final searchQuery = '$chiBoName, Đà Nẵng, Việt Nam';

      // Try to get current position first
      Position? currentPos;
      try {
        currentPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint('⚠️ Could not get current position: $e');
      }

      // If we have current position, use directions API, otherwise use search
      Uri url;
      if (currentPos != null) {
        // Use directions with search query as destination
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=${currentPos.latitude},${currentPos.longitude}&destination=${Uri.encodeComponent(searchQuery)}&travelmode=driving',
        );
      } else {
        // Fallback to search
        url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(searchQuery)}',
        );
      }

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Không thể mở Google Maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở bản đồ: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Danh sách Chi Bộ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          if (!_isLoading && _chiBoList.isNotEmpty) _buildStatisticsCard(),

          // Search Bar
          _buildSearchBar(),

          // Chi Bo List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final chiBo = _filteredList[index];
                            return _buildChiBoCard(chiBo, index);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tính năng dành cho quản trị viên')),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textLight),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final withSecretary =
        _chiBoList.where((cb) => cb.secretary.isNotEmpty).length;
    final withOfficer =
        _chiBoList.where((cb) => cb.officerInCharge.isNotEmpty).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              Icons.groups,
              'Tổng Chi bộ',
              '${_chiBoList.length}',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              Icons.person_outline,
              'Có Bí thư',
              '$withSecretary',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              Icons.badge_outlined,
              'Có Ủy viên',
              '$withOfficer',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 26),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm chi bộ, bí thư, ủy viên...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.grey400),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Không có chi bộ nào'
                : 'Không tìm thấy chi bộ',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                _applyFilters();
              },
              child: const Text('Xóa tìm kiếm'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChiBoCard(ToChucDang chiBo, int index) {
    final hasContact =
        chiBo.secretaryPhone.isNotEmpty || chiBo.officerPhone.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showChiBoDetail(chiBo),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon with gradient background
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.05)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chiBo.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chiBo.type,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.grey400,
                  ),
                ],
              ),

              if (chiBo.secretary.isNotEmpty ||
                  chiBo.officerInCharge.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Contact Information
                if (chiBo.secretary.isNotEmpty)
                  _buildContactRow(
                    Icons.person,
                    'Bí thư',
                    chiBo.secretary,
                    chiBo.secretaryPhone,
                  ),

                if (chiBo.officerInCharge.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildContactRow(
                      Icons.badge,
                      chiBo.officerPosition.isNotEmpty
                          ? chiBo.officerPosition
                          : 'Ủy viên',
                      chiBo.officerInCharge,
                      chiBo.officerPhone,
                    ),
                  ),
              ],

              // Action buttons
              if (hasContact) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (chiBo.secretaryPhone.isNotEmpty ||
                        chiBo.officerPhone.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final phone = chiBo.secretaryPhone.isNotEmpty
                                ? chiBo.secretaryPhone
                                : chiBo.officerPhone;
                            _makePhoneCall(phone);
                          },
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Gọi'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openMaps(chiBo.name),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Chỉ đường'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.info,
                          side: const BorderSide(color: AppColors.info),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(
      IconData icon, String label, String name, String phone) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (phone.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_android,
                  size: 12,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showChiBoDetail(ToChucDang chiBo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with gradient
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chiBo.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chiBo.type,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin lãnh đạo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (chiBo.secretary.isNotEmpty)
                      _buildDetailRow(
                        Icons.person,
                        'Bí thư',
                        chiBo.secretary,
                        chiBo.secretaryPhone,
                        AppColors.primary,
                      ),

                    if (chiBo.officerInCharge.isNotEmpty)
                      _buildDetailRow(
                        Icons.badge,
                        chiBo.officerPosition.isNotEmpty
                            ? chiBo.officerPosition
                            : 'Ủy viên phụ trách',
                        chiBo.officerInCharge,
                        chiBo.officerPhone,
                        AppColors.info,
                      ),

                    if (chiBo.secretary.isEmpty &&
                        chiBo.officerInCharge.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppColors.textSecondary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Chưa có thông tin lãnh đạo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _openMaps(chiBo.name);
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Chỉ đường'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.info,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (chiBo.secretaryPhone.isNotEmpty ||
                            chiBo.officerPhone.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                final phone = chiBo.secretaryPhone.isNotEmpty
                                    ? chiBo.secretaryPhone
                                    : chiBo.officerPhone;
                                _makePhoneCall(phone);
                              },
                              icon: const Icon(Icons.phone),
                              label: const Text('Gọi điện'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String name, String phone, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.phone_android,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _makePhoneCall(phone),
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Gọi'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
