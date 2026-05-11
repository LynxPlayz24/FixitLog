import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../pages/maintenance_page.dart';
import '../pages/profile_page.dart';
import '../pages/settings_page.dart';
import '../screens/add_item_screen.dart';
import '../screens/item_details_page.dart';
import '../services/auth_service.dart';
import '../services/local_notification_service.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Uint8List? _profileImageBytes;

  // Dashboard data
  List<Item> _items = [];
  bool _dashboardLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadDashboardData();
  }

  // ── Data loading ──────────────────────────────────────────────────────

  Future<void> _loadProfileImage() async {
    final email = AuthService.instance.currentUserEmail;
    if (email == null) return;
    final profile = await ProfileService.instance.loadProfile(email);
    if (!mounted) return;
    if (profile.profileImageBase64 != null &&
        profile.profileImageBase64!.isNotEmpty) {
      setState(() {
        _profileImageBytes = base64Decode(profile.profileImageBase64!);
      });
    }
  }

  Future<void> _loadDashboardData() async {
    final items = await StorageService.instance.loadItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _dashboardLoading = false;
    });
  }

  // ── Page routing ──────────────────────────────────────────────────────

  Widget _getPage(int index) {
    switch (index) {
      case 1:
        return const MaintenancePage();
      case 2:
        return const ProfilePage();
      case 3:
        return const SettingsPage();
      default:
        return _buildHomeDashboard();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
    if (index == 0) {
      _loadDashboardData(); // Refresh dashboard when coming back
    }
    if (index == 2 || _selectedIndex == 2) {
      Future.delayed(const Duration(milliseconds: 300), _loadProfileImage);
    }
  }

  // ── Dashboard builder ─────────────────────────────────────────────────

  Widget _buildHomeDashboard() {
    if (_dashboardLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final colorScheme = Theme.of(context).colorScheme;
    final allTasks = <_TaskWithItem>[];
    for (final item in _items) {
      for (final task in item.tasks) {
        allTasks.add(_TaskWithItem(task: task, item: item));
      }
    }

    final overdueTasks =
        allTasks.where((t) => t.task.isOverdue).toList()
          ..sort((a, b) => a.task.daysUntilDue.compareTo(b.task.daysUntilDue));

    final upcomingTasks = allTasks
        .where((t) => !t.task.isOverdue && t.task.daysUntilDue <= 14)
        .toList()
      ..sort((a, b) => a.task.daysUntilDue.compareTo(b.task.daysUntilDue));

    final totalItems = _items.length;
    final totalTasks = allTasks.length;
    final overdueCount = overdueTasks.length;
    final dueSoonCount = upcomingTasks.length;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // ── Welcome header ────────────────────────────────────────
          Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            widget.username,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // ── Stat cards ────────────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _statCard(
                icon: Icons.inventory_2_outlined,
                label: 'Items',
                value: '$totalItems',
                color: AppTheme.primaryPurple,
                colorScheme: colorScheme,
                onTap: () {
                  // Navigate to Maintenance page
                  setState(() => _selectedIndex = 1);
                },
              ),
              _statCard(
                icon: Icons.task_outlined,
                label: 'Tasks',
                value: '$totalTasks',
                color: Colors.blue,
                colorScheme: colorScheme,
                onTap: () => _showTaskListSheet(
                  title: 'All Tasks',
                  tasks: List.of(allTasks)
                    ..sort((a, b) =>
                        b.task.dateDone.compareTo(a.task.dateDone)),
                ),
              ),
              _statCard(
                icon: Icons.warning_amber_rounded,
                label: 'Overdue',
                value: '$overdueCount',
                color: Colors.redAccent,
                colorScheme: colorScheme,
                onTap: () => _showTaskListSheet(
                  title: 'Overdue Tasks',
                  tasks: overdueTasks,
                  emptyMessage: 'No overdue tasks — great job!',
                ),
              ),
              _statCard(
                icon: Icons.schedule_outlined,
                label: 'Due Soon',
                value: '$dueSoonCount',
                color: Colors.orange,
                colorScheme: colorScheme,
                onTap: () => _showTaskListSheet(
                  title: 'Due Soon (next 14 days)',
                  tasks: upcomingTasks,
                  emptyMessage: 'Nothing due in the next 14 days.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Quick actions ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _quickAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Add New Item'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Overdue tasks ─────────────────────────────────────────
          if (overdueTasks.isNotEmpty) ...[
            _sectionTitle(
              '🔴  Overdue',
              count: overdueCount,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            ...overdueTasks.take(5).map((t) => _taskRow(t, colorScheme)),
            if (overdueTasks.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${overdueTasks.length - 5} more overdue',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],

          // ── Upcoming tasks ────────────────────────────────────────
          if (upcomingTasks.isNotEmpty) ...[
            _sectionTitle(
              '🟡  Due Soon (next 14 days)',
              count: dueSoonCount,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            ...upcomingTasks.take(5).map((t) => _taskRow(t, colorScheme)),
            if (upcomingTasks.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${upcomingTasks.length - 5} more upcoming',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],

          // ── All clear ─────────────────────────────────────────────
          if (overdueTasks.isEmpty && upcomingTasks.isEmpty && totalTasks > 0)
            _allClearBanner(colorScheme),

          if (totalItems == 0) _emptyStateBanner(colorScheme),
        ],
      ),
    );
  }

  // ── Dashboard widgets ─────────────────────────────────────────────────

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ColorScheme colorScheme,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text,
      {required int count, required ColorScheme colorScheme}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _taskRow(_TaskWithItem tw, ColorScheme colorScheme) {
    final isOverdue = tw.task.isOverdue;
    final daysText = isOverdue
        ? '${-tw.task.daysUntilDue}d overdue'
        : '${tw.task.daysUntilDue}d left';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openItemDetails(tw.item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOverdue ? Colors.redAccent : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),

              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tw.task.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tw.item.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Due badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isOverdue ? Colors.redAccent : Colors.orange)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  daysText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? Colors.redAccent : Colors.orange,
                  ),
                ),
              ),

              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 18, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _allClearBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppTheme.successGreen, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All clear!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'No tasks are due in the next 14 days.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStateBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline,
              color: AppTheme.primaryPurple, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get started!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Add your first item to start tracking maintenance.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation helpers ────────────────────────────────────────────────

  Future<void> _quickAddItem() async {
    final newItem = await Navigator.push<Item>(
      context,
      MaterialPageRoute(builder: (context) => const AddItemScreen()),
    );
    if (newItem != null) {
      final items = await StorageService.instance.loadItems();
      items.add(newItem);
      await StorageService.instance.saveItems(items);
      await LocalNotificationService.instance.rescheduleAll();
      _loadDashboardData();
    }
  }

  Future<void> _openItemDetails(Item item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailsPage(item: item),
      ),
    );
    // Persist any task changes and refresh dashboard
    await StorageService.instance.saveItems(_items);
    await LocalNotificationService.instance.rescheduleAll();
    _loadDashboardData();
  }

  void _showTaskListSheet({
    required String title,
    required List<_TaskWithItem> tasks,
    String emptyMessage = 'No tasks found.',
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Task list
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            emptyMessage,
                            style: TextStyle(
                              fontSize: 15,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: tasks.length,
                          itemBuilder: (ctx, i) {
                            final tw = tasks[i];
                            final isOverdue = tw.task.isOverdue;
                            final daysText = isOverdue
                                ? '${-tw.task.daysUntilDue}d overdue'
                                : '${tw.task.daysUntilDue}d left';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (isOverdue
                                            ? Colors.redAccent
                                            : AppTheme.primaryPurple)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.build_outlined,
                                    size: 20,
                                    color: isOverdue
                                        ? Colors.redAccent
                                        : AppTheme.primaryPurple,
                                  ),
                                ),
                                title: Text(
                                  tw.task.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${tw.item.name}  •  Done: ${_formatDate(tw.task.dateDone)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isOverdue
                                            ? Colors.redAccent
                                            : Colors.orange)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    daysText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOverdue
                                          ? Colors.redAccent
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx); // Close sheet
                                  _openItemDetails(tw.item);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  // ── Main build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Fixit Log'),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text('Hi, ${widget.username}!'),
                accountEmail: const Text(''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImageBytes != null
                      ? MemoryImage(_profileImageBytes!)
                      : null,
                  child: _profileImageBytes == null
                      ? const Icon(Icons.person,
                          color: AppTheme.primaryPurple)
                      : null,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryPurple,
                ),
              ),
              _drawerItem(Icons.home, 'Home', 0),
              _drawerItem(Icons.build, 'Maintenance', 1),
              _drawerItem(Icons.person, 'Profile', 2),
              _drawerItem(Icons.settings, 'Settings', 3),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await AuthService.instance.clearSession();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                },
              ),
            ],
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey<int>(_selectedIndex),
            child: _getPage(_selectedIndex),
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? AppTheme.primaryPurple : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppTheme.primaryPurple : null,
        ),
      ),
      selected: isSelected,
      onTap: () => _onItemTapped(index),
    );
  }
}

/// Helper class to pair a task with its parent item.
class _TaskWithItem {
  final dynamic task;
  final Item item;
  const _TaskWithItem({required this.task, required this.item});
}
