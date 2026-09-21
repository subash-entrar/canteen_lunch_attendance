import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

/// Reads student identifier from NFC tags (NDEF text / URI / tag UID).
class NfcService {
  bool _cancelled = false;

  Future<bool> isAvailable() async {
    final availability = await FlutterNfcKit.nfcAvailability;
    return availability == NFCAvailability.available;
  }

  Future<NfcScanResult> pollStudentPayload({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final available = await isAvailable();
    if (!available) {
      return const NfcScanResult.failure(
        'NFC is not available. Please enable NFC in device settings.',
      );
    }

    _cancelled = false;
    try {
      final tag = await FlutterNfcKit.poll(
        timeout: timeout,
        iosAlertMessage: 'Hold student card near the device',
        readIso14443A: true,
        readIso14443B: true,
        readIso15693: true,
        readIso18092: true,
      );

      if (_cancelled) {
        try {
          await FlutterNfcKit.finish();
        } catch (_) {}
        return const NfcScanResult.cancelled();
      }

      final payloads = <String>[];

      try {
        final records = await FlutterNfcKit.readNDEFRecords();
        for (final record in records) {
          final decoded = _decodeRecord(record);
          if (decoded != null && decoded.trim().isNotEmpty) {
            payloads.add(decoded.trim());
          }
        }
      } catch (_) {}

      final tagId = tag.id.trim();
      if (tagId.isNotEmpty) {
        payloads.add(tagId);
        final asInt = int.tryParse(tagId, radix: 16);
        if (asInt != null) payloads.add(asInt.toString());
      }

      try {
        await FlutterNfcKit.finish();
      } catch (_) {}

      if (_cancelled) return const NfcScanResult.cancelled();

      if (payloads.isEmpty) {
        return const NfcScanResult.failure('Could not read NFC tag data.');
      }

      return NfcScanResult.success(
        payloads: payloads.toSet().toList(),
        rawTagId: tagId,
      );
    } catch (e) {
      try {
        await FlutterNfcKit.finish();
      } catch (_) {}

      if (_cancelled) return const NfcScanResult.cancelled();

      final message = e.toString().toLowerCase();
      if (message.contains('timeout') ||
          message.contains('cancel') ||
          message.contains('4800') ||
          message.contains('tag was lost')) {
        return const NfcScanResult.cancelled();
      }

      return NfcScanResult.failure(e.toString());
    }
  }

  Future<void> stop() async {
    _cancelled = true;
    try {
      await FlutterNfcKit.finish(iosErrorMessage: 'Stopped');
    } catch (_) {
      try {
        await FlutterNfcKit.finish();
      } catch (_) {}
    }
  }

  String? _decodeRecord(ndef.NDEFRecord record) {
    if (record is ndef.TextRecord) return record.text;
    if (record is ndef.UriRecord) return record.uriString;
    final payload = record.payload;
    if (payload == null || payload.isEmpty) return null;
    try {
      return String.fromCharCodes(payload).trim();
    } catch (_) {
      return null;
    }
  }
}

class NfcScanResult {
  const NfcScanResult._({
    required this.ok,
    this.payloads = const [],
    this.rawTagId = '',
    this.error,
    this.cancelled = false,
  });

  const NfcScanResult.success({
    required List<String> payloads,
    String rawTagId = '',
  }) : this._(ok: true, payloads: payloads, rawTagId: rawTagId);

  const NfcScanResult.failure(String error) : this._(ok: false, error: error);

  const NfcScanResult.cancelled()
      : this._(ok: false, cancelled: true, error: 'cancelled');

  final bool ok;
  final bool cancelled;
  final List<String> payloads;
  final String rawTagId;
  final String? error;
}
