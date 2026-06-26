import 'dart:async';
import 'package:flutter/material.dart';
import '../models/jira_issue.dart';
import '../services/jira_service.dart';
import '../l10n/strings_fa.dart';

class IssueSelector extends StatefulWidget {
  final JiraService? jiraService;
  final JiraIssue? selectedIssue;
  final ValueChanged<JiraIssue?> onSelected;

  const IssueSelector({
    super.key,
    this.jiraService,
    this.selectedIssue,
    required this.onSelected,
  });

  @override
  State<IssueSelector> createState() => _IssueSelectorState();
}

class _IssueSelectorState extends State<IssueSelector> {
  final _searchController = TextEditingController();
  List<JiraIssue> _results = [];
  bool _loading = false;
  Timer? _debounce;
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final text = _searchController.text.trim();
    if (text.length < 2) {
      _removeOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(text));
  }

  Future<void> _search(String query) async {
    if (widget.jiraService == null) return;
    setState(() => _loading = true);
    try {
      _results = await widget.jiraService!.searchIssuesAll(query: query, maxResults: 50);
      _showOverlay = _results.isNotEmpty;
      if (_showOverlay) _insertOverlay();
      else _removeOverlay();
    } catch (_) {
      _results = [];
      _removeOverlay();
    }
    setState(() => _loading = false);
  }

  void _insertOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(
      builder: (ctx) => Positioned(
        width: 350,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final issue = _results[i];
                  final theme = Theme.of(ctx);
                  return ListTile(
                    dense: true,
                    selected: widget.selectedIssue?.key == issue.key,
                    leading: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.task_alt, size: 14, color: theme.colorScheme.primary),
                    ),
                    title: Text('${issue.key} — ${issue.summary}',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                    subtitle: issue.status != null
                        ? Text(issue.status!,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))
                        : null,
                    onTap: () {
                      widget.onSelected(issue);
                      _searchController.text = '${issue.key} — ${issue.summary}';
                      _searchController.selection = TextSelection.collapsed(offset: _searchController.text.length);
                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() => _showOverlay = true);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    setState(() => _showOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'KEY-123 یا بخشی از عنوان',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _loading
                  ? const SizedBox(width: 20, height: 20, child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                  : (_searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSelected(null);
                            _removeOverlay();
                          },
                        )
                      : null),
            ),
            onChanged: (_) {},
          ),
          if (widget.selectedIssue != null && _searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                avatar: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  radius: 10,
                  child: Icon(Icons.task_alt, size: 12, color: theme.colorScheme.primary),
                ),
                label: Text('${widget.selectedIssue!.key} — ${widget.selectedIssue!.summary}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  widget.onSelected(null);
                  _searchController.clear();
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }
}
