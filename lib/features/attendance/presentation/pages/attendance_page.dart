import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yurt_yoklama/features/attendance/presentation/models/attendance_models.dart';
import 'package:yurt_yoklama/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:yurt_yoklama/features/management/presentation/providers/management_provider.dart';
import 'package:yurt_yoklama/features/auth/presentation/providers/auth_provider.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';
import 'package:yurt_yoklama/core/utils/snackbar_service.dart';
import 'package:yurt_yoklama/core/widgets/course_group_card.dart';
import 'package:go_router/go_router.dart';
import 'package:yurt_yoklama/app/app_routes.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String _checkType = "MORNING";
  bool _isLoading = false;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();
  bool _isDateExpanded = false;

  // View Mode
  DateTime? _viewModeDate;
  Map<String, String> _readOnlyStatusMap = {};

  final ScrollController _dateScrollController = ScrollController();

  // Birden fazla grubu tutacak yapı
  final List<GroupAttendanceModel> _selectedGroupsData = [];

  // Otomatik senkronizasyon takibi için
  int _lastQueueCount = 0;

  @override
  void initState() {
    super.initState();
    _lastQueueCount = context.read<AttendanceProvider>().offlineQueueCount;

    // Senkronizasyon bittiğinde sayfayı yenilemek için dinleyici ekle
    context.read<AttendanceProvider>().addListener(_onAttendanceProviderChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllGroupsWithStudents();
      // Gecikmeyi biraz artırdık ki liste tam render edilsin
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _dateScrollController.hasClients) {
          _dateScrollController.animateTo(
            _dateScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _onAttendanceProviderChange() {
    if (!mounted) return;
    final provider = context.read<AttendanceProvider>();
    final newCount = provider.offlineQueueCount;

    // Eğer kuyruk 0'a düştüyse (senkronizasyon bittiyse) ve bugün modundaysak sayfayı yenile
    if (_lastQueueCount > 0 && newCount == 0 && _viewModeDate == null) {
      _loadAllGroupsWithStudents();
    }
    _lastQueueCount = newCount;
  }

  @override
  void dispose() {
    context.read<AttendanceProvider>().removeListener(
      _onAttendanceProviderChange,
    );
    _dateScrollController.dispose();
    for (var g in _selectedGroupsData) {
      g.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAllGroupsWithStudents() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final management = context.read<ManagementProvider>();

    await management.loadClassGroups();
    if (!mounted) return;
    final groups = management.groups ?? [];

    final teacherProfile = auth.userProfile;

    // debugPrint("DEBUG: User Profile: $teacherProfile");
    // debugPrint("DEBUG: Is Any Admin: ${auth.isAnyAdmin}");

    final myGroups = auth.isAnyAdmin
        ? groups
        : groups.where((g) {
          // teacherProfile['id'] is UUID, g.teacherId is also UUID string
          final profileId = teacherProfile?['id']?.toString();
          final groupTeacherId = g.teacherId?.toString();
          // debugPrint("DEBUG: Checking group ${g.name}: groupTeacherId=$groupTeacherId, profileId=$profileId");
          return groupTeacherId == profileId;
        }).toList();

    // Öncekileri temizle (dispose önemli)
    for (var g in _selectedGroupsData) {
      g.dispose();
    }
    _selectedGroupsData.clear();

    // Veritabanındaki (veya cache'deki) mevcut kayıtları çek
    final attendanceProv = context.read<AttendanceProvider>();
    final existingStatuses = await attendanceProv.getAttendanceRecords(
      date: _selectedDate,
      checkType: _checkType,
    );

    // Tüm grupların öğrencilerini PARALEL olarak çek (Future.wait)
    final futures = myGroups.map((group) async {
      await management.loadStudentsForGroup(group.id);
      final students = management.getStudentsForGroup(group.id) ?? [];

      final studentModels = students.map((s) {
        final savedStatus = existingStatuses[s.id];
        String initialStatus = 'UNSET';

        if (savedStatus != null) {
          initialStatus = savedStatus.toUpperCase(); // 'present' -> 'PRESENT'
        }

        return StudentAttendanceModel(
          id: s.id,
          fullName: s.fullName,
          initialStatus: initialStatus,
        );
      }).toList();
      return GroupAttendanceModel(group: group, students: studentModels);
    });

    final results = await Future.wait(futures);
    _selectedGroupsData.addAll(results);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAll() async {
    if (_selectedGroupsData.isEmpty) return;

    setState(() => _isSaving = true);

    final provider = context.read<AttendanceProvider>();
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.userProfile?['id'];

    final existingIds = await provider.getAttendanceRecordIds(
      date: _selectedDate,
      checkType: _checkType,
    );

    if (!mounted) {
      setState(() => _isSaving = false);
      return;
    }

    // Toplu veri setini hazırla
    final List<Map<String, dynamic>> records = [];
    final dateStr = _selectedDate.toIso8601String().split('T')[0];

    for (var groupData in _selectedGroupsData) {
      final groupId = groupData.group.id;
      for (var student in groupData.students) {
        if (student.status == 'UNSET') continue;

        final status = student.status == 'PRESENT'
            ? 'present'
            : student.status == 'EXCUSED'
            ? 'excused'
            : 'absent';

        final record = <String, dynamic>{
          'student_id': student.id,
          'group_id': groupId,
          'status': status,
          'attendance_date': dateStr,
          'check_type': _checkType.toLowerCase(), // 'morning' or 'night'
        };

        // Eğer bu kayıt önceden varsa (ID'si varsa), ID'yi de ekle ki UPDATE (Upsert) yapsın
        final existingId = existingIds[student.id];
        if (existingId != null) {
          record['id'] = existingId;
        }

        if (currentUserId != null) {
          record['recorded_by'] = currentUserId;
        }
        records.add(record);
      }
    }

    if (records.isEmpty) {
      setState(() => _isSaving = false);
      return;
    }

    if (!mounted) return;

    // TEK BİR İSTEKLE GÖNDER! (BATCH SAVE)
    final success = await context
        .read<AttendanceProvider>()
        .saveBatchAttendance(records);
    final totalCount = records.length;
    final successCount = success ? totalCount : 0;

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (successCount == totalCount && totalCount > 0) {
      SnackbarService.showSuccess(
        context,
        '$successCount / $totalCount yoklama kaydedildi ✅',
      );
    } else if (successCount > 0) {
      SnackbarService.showInfo(
        context,
        '$successCount / $totalCount yoklama kaydedildi ⚠️',
      );
    } else {
      SnackbarService.showError(context, 'Yoklama kaydedilemedi');
    }
  }

  // Removed _fetchPastAttendance - it's handled by _loadAllGroupsWithStudents correctly
  Future<void> _fetchPastAttendance() async {
    if (_viewModeDate == null) return;

    final provider = context.read<AttendanceProvider>();
    final statusMap = await provider.getAttendanceRecords(
      date: _viewModeDate!,
      checkType: _checkType,
    );

    if (mounted) {
      setState(() {
        _readOnlyStatusMap = statusMap;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userName = auth.userProfile?['full_name'] ?? 'Bilinmiyor';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Yoklama Paneli",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "Yoklamayı Alan: $userName",
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AttendanceProvider>(
            builder: (context, attendance, child) {
              if (attendance.offlineQueueCount > 0) {
                return IconButton(
                  icon: const Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.orange,
                  ),
                  tooltip:
                      '${attendance.offlineQueueCount} Yoklamayı Senkronize Et',
                  onPressed: () async {
                    final success = await attendance.syncOfflineAttendances();
                    if (context.mounted) {
                      if (success) {
                        SnackbarService.showSuccess(
                          context,
                          'Tüm yoklamalar senkronize edildi!',
                        );
                      } else {
                        SnackbarService.showError(
                          context,
                          'Senkronizasyon başarısız oldu.',
                        );
                      }
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Geçmiş & Performans',
            onPressed: () {
              context.go(AppRoutes.attendancePerformance);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive padding: daha geniş görünüm için paddingleri azalttık
          final horizontalPadding = constraints.maxWidth < 360
              ? 8.0
              : constraints.maxWidth > 600
              ? 16.0
              : 12.0;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // GECMIS TARIHLER SCROLL
                _buildPastDaysList(),
                const SizedBox(height: 12),

                // TARİH SEÇİMİ (Yalnızca Kayıt Modunda)
                if (_viewModeDate == null) ...[
                  _buildDateSelector(),
                  const SizedBox(height: 12),
                ],

                // SABAH - YAT YOKLAMASI FİLTRE ÇİPLERİ
                Row(
                  children: [
                    _buildFilterChip(
                      label: "Sabah Yoklaması",
                      icon: Icons.wb_sunny_outlined,
                      isSelected: _checkType == "MORNING",
                      onTap: () {
                        setState(() => _checkType = "MORNING");
                        if (_viewModeDate != null) {
                          _fetchPastAttendance();
                        } else {
                          _loadAllGroupsWithStudents();
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildFilterChip(
                      label: "Yat Yoklaması",
                      icon: Icons.nightlight_outlined,
                      isSelected: _checkType == "NIGHT",
                      onTap: () {
                        setState(() => _checkType = "NIGHT");
                        if (_viewModeDate != null) {
                          _fetchPastAttendance();
                        } else {
                          _loadAllGroupsWithStudents();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: AppColors.darkSurfaceContainer.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),

                // KARTLARIN LİSTESİ
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : _selectedGroupsData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group_off_outlined,
                                size: 64,
                                color: AppColors.darkTextSecondary.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Sorumlu olduğunuz bir ders grubu yok',
                                style: TextStyle(
                                  color: AppColors.darkTextSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _selectedGroupsData.length,
                          itemBuilder: (context, groupIndex) {
                            final data = _selectedGroupsData[groupIndex];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CourseGroupCard(
                                groupData: data,
                                isReadOnly: _viewModeDate != null,
                                readOnlyStatusMap: _readOnlyStatusMap,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),

      // ALTTAKİ BÜYÜK KAYDET BUTONU
      bottomNavigationBar:
          _selectedGroupsData.isNotEmpty && _viewModeDate == null
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.darkSurfaceContainer.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "KAYDET",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            )
          : null,
    );
  }

  // --- TÜRKÇE TARİH ---
  static const _turkishDays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  static const _turkishMonths = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  String _formatTurkishDate(DateTime date) {
    final day = date.day;
    final month = _turkishMonths[date.month];
    final weekday = _turkishDays[date.weekday - 1];
    return '$day $month $weekday';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatShortDate(DateTime date) {
    final day = date.day;
    final month = _turkishMonths[date.month].substring(0, 3);
    final weekday = _turkishDays[date.weekday - 1].substring(0, 3);
    return '$day $month $weekday';
  }

  Widget _buildPastDaysList() {
    final today = DateTime.now();
    // Son 14 günü oluştur (Eskiden yeniye doğru: 13 gün önce, 12 gün önce, ..., bugün)
    final pastDays = List.generate(
      14,
      (i) => today.subtract(Duration(days: 13 - i)),
    );

    return SizedBox(
      height: 44,
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          right: 32,
        ), // Son elementin tam görünmesi için sağ padding
        itemCount: pastDays.length,
        itemBuilder: (context, index) {
          final date = pastDays[index];
          // En sondaki eleman bugüne denk gelir (index == 13)
          final isToday = index == pastDays.length - 1;

          final isSelected = isToday
              ? _viewModeDate == null
              : _viewModeDate != null && _isSameDay(date, _viewModeDate!);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                isToday
                    ? "Bugün ${date.day} ${_turkishMonths[date.month].substring(0, 3)}"
                    : _formatShortDate(date),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.darkTextPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.darkSurfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  if (isToday) {
                    setState(() {
                      _viewModeDate = null;
                      _readOnlyStatusMap.clear();
                    });
                    _loadAllGroupsWithStudents();
                  } else {
                    setState(() {
                      _viewModeDate = date;
                    });
                    _fetchPastAttendance();
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    // ±2 gün listesi
    final dates = List.generate(5, (i) => today.add(Duration(days: i - 2)));

    return Column(
      children: [
        // Ana tarih satırı — tıklanabilir
        GestureDetector(
          onTap: () => setState(() => _isDateExpanded = !_isDateExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formatTurkishDate(_selectedDate),
                    style: const TextStyle(
                      color: AppColors.darkTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isDateExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.darkTextSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expand edilebilen tarih listesi
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkSurfaceContainer),
            ),
            child: Column(
              children: dates.map((date) {
                final isSelected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, today);
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _isDateExpanded = false;
                      _viewModeDate =
                          null; // Clear view mode when selecting recording date
                    });
                    _loadAllGroupsWithStudents();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatTurkishDate(date),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.darkTextPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Bugün',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState: _isDateExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.darkSurfaceContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.darkTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
