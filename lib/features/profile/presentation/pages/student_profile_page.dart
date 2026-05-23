import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/admin/presentation/pages/admin_dashboard_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key, required this.controller});

  static const String routeName = '/student-profile';
  final AuthController controller;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  late final TextEditingController _displayNameController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.controller.currentUser?.displayName ?? '',
    );
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _displayNameController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _saveProfile() async {
    await widget.controller.updateDisplayName(_displayNameController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật thông tin thành công'), backgroundColor: Colors.green),
    );
  }

  Future<void> _changeAvatar() async {
    if (_isUploadingAvatar || widget.controller.isLoading) return;
    final userId = widget.controller.currentUser?.id;
    if (userId == null) return;

    final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 400, maxHeight: 400);
    if (image == null || !mounted) return;

    // Crop the image before uploading
    final croppedImage = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt ảnh',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.original,
          ],
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.original,
          ],
          minimumAspectRatio: 1.0,
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    if (croppedImage == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await croppedImage.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await widget.controller.updateAvatarUrl(base64String);
      await widget.controller.reloadUserFromFirebase();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;

    ImageProvider? avatarImage;
    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      if (user.avatarUrl!.startsWith('data:image')) {
        try {
          final base64Data = user.avatarUrl!.split(',').last;
          avatarImage = MemoryImage(base64Decode(base64Data));
        } catch (_) {}
      } else {
        avatarImage = NetworkImage(user.avatarUrl!);
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sử dụng SliverAppBar để tiêu đề cuộn theo nội dung
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            elevation: 0,
            stretch: true,
            backgroundColor: Colors.indigo[600],
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                user?.displayName ?? 'Trang Cá Nhân',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[800]!, Colors.indigo[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 56,
                            backgroundImage: avatarImage,
                            backgroundColor: Colors.grey[200],
                            child: (avatarImage == null)
                                ? Text(
                                    (user?.displayName != null && user!.displayName.trim().isNotEmpty)
                                        ? user.displayName.trim()[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.indigo[400]),
                                  )
                                : null,
                          ),
                        ),
                        GestureDetector(
                          onTap: _changeAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: _isUploadingAvatar
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(Icons.camera_alt_rounded, size: 20, color: Colors.indigo[600]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Nội dung bên dưới
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Thông tin tài khoản'),
                  _buildInfoCard([
                    _infoRow('Email', user?.email ?? 'N/A'),
                    const Divider(height: 24),
                    _infoRow('Vai trò', user?.role.toUpperCase() ?? 'STUDENT'),
                    const Divider(height: 24),
                    _infoRow('Trạng thái', 'Đang hoạt động'),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Chỉnh sửa thông tin'),
                  _buildEditCard(),

                  if (user?.role == 'admin' || user?.email == 'admin@gmail.com') ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle('Quản trị'),
                    _buildAdminCard(context),
                  ],

                  if (widget.controller.error != null)
                    _buildErrorBox(widget.controller.error!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEditCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: 'Tên hiển thị',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: Colors.grey.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.controller.isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: widget.controller.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo[700]!, Colors.indigo[900]!]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () => Navigator.pushNamed(context, AdminDashboardPage.routeName),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.auto_graph_rounded, color: Colors.white)),
          title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          subtitle: Text('Quản lý hệ thống EduCode', style: TextStyle(color: Colors.white.withOpacity(0.7))),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String error) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(error, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

