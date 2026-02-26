import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Map<String, dynamic>? _selectedGroup;
  List<Map<String, dynamic>> _attendanceData = [];
  bool _isLoading = false;

  Future<void> _fetchStudents(String groupId) async {
    setState(() => _isLoading = true);
    final students = await context.read<AuthProvider>().fetchStudentsByGroup(
      groupId,
    );
    setState(() {
      _attendanceData = students
          .map(
            (s) => {
              'id': s['id'],
              'full_name': s['full_name'],
              'status': 'present', // Default status
            },
          )
          .toList();
      _isLoading = false;
    });
  }

  void _updateStatus(int index, String status) {
    setState(() {
      _attendanceData[index]['status'] = status;
    });
  }

  Future<void> _saveAll() async {
    if (_selectedGroup == null) return;

    final auth = context.read<AuthProvider>();
    int successCount = 0;

    for (var record in _attendanceData) {
      final success = await auth.saveAttendance(
        studentId: record['id'],
        groupId: _selectedGroup!['id'],
        status: record['status'],
      );
      if (success) successCount++;
    }

    if (mounted) {
      if (Navigator.canPop(context)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount öğrencinin yoklaması kaydedildi.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final teacherProfile = auth.userProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Yoklama Al')),
      body: Column(
        children: [
          // Grup Seçimi
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: auth
                  .fetchClassGroups(), // Aslında sadece hocanın grupları olmalı
              builder: (context, snapshot) {
                final allGroups = snapshot.data ?? [];
                // Sadece bu hocaya ait grupları filtreleyelim (Admin değilse)
                final myGroups = auth.isAnyAdmin
                    ? allGroups
                    : allGroups
                          .where(
                            (g) => g['teacher_id'] == teacherProfile?['id'],
                          )
                          .toList();

                return DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  hint: const Text('Ders Grubu Seçin'),
                  value: _selectedGroup,
                  items: myGroups
                      .map(
                        (g) =>
                            DropdownMenuItem(value: g, child: Text(g['name'])),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedGroup = val);
                    if (val != null) _fetchStudents(val['id']);
                  },
                );
              },
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedGroup == null
                ? const Center(child: Text('Lütfen bir grup seçin'))
                : _attendanceData.isEmpty
                ? const Center(child: Text('Bu grupta öğrenci bulunamadı.'))
                : ListView.builder(
                    itemCount: _attendanceData.length,
                    itemBuilder: (context, index) {
                      final student = _attendanceData[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(student['full_name']),
                          trailing: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'present',
                                label: Text('V'),
                                tooltip: 'Var',
                              ),
                              ButtonSegment(
                                value: 'absent',
                                label: Text('Y'),
                                tooltip: 'Yok',
                              ),
                              ButtonSegment(
                                value: 'late',
                                label: Text('G'),
                                tooltip: 'Geç',
                              ),
                            ],
                            selected: {student['status']},
                            onSelectionChanged: (Set<String> newSelection) {
                              _updateStatus(index, newSelection.first);
                            },
                            showSelectedIcon: false,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_selectedGroup != null && _attendanceData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _saveAll,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yoklamayı Kaydet'),
              ),
            ),
        ],
      ),
    );
  }
}
