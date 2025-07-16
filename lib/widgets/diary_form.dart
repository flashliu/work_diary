import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../models/tag.dart';
import 'tag_widget.dart';

/// 日记表单组件
/// 用于创建和编辑日记条目
class DiaryForm extends StatefulWidget {
  final DiaryEntry? initialEntry;
  final List<Tag> availableTags;
  final ValueChanged<DiaryEntry> onSaved;
  final VoidCallback? onCancel;

  const DiaryForm({
    super.key,
    this.initialEntry,
    required this.availableTags,
    required this.onSaved,
    this.onCancel,
  });

  @override
  State<DiaryForm> createState() => _DiaryFormState();
}

class _DiaryFormState extends State<DiaryForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<String> _selectedTags = [];
  List<Tag> _selectedTagObjects = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialEntry != null) {
      _titleController.text = widget.initialEntry!.title;
      _contentController.text = widget.initialEntry!.content;
      _notesController.text = widget.initialEntry!.notes ?? '';
      _selectedDate = widget.initialEntry!.date;
      _selectedTags = List.from(widget.initialEntry!.tags);

      // 将字符串标签转换为Tag对象
      _selectedTagObjects = _selectedTags.map((tagName) {
        return widget.availableTags.firstWhere(
          (tag) => tag.name == tagName,
          orElse: () =>
              Tag(name: tagName, color: '#2196F3', createdAt: DateTime.now()),
        );
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onTagsChanged(List<Tag> tags) {
    setState(() {
      _selectedTagObjects = tags;
      _selectedTags = tags.map((tag) => tag.name).toList();
    });
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final entry = DiaryEntry(
        id: widget.initialEntry?.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: _selectedDate,
        tags: _selectedTags,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: widget.initialEntry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSaved(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期选择
          _buildDateSection(),

          const SizedBox(height: 16),

          // 工作内容
          _buildContentSection(),

          const SizedBox(height: 16),

          // 标签
          _buildTagsSection(),

          const SizedBox(height: 16),

          // 备注
          _buildNotesSection(),

          const SizedBox(height: 24),

          // 操作按钮
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '日期',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('yyyy年MM月dd日').format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE', 'zh_CN').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '工作内容',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '标题',
              hintText: '今天做了什么？',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入标题';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contentController,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '详细内容',
              hintText: '详细描述今天的工作内容、遇到的问题、解决方案等...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入详细内容';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.label, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '标签',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TagInput(
            tags: _selectedTagObjects,
            availableTags: widget.availableTags,
            onTagsChanged: _onTagsChanged,
            hintText: '添加标签...',
            maxTags: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '备注',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '备注信息',
              hintText: '添加其他备注信息...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.onCancel != null)
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('取消'),
            ),
          ),
        if (widget.onCancel != null) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(widget.initialEntry != null ? '更新' : '保存'),
          ),
        ),
      ],
    );
  }
}

/// 快速日记表单
/// 用于快速创建简单的日记条目
class QuickDiaryForm extends StatefulWidget {
  final ValueChanged<DiaryEntry> onSaved;
  final VoidCallback? onCancel;

  const QuickDiaryForm({super.key, required this.onSaved, this.onCancel});

  @override
  State<QuickDiaryForm> createState() => _QuickDiaryFormState();
}

class _QuickDiaryFormState extends State<QuickDiaryForm> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入标题')));
      return;
    }

    final entry = DiaryEntry(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSaved(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          const Text(
            '快速记录',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 标题输入
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '标题',
              hintText: '今天做了什么？',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // 内容输入
          TextField(
            controller: _contentController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '内容',
              hintText: '简单描述工作内容...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              if (widget.onCancel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('取消'),
                  ),
                ),
              if (widget.onCancel != null) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
