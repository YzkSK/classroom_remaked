// lib/core/services/drive_file_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/remote/classroom_http_client.dart';
import '../../domain/entities/assignment_material.dart';

/// Google Drive がウイルススキャンできないと判断したファイルのダウンロード時にスローする。
/// ユーザーの確認を得て acknowledgeAbuse: true で再試行する。
class DriveVirusScanWarningException implements Exception {
  const DriveVirusScanWarningException(this.fileId, this.title, this.mimeType);
  final String fileId;
  final String title;
  final String mimeType;
}

/// ファイルを開く方法を表す。
enum DriveOpenAction {
  inAppPdf,
  externalLink,
  nativeOpen,
}

class DriveFileService {
  DriveFileService({required GoogleSignInAccount account})
      : _api = drive.DriveApi(ClassroomHttpClient(account));

  final drive.DriveApi _api;

  static const _workspaceMimeTypes = {
    'application/vnd.google-apps.document',
    'application/vnd.google-apps.spreadsheet',
    'application/vnd.google-apps.presentation',
    'application/vnd.google-apps.form',
  };

  static const _officeMimeToExt = {
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        'docx',
    'application/msword': 'doc',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        'xlsx',
    'application/vnd.ms-excel': 'xls',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        'pptx',
    'application/vnd.ms-powerpoint': 'ppt',
  };

  /// [material] に応じた開き方を決定して実行する。
  /// PDF の場合は [DriveOpenAction.inAppPdf] を返し、bytes は
  /// [downloadPdf] で別途取得すること。
  Future<DriveOpenAction> resolveAndOpen(
    AssignmentMaterial material,
  ) async {
    if (_isWorkspaceMime(material.mimeType)) {
      final uri = Uri.parse(material.url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return DriveOpenAction.externalLink;
    }

    final fileId = material.driveFileId;
    if (fileId != null) {
      final mimeType = material.mimeType ?? await _fetchMimeType(fileId);

      if (mimeType == 'application/pdf') {
        return DriveOpenAction.inAppPdf;
      }

      if (_officeMimeToExt.containsKey(mimeType)) {
        await _openWithNativePicker(fileId, material.title, mimeType);
        return DriveOpenAction.nativeOpen;
      }
    }

    final uri = Uri.parse(material.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return DriveOpenAction.externalLink;
  }

  /// PDF ファイルのバイト列を取得する（FileViewerScreen の provider で使用）。
  /// Drive がウイルススキャンできない場合は [DriveVirusScanWarningException] をスロー。
  Future<Uint8List> downloadPdf(String fileId) =>
      _rawDownload(fileId, acknowledgeAbuse: false);

  /// ユーザーが確認済みの場合に acknowledgeAbuse=true で再ダウンロードする。
  Future<Uint8List> downloadPdfWithAcknowledge(String fileId) =>
      _rawDownload(fileId, acknowledgeAbuse: true);

  /// [DriveVirusScanWarningException] に対してユーザーが承認済みの場合に
  /// acknowledgeAbuse=true で再試行する（非 PDF ファイル用）。
  Future<void> openWithAcknowledge(DriveVirusScanWarningException e) =>
      _openWithNativePickerAcknowledged(e.fileId, e.title, e.mimeType);

  Future<Uint8List> _rawDownload(
    String fileId, {
    required bool acknowledgeAbuse,
  }) async {
    try {
      final media = await _api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
        acknowledgeAbuse: acknowledgeAbuse,
      ) as drive.Media;
      return _readStream(media.stream);
    } on Exception catch (e) {
      if (!acknowledgeAbuse &&
          e.toString().contains('cannotDownloadAbusiveFile')) {
        throw DriveVirusScanWarningException(fileId, '', 'application/pdf');
      }
      rethrow;
    }
  }

  Future<String> _fetchMimeType(String fileId) async {
    final meta = await _api.files.get(
      fileId,
      $fields: 'mimeType',
    ) as drive.File;
    return meta.mimeType ?? 'application/octet-stream';
  }

  Future<void> _openWithNativePicker(
    String fileId,
    String title,
    String mimeType,
  ) async {
    try {
      final media = await _api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      final bytes = await _readStream(media.stream);
      final ext = _officeMimeToExt[mimeType] ?? 'bin';
      final safeName = title.replaceAll(RegExp(r'[^\w\s.-]'), '_');
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/$safeName.$ext');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } on Exception catch (e) {
      if (e.toString().contains('cannotDownloadAbusiveFile')) {
        throw DriveVirusScanWarningException(fileId, title, mimeType);
      }
      rethrow;
    }
  }

  Future<void> _openWithNativePickerAcknowledged(
    String fileId,
    String title,
    String mimeType,
  ) async {
    final media = await _api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
      acknowledgeAbuse: true,
    ) as drive.Media;
    final bytes = await _readStream(media.stream);
    final ext = _officeMimeToExt[mimeType] ?? 'bin';
    final safeName = title.replaceAll(RegExp(r'[^\w\s.-]'), '_');
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/$safeName.$ext');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  Future<Uint8List> _readStream(Stream<List<int>> stream) async {
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }

  static bool _isWorkspaceMime(String? mime) =>
      mime != null && _workspaceMimeTypes.contains(mime);
}
