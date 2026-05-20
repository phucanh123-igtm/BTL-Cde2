import 'package:flutter/material.dart';

class IntroductionPage extends StatelessWidget {
  const IntroductionPage({super.key});

  static const String routeName = '/introduction';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text('Giới thiệu', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF1A237E), const Color(0xFF121212)]
                : [Colors.indigo.shade800, Colors.grey.shade50],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, size: 80, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Về EduCode',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.indigo.shade300 : Colors.indigo.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'EduCode là một nền tảng học tập trực tuyến hiện đại, được thiết kế đặc biệt để giúp sinh viên và những người mới bắt đầu tiếp cận với lập trình một cách dễ dàng và hiệu quả nhất.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'Tính năng nổi bật',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.indigo.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureSection(
                context,
                icon: Icons.psychology_rounded,
                title: 'Tích hợp AI',
                description: 'Sử dụng trí tuệ nhân tạo để cá nhân hóa lộ trình học tập và giải đáp thắc mắc tức thì.',
                color: Colors.blue,
              ),
              _buildFeatureSection(
                context,
                icon: Icons.quiz_rounded,
                title: 'Học qua thực hành',
                description: 'Hệ thống bài tập Quiz đa dạng và các dự án thực tế giúp củng cố kiến thức vững chắc.',
                color: Colors.orange,
              ),
              _buildFeatureSection(
                context,
                icon: Icons.devices_rounded,
                title: 'Mọi lúc mọi nơi',
                description: 'Truy cập nội dung học tập trên nhiều thiết bị, giúp bạn chủ động thời gian của mình.',
                color: Colors.green,
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Phiên bản 1.0.0',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



