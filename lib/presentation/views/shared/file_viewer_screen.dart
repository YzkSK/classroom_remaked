// lib/presentation/views/shared/file_viewer_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/di/providers.dart';
import '../../../core/services/drive_file_service.dart';

class FileViewerScreen extends ConsumerStatefulWidget {
  const FileViewerScreen({
    super.key,
    required this.fileId,
    required this.title,
  });

  final String fileId;
  final String title;

  @override
  ConsumerState<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends ConsumerState<FileViewerScreen> {
  PdfController? _controller;
  Uint8List? _acknowledgedBytes;
  bool _acknowledgeLoading = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _downloadWithAcknowledge() async {
    setState(() => _acknowledgeLoading = true);
    try {
      final bytes = await ref
          .read(driveFileServiceProvider)
          .downloadPdfWithAcknowledge(widget.fileId);
      if (!mounted) return;
      setState(() {
        _acknowledgedBytes = bytes;
        _controller = PdfController(document: PdfDocument.openData(bytes));
        _acknowledgeLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _acknowledgeLoading = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('ダウンロードに失敗しました'),
          description: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_acknowledgedBytes != null && _controller != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: PdfView(
          controller: _controller!,
          scrollDirection: Axis.vertical,
        ),
      );
    }

    final async = ref.watch(fileViewerProvider(widget.fileId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          if (e is DriveVirusScanWarningException) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'このファイルはウイルススキャンができませんでした。\nダウンロードを続けますか？',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ShadButton(
                      onPressed: _acknowledgeLoading
                          ? null
                          : _downloadWithAcknowledge,
                      child: _acknowledgeLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('ダウンロードする'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '読み込みに失敗しました\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        data: (bytes) {
          _controller ??= PdfController(
            document: PdfDocument.openData(bytes),
          );
          return PdfView(
            controller: _controller!,
            scrollDirection: Axis.vertical,
          );
        },
      ),
    );
  }
}
