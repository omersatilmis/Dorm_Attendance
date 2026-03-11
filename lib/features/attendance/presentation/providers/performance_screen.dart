import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yurt_yoklama/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:yurt_yoklama/features/management/presentation/providers/management_provider.dart';
import 'package:yurt_yoklama/features/auth/presentation/providers/auth_provider.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _coursesData = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPerformanceData();
    });
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);

    final management = context.read<ManagementProvider>();
    final attendance = context.read<AttendanceProvider>();
    final auth = context.read<AuthProvider>();

    await management.loadClassGroups();
    final groups = management.groups ?? [];

    final teacherProfile = auth.userProfile;
    final myGroups = auth.isAnyAdmin
        ? groups
        : groups.where((g) {
          final profileId = teacherProfile?['id']?.toString();
          final groupTeacherId = g.teacherId?.toString();
          return groupTeacherId == profileId;
        }).toList();

    final data = await attendance.loadAllPerformanceData(myGroups);

    if (mounted) {
      setState(() {
        _coursesData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "📊 Öğrenci performansları",
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coursesData.isEmpty
          ? const Center(
              child: Text("Sorumlu olduğunuz sınıf/öğrenci bulunmuyor."),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              itemCount: _coursesData.length,
              itemBuilder: (context, index) {
                return CoursePerformanceCard(courseData: _coursesData[index]);
              },
            ),
    );
  }
}

/* ---------- 🎓 Ders Grubu Kartı ---------- */
class CoursePerformanceCard extends StatelessWidget {
  final Map<String, dynamic> courseData;

  const CoursePerformanceCard({super.key, required this.courseData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final px = constraints.maxWidth;
          // Ekran genişliğine göre kolon genişliklerini ayarlıyoruz (Kotlin'deki mantık)
          final weeklyW = (px * 0.14).clamp(40.0, 64.0);
          final monthlyW = (px * 0.13).clamp(38.0, 56.0);
          final allW = (px * 0.13).clamp(38.0, 56.0);

          final group = courseData['group'];
          final students = courseData['students'] as List<dynamic>;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BAŞLIK
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    "${_toProperCase(group.name)} — ${_toProperCase(group.teacher?.fullName ?? 'Bilinmiyor')}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),

                // TABLO BAŞLIKLARI
                Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Öğrenci",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: weeklyW,
                        child: const Text(
                          "Haftalık",
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: monthlyW,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            "Aylık",
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: allW,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 2),
                          child: Text(
                            "Tüm",
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9333EA),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // ÖĞRENCİ LİSTESİ
                if (students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        "Henüz öğrenci yok.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...students.asMap().entries.map((entry) {
                    final index = entry.key;
                    final student = entry.value;

                    final weekly = student['weekly'] as double;
                    final monthly = student['monthly'] as double;
                    final all = student['all'] as double;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${index + 1}. ${_toProperCase(student['name'])}",
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: weeklyW,
                                child: Text(
                                  "${weekly.toStringAsFixed(1)}%",
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: monthlyW,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    "${monthly.toStringAsFixed(1)}%",
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: allW,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Text(
                                    "${all.toStringAsFixed(1)}%",
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF9333EA),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          thickness: 0.5,
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.22),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- 🔤 Proper Case (Türkçe’ye uygun) Dart Versiyonu ----------
  String _toProperCase(String text) {
    if (text.isEmpty) return text;
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
