import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../themes/theme_extensions.dart';
import '../animations/common_animations.dart';

/// 主题设置对话框
class ThemeSettingsDialog extends StatefulWidget {
  const ThemeSettingsDialog({super.key});

  @override
  State<ThemeSettingsDialog> createState() => _ThemeSettingsDialogState();
}

class _ThemeSettingsDialogState extends State<ThemeSettingsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 标题
                Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: appProvider.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '主题设置',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 标签栏
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '主题模式'),
                    Tab(text: '主题颜色'),
                    Tab(text: '字体设置'),
                  ],
                ),

                // 内容
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildThemeModeTab(appProvider),
                      _buildThemeColorTab(appProvider),
                      _buildFontSettingsTab(appProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 主题模式标签页
  Widget _buildThemeModeTab(AppProvider appProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择主题模式',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // 主题模式选项
          ...ThemeMode.values.map((mode) {
            return FadeInAnimation(
              delay: ThemeMode.values.indexOf(mode) * 100,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<ThemeMode>(
                  title: Text(mode.displayName),
                  subtitle: Text(mode.description),
                  value: mode,
                  groupValue: appProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      appProvider.setThemeMode(value);
                    }
                  },
                  secondary: Icon(mode.icon),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // 预览区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '预览效果',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: appProvider.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '今日工作记录',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '完成项目进度汇报',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 主题颜色标签页
  Widget _buildThemeColorTab(AppProvider appProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择主题颜色',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // 颜色网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: AppProvider.themeColors.length,
            itemBuilder: (context, index) {
              final color = AppProvider.themeColors[index];
              final isSelected = appProvider.primaryColor == color;

              return ScaleAnimation(
                delay: index * 50,
                child: GestureDetector(
                  onTap: () {
                    appProvider.setPrimaryColor(color);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // 颜色名称
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: appProvider.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '当前颜色：${appProvider.primaryColor.displayName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 字体设置标签页
  Widget _buildFontSettingsTab(AppProvider appProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '字体大小',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // 字体大小滑块
          Row(
            children: [
              const Text('小', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: appProvider.fontSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 12,
                  label: '${appProvider.fontSize.toInt()}pt',
                  onChanged: (value) {
                    appProvider.setFontSize(value);
                  },
                ),
              ),
              const Text('大', style: TextStyle(fontSize: 18)),
            ],
          ),

          const SizedBox(height: 24),

          // 字体预览
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '字体预览',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  '标题文本',
                  style: TextStyle(
                    fontSize: appProvider.fontSize + 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '正文内容：这是一段示例文本，用于预览当前字体大小设置的效果。',
                  style: TextStyle(fontSize: appProvider.fontSize),
                ),
                const SizedBox(height: 8),
                Text(
                  '小号文本',
                  style: TextStyle(
                    fontSize: appProvider.fontSize - 2,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 重置按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                appProvider.setFontSize(16.0);
              },
              child: const Text('重置为默认字体大小'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 主题选择器组件
class ThemeSelector extends StatelessWidget {
  final Function(ThemeMode)? onThemeChanged;
  final Function(Color)? onColorChanged;

  const ThemeSelector({super.key, this.onThemeChanged, this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Column(
          children: [
            // 主题模式选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '主题模式',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ThemeMode.values.map((mode) {
                        final isSelected = appProvider.themeMode == mode;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              appProvider.setThemeMode(mode);
                              onThemeChanged?.call(mode);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? appProvider.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? appProvider.primaryColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    mode.icon,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mode.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 主题颜色选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '主题颜色',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppProvider.themeColors.map((color) {
                        final isSelected = appProvider.primaryColor == color;
                        return GestureDetector(
                          onTap: () {
                            appProvider.setPrimaryColor(color);
                            onColorChanged?.call(color);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 快速主题切换按钮
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return IconButton(
          onPressed: () {
            final currentMode = appProvider.themeMode;
            final newMode = currentMode == ThemeMode.light
                ? ThemeMode.dark
                : ThemeMode.light;
            appProvider.setThemeMode(newMode);
          },
          icon: Icon(
            appProvider.themeMode == ThemeMode.light
                ? Icons.dark_mode
                : Icons.light_mode,
          ),
          tooltip: appProvider.themeMode == ThemeMode.light
              ? '切换到深色模式'
              : '切换到浅色模式',
        );
      },
    );
  }
}
