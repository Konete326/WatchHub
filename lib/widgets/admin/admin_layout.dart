import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_drawer.dart';
import '../../providers/settings_provider.dart';
import 'admin_search_delegate.dart';

// Intents for shortcuts
class SearchIntent extends Intent {
  const SearchIntent();
}

class DashboardIntent extends Intent {
  const DashboardIntent();
}

class ProductsIntent extends Intent {
  const ProductsIntent();
}

class OrdersIntent extends Intent {
  const OrdersIntent();
}

class UsersIntent extends Intent {
  const UsersIntent();
}

class AdminLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final String currentRoute;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    required this.currentRoute,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.slash): const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyG, LogicalKeyboardKey.keyH):
            const DashboardIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyG, LogicalKeyboardKey.keyP):
            const ProductsIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyG, LogicalKeyboardKey.keyO):
            const OrdersIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyG, LogicalKeyboardKey.keyU):
            const UsersIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (SearchIntent intent) {
              showSearch(context: context, delegate: AdminSearchDelegate());
              return null;
            },
          ),
          DashboardIntent: CallbackAction<DashboardIntent>(
            onInvoke: (intent) => _navigate('/admin'),
          ),
          ProductsIntent: CallbackAction<ProductsIntent>(
            onInvoke: (intent) => _navigate('/admin/products'),
          ),
          OrdersIntent: CallbackAction<OrdersIntent>(
            onInvoke: (intent) => _navigate('/admin/orders'),
          ),
          UsersIntent: CallbackAction<UsersIntent>(
            onInvoke: (intent) => _navigate('/admin/users'),
          ),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isLargeScreen = constraints.maxWidth > 900;

              return Scaffold(
                appBar: isLargeScreen
                    ? null // Use a custom header on large screens
                    : AppBar(
                        title: Text(widget.title),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              showSearch(
                                  context: context,
                                  delegate: AdminSearchDelegate());
                            },
                          ),
                          if (widget.actions != null) ...widget.actions!,
                        ],
                      ),
                drawer: isLargeScreen ? null : const AdminDrawer(),
                body: Row(
                  children: [
                    if (isLargeScreen)
                      AdminSidebar(
                        isCollapsed: _isCollapsed,
                        onToggle: (value) =>
                            setState(() => _isCollapsed = value),
                        currentRoute: widget.currentRoute,
                      ),
                    if (isLargeScreen)
                      VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Theme.of(context).dividerColor),
                    Expanded(
                      child: Column(
                        children: [
                          if (isLargeScreen) _buildWebHeader(),
                          Expanded(child: widget.child),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigate(String route) {
    if (widget.currentRoute != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  Widget _buildWebHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Breadcrumbs & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBreadcrumbs(),
                const SizedBox(height: 4),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          // Center: Global Search Bar
          Expanded(
            flex: 2,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  showSearch(context: context, delegate: AdminSearchDelegate());
                },
                child: Container(
                  width: 400,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search,
                          size: 20, color: Theme.of(context).hintColor),
                      const SizedBox(width: 8),
                      Text(
                        'Search products, orders, users... (/)',
                        style: TextStyle(
                            color: Theme.of(context).hintColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right: Actions & Theme Toggle
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    bool isDark = settings.themeMode == ThemeMode.dark;
                    return IconButton(
                      tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                      onPressed: () => settings.toggleTheme(),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/admin/notifications'),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.shade100,
                  child:
                      Text('A', style: TextStyle(color: Colors.blue.shade800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    // Generate simple breadcrumbs from route
    final parts =
        widget.currentRoute.split('/').where((p) => p.isNotEmpty).toList();
    List<Widget> crumbs = [];

    // Always start with Home (Admin Dashboard)
    crumbs.add(InkWell(
      onTap: () => _navigate('/admin'),
      child: Text('Home',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ));

    for (var part in parts) {
      if (part == 'admin') {
        continue;
      }
      crumbs.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
      ));
      crumbs.add(Text(part[0].toUpperCase() + part.substring(1),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: crumbs);
  }
}
