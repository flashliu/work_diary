import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../constants/app_constants.dart';

/// 标签尺寸枚举
enum TagSize { small, medium, large }

/// 颜色工具类
class ColorUtils {
  /// 将十六进制颜色字符串转换为Color对象
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// 将Color对象转换为十六进制字符串
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// 获取标签默认颜色
  static Color getTagColor(String colorString) {
    try {
      return hexToColor(colorString);
    } catch (e) {
      // 如果转换失败，返回默认颜色
      return AppConstants.tagColors[0];
    }
  }
}

/// 标签芯片组件
/// 用于展示标签信息
class TagChip extends StatelessWidget {
  final Tag tag;
  final TagSize size;
  final bool showDeleteButton;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;

  const TagChip({
    super.key,
    required this.tag,
    this.size = TagSize.medium,
    this.showDeleteButton = false,
    this.onPressed,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final chipSize = _getChipSize();
    final textStyle = _getTextStyle();
    final tagColor = ColorUtils.getTagColor(tag.color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(chipSize.height / 2),
        child: Container(
          height: chipSize.height,
          constraints: BoxConstraints(minWidth: chipSize.height, maxWidth: 120),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(chipSize.height / 2),
            border: Border.all(
              color: tagColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: chipSize.padding,
              vertical: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    tag.name,
                    style: textStyle.copyWith(color: tagColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showDeleteButton) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDeleted,
                    child: Icon(
                      Icons.close,
                      size: chipSize.iconSize,
                      color: tagColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ChipSize _getChipSize() {
    switch (size) {
      case TagSize.small:
        return const _ChipSize(height: 24, padding: 8, iconSize: 12);
      case TagSize.medium:
        return const _ChipSize(height: 28, padding: 12, iconSize: 16);
      case TagSize.large:
        return const _ChipSize(height: 32, padding: 16, iconSize: 18);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case TagSize.small:
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
      case TagSize.medium:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
      case TagSize.large:
        return const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
    }
  }
}

/// 标签输入组件
/// 用于输入和管理标签
class TagInput extends StatefulWidget {
  final List<Tag> tags;
  final List<Tag> availableTags;
  final ValueChanged<List<Tag>> onTagsChanged;
  final String? hintText;
  final int? maxTags;

  const TagInput({
    super.key,
    required this.tags,
    required this.availableTags,
    required this.onTagsChanged,
    this.hintText,
    this.maxTags,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _showSuggestions = false;
  List<Tag> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions(_controller.text);
    } else {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      _filteredSuggestions = widget.availableTags
          .where((tag) => !widget.tags.contains(tag))
          .toList();
    } else {
      _filteredSuggestions = widget.availableTags
          .where(
            (tag) =>
                tag.name.toLowerCase().contains(query.toLowerCase()) &&
                !widget.tags.contains(tag),
          )
          .toList();
    }

    setState(() {
      _showSuggestions = _filteredSuggestions.isNotEmpty;
    });
  }

  void _addTag(Tag tag) {
    if (widget.maxTags != null && widget.tags.length >= widget.maxTags!) {
      return;
    }

    if (!widget.tags.contains(tag)) {
      final newTags = List<Tag>.from(widget.tags)..add(tag);
      widget.onTagsChanged(newTags);
      _controller.clear();
      _updateSuggestions('');
    }
  }

  void _removeTag(Tag tag) {
    final newTags = List<Tag>.from(widget.tags)..remove(tag);
    widget.onTagsChanged(newTags);
  }

  void _createNewTag(String name) {
    if (name.trim().isEmpty) return;

    final newTag = Tag(
      id: null, // 新标签的ID将在数据库中自动生成
      name: name.trim(),
      color: ColorUtils.colorToHex(
        AppConstants.tagColors[DateTime.now().millisecondsSinceEpoch %
            AppConstants.tagColors.length],
      ),
      createdAt: DateTime.now(),
    );

    _addTag(newTag);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? Theme.of(context).primaryColor
                  : Colors.grey.withValues(alpha: 0.3),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 已选择的标签
                ...widget.tags.map((tag) {
                  return TagChip(
                    tag: tag,
                    size: TagSize.medium,
                    showDeleteButton: true,
                    onDeleted: () => _removeTag(tag),
                  );
                }),

                // 输入框
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? '添加标签...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    onChanged: _updateSuggestions,
                    onSubmitted: _createNewTag,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 建议列表
        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: _filteredSuggestions.length,
              itemBuilder: (context, index) {
                final tag = _filteredSuggestions[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: ColorUtils.getTagColor(tag.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(tag.name, style: const TextStyle(fontSize: 14)),
                  onTap: () => _addTag(tag),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// 标签选择器组件
/// 用于选择多个标签
class TagSelector extends StatefulWidget {
  final List<Tag> availableTags;
  final List<Tag> selectedTags;
  final ValueChanged<List<Tag>> onSelectionChanged;
  final bool allowMultipleSelection;

  const TagSelector({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onSelectionChanged,
    this.allowMultipleSelection = true,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  void _toggleTag(Tag tag) {
    List<Tag> newSelectedTags;

    if (widget.allowMultipleSelection) {
      if (widget.selectedTags.contains(tag)) {
        newSelectedTags = widget.selectedTags.where((t) => t != tag).toList();
      } else {
        newSelectedTags = [...widget.selectedTags, tag];
      }
    } else {
      newSelectedTags = widget.selectedTags.contains(tag) ? [] : [tag];
    }

    widget.onSelectionChanged(newSelectedTags);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.availableTags.map((tag) {
        final isSelected = widget.selectedTags.contains(tag);
        final tagColor = ColorUtils.getTagColor(tag.color);

        return GestureDetector(
          onTap: () => _toggleTag(tag),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? tagColor : tagColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tagColor, width: isSelected ? 2 : 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              tag.name,
              style: TextStyle(
                color: isSelected ? Colors.white : tagColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 芯片尺寸辅助类
class _ChipSize {
  final double height;
  final double padding;
  final double iconSize;

  const _ChipSize({
    required this.height,
    required this.padding,
    required this.iconSize,
  });
}
