import 'package:flutter/material.dart';
import 'package:btl/features/home/presentation/pages/home_page.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});

  static const String routeName = '/login';
  final AuthController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _forgotPasswordEmailController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _forgotPasswordEmailController.dispose();
    super.dispose();
  }

  String _humanizeError(String raw) {
    final lowerRaw = raw.toLowerCase();
    if (lowerRaw.contains('invalid-credential') || 
        lowerRaw.contains('user-not-found') || 
        lowerRaw.contains('wrong-password') ||
        lowerRaw.contains('invalid-email')) {
      return 'Tài khoản hoặc mật khẩu không chính xác';
    }
    if (raw.contains('email-already-in-use')) {
      return 'Email này đã được đăng ký bởi người khác';
    }
    if (raw.contains('network-request-failed')) {
      return 'Lỗi kết nối mạng, vui lòng thử lại';
    }
    if (raw.contains('too-many-requests')) {
      return 'Quá nhiều lần thử sai. Vui lòng quay lại sau ít phút';
    }

    final text = raw.trim();
    if (text.startsWith('Exception:')) {
      return text.replaceFirst('Exception:', '').trim();
    }
    return text;
  }

  Future<void> _showForgotPasswordDialog() async {
    _forgotPasswordEmailController.text = _emailController.text.trim();
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Quên mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nhập email để nhận link đặt lại mật khẩu.'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _forgotPasswordEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  if (localError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(localError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () async {
                    final email = _forgotPasswordEmailController.text.trim();
                    if (email.isEmpty) {
                      setDialogState(() => localError = 'Vui lòng nhập email');
                      return;
                    }
                    final ok = await widget.controller.sendPasswordResetEmail(email);
                    if (!context.mounted) return;
                    if (ok) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi email thành công!')));
                    } else {
                      setDialogState(() => localError = _humanizeError(widget.controller.error ?? 'Lỗi'));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: const Text('Gửi link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRegisterMode) {
      final success = await widget.controller.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _displayNameController.text.trim(),
      );
      if (success && mounted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
        );
        setState(() {
          _isRegisterMode = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } else {
      await widget.controller.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        rememberMe: _rememberMe,
      );
      if (mounted) {
        if (widget.controller.isLoggedIn) {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacementNamed(HomePage.routeName);
        } else {
          // Bắt buộc gọi setState để hiển thị lỗi đã được humanize
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Decor
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.indigo[800]!, Colors.indigo[500]!],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 60,
                    left: 20,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: const Icon(Icons.school_rounded, size: 60, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'EduCode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isRegisterMode ? 'Tạo tài khoản mới' : 'Chào mừng trở lại!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDarkMode ? Colors.white : Colors.indigo[900],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegisterMode ? 'Bắt đầu hành trình học tập ngay.' : 'Đăng nhập để tiếp tục việc học.',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Email
                        _buildInputField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          isDarkMode: isDarkMode,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(v)) return 'Email không đúng định dạng';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password
                        _buildInputField(
                          controller: _passwordController,
                          label: 'Mật khẩu',
                          icon: Icons.lock_outline_rounded,
                          isDarkMode: isDarkMode,
                          isPassword: true,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                            if (_isRegisterMode) {
                              if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                              if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(v)) {
                                return 'Mật khẩu cần có cả chữ và số';
                              }
                            }
                            return null;
                          },
                        ),

                        // Confirm Password (Only for Register)
                        if (_isRegisterMode) ...[
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: _confirmPasswordController,
                            label: 'Xác nhận mật khẩu',
                            icon: Icons.lock_reset_rounded,
                            isDarkMode: isDarkMode,
                            isPassword: true,
                            obscure: _obscurePassword,
                            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (v) {
                              if (v != _passwordController.text) return 'Mật khẩu không khớp';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: _displayNameController,
                            label: 'Họ và tên',
                            icon: Icons.person_outline_rounded,
                            isDarkMode: isDarkMode,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Vui lòng nhập họ tên';
                              if (v.trim().split(' ').length < 2) return 'Vui lòng nhập đầy đủ họ và tên';
                              if (RegExp(r'[0-9!@#<>?":_`~;[\]\\|=+)(*&^%$-]').hasMatch(v)) return 'Tên không lệ';
                              return null;
                            },
                          ),
                        ],

                        // Extra Options for Login (Remember Me)
                        if (!_isRegisterMode) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                      activeColor: Colors.indigo,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Nhớ tôi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: Text('Quên mật khẩu?', style: TextStyle(color: Colors.indigo[700], fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: widget.controller.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: widget.controller.isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _isRegisterMode ? 'ĐĂNG KÝ NGAY' : 'ĐĂNG NHẬP',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Toggle Mode
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isRegisterMode ? 'Đã có tài khoản?' : 'Chưa có tài khoản?',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isRegisterMode = !_isRegisterMode;
                                  _formKey.currentState?.reset();
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  _displayNameController.clear();
                                });
                              },
                              child: Text(
                                _isRegisterMode ? ' Đăng nhập' : ' Đăng ký',
                                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        // Error message
                        if (widget.controller.error != null)
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                            ),
                            child: Text(
                              _humanizeError(widget.controller.error!),
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: Colors.indigo[400], size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey[400]),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: isDarkMode ? Colors.black26 : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}



