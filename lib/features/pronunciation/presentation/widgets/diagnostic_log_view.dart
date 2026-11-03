// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/pronunciation_logger.dart';

/// Live diagnostic log console displayed on the UI to monitor real-time function calls,
/// audio capture stages, and potential errors.
class DiagnosticLogView extends StatefulWidget {
  const DiagnosticLogView({super.key});

  @override
  State<DiagnosticLogView> createState() => _DiagnosticLogViewState();
}

class _DiagnosticLogViewState extends State<DiagnosticLogView> {
  bool _isExpanded = false;
  final List<LogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _logs.addAll(PronunciationLogger.history);
    PronunciationLogger.stream.listen((entry) {
      if (!mounted) return;
      setState(() {
        _logs.add(entry);
        if (_logs.length > 100) _logs.removeAt(0);
      });
    });
  }

  void _copyLogs() {
    final text = _logs.map((e) => e.toString()).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép nhật ký hệ thống vào bộ nhớ tạm')),
    );
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      PronunciationLogger.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E), // dark console theme
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header toggle bar
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.terminal_rounded, size: 20, color: Color(0xFF89B4FA)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Nhật ký hệ thống & Chẩn đoán lỗi (Live Logs)',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: const Color(0xFFCDD6F4),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_logs.length}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isExpanded) ...[
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                      onPressed: _copyLogs,
                      tooltip: 'Sao chép log',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white70),
                      onPressed: _clearLogs,
                      tooltip: 'Xóa log',
                    ),
                  ],
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),

          // Log terminal content
          if (_isExpanded) ...[
            const Divider(color: Colors.white12, height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(12),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có log ghi nhận. Hãy bắt đầu ghi âm hoặc thao tác để xem log thời gian thực.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color tagColor = const Color(0xFF89B4FA);
                        if (log.level == LogLevel.warning) tagColor = const Color(0xFFF9E2AF);
                        if (log.level == LogLevel.error) tagColor = const Color(0xFFF38BA8);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: SelectableText.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '[${log.formattedTime}] ',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                                TextSpan(
                                  text: '[${log.tag}] ',
                                  style: TextStyle(
                                    color: tagColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                TextSpan(
                                  text: log.message,
                                  style: TextStyle(
                                    color: log.level == LogLevel.error
                                        ? const Color(0xFFF38BA8)
                                        : const Color(0xFFCDD6F4),
                                    fontSize: 12,
                                  ),
                                ),
                                if (log.details != null)
                                  TextSpan(
                                    text: ' (${log.details})',
                                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
