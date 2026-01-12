import 'package:flutter/material.dart';
import '../models/field_definition.dart';
import '../theme/app_theme.dart';

/// Bottom sheet picker for adding custom fields to a job template
class AddFieldPicker extends StatefulWidget {
  final List<String> alreadyAddedKeys;
  final Function(FieldDefinition field, bool deductFromEarnings)
      onFieldSelected;

  const AddFieldPicker({
    super.key,
    required this.alreadyAddedKeys,
    required this.onFieldSelected,
  });

  @override
  State<AddFieldPicker> createState() => _AddFieldPickerState();

  static Future<void> show(
    BuildContext context, {
    required List<String> alreadyAddedKeys,
    required Function(FieldDefinition field, bool deductFromEarnings)
        onFieldSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => AddFieldPicker(
          alreadyAddedKeys: alreadyAddedKeys,
          onFieldSelected: onFieldSelected,
        ),
      ),
    );
  }
}

class _AddFieldPickerState extends State<AddFieldPicker> {
  String? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FieldDefinition> get _filteredFields {
    var fields = FieldRegistry.allFields
        .where((f) => !widget.alreadyAddedKeys.contains(f.key))
        .toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      fields = fields.where((f) {
        return f.label.toLowerCase().contains(query) ||
            f.category.toLowerCase().contains(query) ||
            (f.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_selectedCategory != null) {
      fields = fields.where((f) => f.category == _selectedCategory).toList();
    }

    return fields;
  }

  List<String> get _categories {
    final cats = FieldRegistry.allFields
        .where((f) => !widget.alreadyAddedKeys.contains(f.key))
        .map((f) => f.category)
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  void _selectField(FieldDefinition field) async {
    if (field.canDeduct) {
      // Show deduction dialog
      final deduct = await _showDeductionDialog(field);
      if (deduct != null) {
        widget.onFieldSelected(field, deduct);
        if (mounted) Navigator.pop(context);
      }
    } else {
      widget.onFieldSelected(field, false);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<bool?> _showDeductionDialog(FieldDefinition field) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Add ${field.label}',
          style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (field.description != null) ...[
              Text(
                field.description!,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.accentOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This field can be deducted from your total earnings. Would you like to deduct it?',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.textMuted),
            ),
            child: Text('No Deduction',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Deduct from Earnings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen),
              const SizedBox(width: 12),
              Text(
                'Add Field',
                style:
                    AppTheme.titleLarge.copyWith(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search fields...',
              hintStyle: TextStyle(color: AppTheme.textMuted),
              prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppTheme.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Category chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // All categories chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = null);
                  },
                  selectedColor: AppTheme.primaryGreen,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _selectedCategory == null
                        ? Colors.white
                        : AppTheme.textPrimary,
                  ),
                  backgroundColor: AppTheme.cardBackgroundLight,
                ),
              ),
              // Category chips
              ..._categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat : null;
                        });
                      },
                      selectedColor: AppTheme.primaryGreen,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _selectedCategory == cat
                            ? Colors.white
                            : AppTheme.textPrimary,
                        fontSize: 12,
                      ),
                      backgroundColor: AppTheme.cardBackgroundLight,
                    ),
                  )),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Fields list
        Expanded(
          child: _filteredFields.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No fields found',
                        style: AppTheme.bodyMedium
                            .copyWith(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredFields.length,
                  itemBuilder: (context, index) {
                    final field = _filteredFields[index];
                    return _buildFieldTile(field);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFieldTile(FieldDefinition field) {
    return Card(
      color: AppTheme.cardBackgroundLight,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            field.icon ?? Icons.text_fields,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
        ),
        title: Text(
          field.label,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (field.hintText != null)
              Text(
                field.hintText!,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (field.canDeduct)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Can be deducted',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.accentOrange,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        trailing: Icon(Icons.add, color: AppTheme.primaryGreen),
        onTap: () => _selectField(field),
      ),
    );
  }
}
