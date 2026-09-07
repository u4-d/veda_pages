import 'package:flutter/material.dart';
import 'package:app_config/app_config.dart';
import 'package:my_supabase_service/my_supabase_service.dart';
import 'package:ranking/sector_ranking.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化 Web 环境配置与 Supabase 连接
  final AppConfig config = ConfigFactory.web();
  final SupabaseService supabaseService = SupabaseService(config);

  runApp(VedaPagesApp(supabaseService: supabaseService, config: config));
}

class VedaPagesApp extends StatefulWidget {
  final SupabaseService supabaseService;
  final AppConfig config;

  const VedaPagesApp({
    super.key,
    required this.supabaseService,
    required this.config,
  });

  @override
  State<VedaPagesApp> createState() => _VedaPagesAppState();
}

class _VedaPagesAppState extends State<VedaPagesApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF1E3A8A); // 深蓝主色调

    return MaterialApp(
      title: 'VEDA 股票量化与行业分析平台',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(elevation: 1, margin: EdgeInsets.zero),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(elevation: 1, margin: EdgeInsets.zero),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      home: VedaMainDashboard(
        supabaseService: widget.supabaseService,
        config: widget.config,
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class VedaMainDashboard extends StatefulWidget {
  final SupabaseService supabaseService;
  final AppConfig config;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const VedaMainDashboard({
    super.key,
    required this.supabaseService,
    required this.config,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<VedaMainDashboard> createState() => _VedaMainDashboardState();
}

class _VedaMainDashboardState extends State<VedaMainDashboard> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SectorDashboardPage.withService(supabaseService: widget.supabaseService),
      StockScoreRankingPage(supabaseService: widget.supabaseService),
      Scaffold(
        appBar: AppBar(title: const Text('数据计算流水线')),
        body: DataPipelineView(supabaseService: widget.supabaseService),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 800;

        if (isWideScreen) {
          // 宽屏模式：左侧 NavigationRail + 顶部状态栏 + 主内容区
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'V',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'VEDA',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: IconButton(
                          icon: Icon(
                            widget.themeMode == ThemeMode.light
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                          ),
                          tooltip: widget.themeMode == ThemeMode.light
                              ? '切换至深色模式'
                              : '切换至浅色模式',
                          onPressed: widget.onToggleTheme,
                        ),
                      ),
                    ),
                  ),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view),
                      label: Text('行业板块'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.format_list_numbered_outlined),
                      selectedIcon: Icon(Icons.format_list_numbered),
                      label: Text('评分排行'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.schema_outlined),
                      selectedIcon: Icon(Icons.schema),
                      label: Text('数据流水线'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: _pages),
                ),
              ],
            ),
          );
        } else {
          // 移动端/窄屏模式：底部 NavigationBar
          return Scaffold(
            body: IndexedStack(index: _selectedIndex, children: _pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view),
                  label: '行业板块',
                ),
                NavigationDestination(
                  icon: Icon(Icons.format_list_numbered_outlined),
                  selectedIcon: Icon(Icons.format_list_numbered),
                  label: '评分排行',
                ),
                NavigationDestination(
                  icon: Icon(Icons.schema_outlined),
                  selectedIcon: Icon(Icons.schema),
                  label: '流水线',
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
