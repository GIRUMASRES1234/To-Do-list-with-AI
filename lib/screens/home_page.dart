// lib/screens/home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../services/openrouter_ai_service.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final TaskService _taskService = TaskService();
  final OpenRouterAIService _aiService = OpenRouterAIService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  bool isGenerating = false;
  String searchText = "";
  String filterCategory = "All";

  final List<String> categories = ["All", "School", "Work", "Personal"];
  final List<String> priorities = ["High", "Medium", "Low"];

  String selectedCategory = "School";
  String selectedPriority = "Medium";
  DateTime? selectedDate;

  // ─── Theme palette ─────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF4F46E5);
  static const Color _primaryLight = Color(0xFF818CF8);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fabScaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  bool isOverdue(String? dueDate) {
    if (dueDate == null) return false;
    try {
      final d = DateTime.parse(dueDate);
      final now = DateTime.now();
      return DateTime(
        d.year,
        d.month,
        d.day,
      ).isBefore(DateTime(now.year, now.month, now.day));
    } catch (_) {
      return false;
    }
  }

  Color getPriorityColor(String p) {
    switch (p) {
      case "High":
        return _danger;
      case "Medium":
        return _warning;
      default:
        return _success;
    }
  }

  Color getCategoryColor(String c) {
    switch (c) {
      case "School":
        return _primary;
      case "Work":
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF06B6D4);
    }
  }

  Color getCategoryBg(String c) {
    switch (c) {
      case "School":
        return const Color(0xFFEEF2FF);
      case "Work":
        return const Color(0xFFF5F3FF);
      default:
        return const Color(0xFFECFEFF);
    }
  }

  Color getPriorityBg(String p) {
    switch (p) {
      case "High":
        return const Color(0xFFFEF2F2);
      case "Medium":
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFECFDF5);
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // ─── Snack helper ──────────────────────────────────────────────────────────

  void _snack(
    String msg, {
    Color color = _success,
    IconData icon = Icons.check_circle,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── AI Dialog ─────────────────────────────────────────────────────────────

  void showAIGenerateDialog() {
    final promptController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Task Generator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Describe what you want to accomplish',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: promptController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Prepare for final exam next week',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _primaryLight,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (promptController.text.trim().isEmpty) return;
                        Navigator.pop(context);
                        setState(() => isGenerating = true);
                        try {
                          final tasks = await _aiService.generateTasks(
                            promptController.text.trim(),
                          );
                          for (var t in tasks) {
                            await _taskService.addGeneratedTask(t);
                          }
                          if (mounted) _snack('AI tasks added successfully ✨');
                        } catch (e) {
                          if (mounted)
                            _snack(
                              'AI Error: $e',
                              color: _danger,
                              icon: Icons.error_outline,
                            );
                        } finally {
                          if (mounted) setState(() => isGenerating = false);
                        }
                      },
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text(
                        'Generate',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Add Task Bottom Sheet ─────────────────────────────────────────────────

  void _showAddTaskDialog() {
    _titleController.clear();
    _descController.clear();
    selectedCategory = "School";
    selectedPriority = "Medium";
    selectedDate = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF1E1B2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primary, _primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.add_task,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'New Task',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: widget.isDarkMode
                            ? Colors.white
                            : const Color(0xFF0F0A1E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                _sheetField(
                  _titleController,
                  'Task title',
                  Icons.title_rounded,
                ),
                const SizedBox(height: 11),
                _sheetField(
                  _descController,
                  'Description (optional)',
                  Icons.notes_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _sheetDropdown<String>(
                        value: selectedCategory,
                        label: 'Category',
                        icon: Icons.folder_outlined,
                        items: ["School", "Work", "Personal"],
                        color: getCategoryColor(selectedCategory),
                        onChanged: (v) => setS(() => selectedCategory = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _sheetDropdown<String>(
                        value: selectedPriority,
                        label: 'Priority',
                        icon: Icons.flag_outlined,
                        items: priorities,
                        color: getPriorityColor(selectedPriority),
                        onChanged: (v) => setS(() => selectedPriority = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),

                // Date picker
                GestureDetector(
                  onTap: () async {
                    await pickDate();
                    setS(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: selectedDate != null
                          ? _primary.withOpacity(0.06)
                          : (widget.isDarkMode
                                ? Colors.white.withOpacity(0.06)
                                : const Color(0xFFF8F8FF)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selectedDate != null
                            ? _primary.withOpacity(0.35)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_rounded,
                          size: 20,
                          color: selectedDate != null
                              ? _primary
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          selectedDate == null
                              ? 'Pick due date'
                              : 'Due ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedDate != null
                                ? _primary
                                : Colors.grey.shade400,
                            fontWeight: selectedDate != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (selectedDate != null)
                          GestureDetector(
                            onTap: () => setS(() => selectedDate = null),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: Colors.grey.withOpacity(0.25),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primary, _primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_titleController.text.trim().isNotEmpty) {
                              await _taskService.addTask(
                                _titleController.text.trim(),
                                _descController.text.trim(),
                                category: selectedCategory,
                                priority: selectedPriority,
                                dueDate: selectedDate?.toString(),
                              );
                              if (mounted) Navigator.pop(ctx);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Save Task',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sheet field helpers ───────────────────────────────────────────────────

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: _primary),
        filled: true,
        fillColor: widget.isDarkMode
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF8F8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _sheetDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required Color color,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: color),
        filled: true,
        fillColor: widget.isDarkMode
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF8F8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      ),
      items: items
          .map((i) => DropdownMenuItem<T>(value: i, child: Text(i.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ─── Drawer header ─────────────────────────────────────────────────────────

  Widget _drawerHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .snapshots(),
      builder: (_, snap) {
        String? imageUrl;
        if (snap.hasData && snap.data!.exists) {
          imageUrl =
              (snap.data!.data() as Map<String, dynamic>)["profileImage"];
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF312E81), _primary],
            ),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl == null
                      ? const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 28,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Stat card ─────────────────────────────────────────────────────────────

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF1E1B2E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Badge ─────────────────────────────────────────────────────────────────

  Widget _buildBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ─── Task card ─────────────────────────────────────────────────────────────

  Widget buildTaskCard(DocumentSnapshot task) {
    final bool isCompleted = task["isCompleted"] ?? false;
    final String category = task["category"] ?? "School";
    final String priority = task["priority"] ?? "Medium";
    final String? dueDate = task["dueDate"];
    final String title = task["title"] ?? "";
    final String desc = task["description"] ?? "";
    final bool overdue = isOverdue(dueDate) && !isCompleted;

    final Color accent = isCompleted
        ? Colors.grey
        : overdue
        ? _danger
        : getCategoryColor(category);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _taskService.deleteTask(task.id),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: _danger,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _taskService.toggleTaskStatus(task.id, !isCompleted),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF1E1B2E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted
                  ? Colors.grey.withOpacity(0.12)
                  : overdue
                  ? _danger.withOpacity(0.25)
                  : accent.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(isCompleted ? 0.03 : 0.07),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated checkbox
                GestureDetector(
                  onTap: () =>
                      _taskService.toggleTaskStatus(task.id, !isCompleted),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isCompleted ? accent : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? accent
                            : Colors.grey.withOpacity(0.35),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 15,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: Colors.grey.shade400,
                                color: isCompleted
                                    ? Colors.grey.shade400
                                    : (widget.isDarkMode
                                          ? Colors.white
                                          : const Color(0xFF0F0A1E)),
                              ),
                            ),
                          ),
                          if (overdue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: _danger,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Overdue',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildBadge(
                            category,
                            getCategoryBg(category),
                            getCategoryColor(category),
                          ),
                          _buildBadge(
                            priority,
                            getPriorityBg(priority),
                            getPriorityColor(priority),
                          ),
                          if (dueDate != null)
                            _buildBadge(
                              '📅 ${dueDate.substring(0, 10)}',
                              overdue
                                  ? _danger.withOpacity(0.08)
                                  : Colors.grey.withOpacity(0.09),
                              overdue ? _danger : Colors.grey.shade600,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: () => _taskService.deleteTask(task.id),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _danger.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: _danger,
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Drawer tile ───────────────────────────────────────────────────────────

  Widget _drawerTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color == _danger ? _danger : null,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bg = isDark ? const Color(0xFF13111E) : const Color(0xFFF4F3FF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1B2E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, _primaryLight],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Task Manager',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF0F0A1E),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            onPressed: widget.onThemeChanged,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E1B2E) : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _drawerHeader(),
            const SizedBox(height: 8),
            _drawerTile(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              color: _primary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            _drawerTile(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: _danger,
              onTap: () async {
                Navigator.pop(context);
                await _auth.signOut();
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _taskService.getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      color: _primary,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your tasks...',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _danger.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: _danger,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }

          final allTasks = snapshot.data?.docs ?? [];
          final totalTasks = allTasks.length;
          final completedTasks = allTasks
              .where((t) => (t["isCompleted"] ?? false) == true)
              .length;
          final pendingTasks = totalTasks - completedTasks;

          final filteredTasks = allTasks.where((t) {
            final title = (t["title"] ?? "").toString().toLowerCase();
            final desc = (t["description"] ?? "").toString().toLowerCase();
            final category = (t["category"] ?? "").toString();
            final priority = (t["priority"] ?? "").toString().toLowerCase();
            final query = searchText.trim().toLowerCase();

            final matchesSearch =
                query.isEmpty ||
                title.contains(query) ||
                desc.contains(query) ||
                category.toLowerCase().contains(query) ||
                priority.contains(query);

            final matchesCategory =
                filterCategory == "All" || category == filterCategory;

            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              // Stats
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    _buildStatCard(
                      'Total',
                      totalTasks.toString(),
                      Icons.format_list_bulleted_rounded,
                      _primary,
                      const Color(0xFFEEF2FF),
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      'Done',
                      completedTasks.toString(),
                      Icons.check_circle_outline_rounded,
                      _success,
                      const Color(0xFFECFDF5),
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      'Pending',
                      pendingTasks.toString(),
                      Icons.pending_actions_rounded,
                      _warning,
                      const Color(0xFFFFFBEB),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => searchText = v),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F0A1E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                      suffixIcon: searchText.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.grey.shade400,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => searchText = "");
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Category chips
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final sel = filterCategory == cat;
                    final chipColor = cat == "All"
                        ? _primary
                        : getCategoryColor(cat);
                    return GestureDetector(
                      onTap: () => setState(() => filterCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? chipColor
                              : (isDark
                                    ? const Color(0xFF1E1B2E)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? chipColor
                                : Colors.grey.withOpacity(0.2),
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: chipColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                            color: sel ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // AI button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: showAIGenerateDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF312E81), _primary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Generate Tasks with AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white54,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (isGenerating)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      color: _primaryLight,
                      backgroundColor: Color(0xFFEEF2FF),
                      minHeight: 3,
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // Task list
              Expanded(
                child: filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                searchText.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.inbox_outlined,
                                size: 34,
                                color: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchText.isNotEmpty
                                  ? 'No results for "$searchText"'
                                  : 'No tasks yet',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (searchText.isEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Tap + to create your first task',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 110),
                        itemCount: filteredTasks.length,
                        itemBuilder: (_, i) => buildTaskCard(filteredTasks[i]),
                      ),
              ),
            ],
          );
        },
      ),

      // Animated FAB
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: GestureDetector(
          onTapDown: (_) => _fabAnimController.forward(),
          onTapUp: (_) {
            _fabAnimController.reverse();
            _showAddTaskDialog();
          },
          onTapCancel: () => _fabAnimController.reverse(),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryLight, _primary],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
