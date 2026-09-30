import 'package:cloud_firestore/cloud_firestore.dart';

class AppDownloadConfig {
  final String downloadUrl;
  final String? minVersion;
  final DateTime? updatedAt;
  final String? updatedBy;
  final String? notes;

  const AppDownloadConfig({
    required this.downloadUrl,
    this.minVersion,
    this.updatedAt,
    this.updatedBy,
    this.notes,
  });

  bool get hasValidUrl => downloadUrl.trim().isNotEmpty;

  bool get hasMinimumVersionRequirement =>
      minVersion != null && minVersion!.trim().isNotEmpty;

  /// Checks if [currentVersion] is strictly less than [minVersion].
  bool isUpdateRequired(String currentVersion) {
    if (!hasMinimumVersionRequirement) return false;
    return isVersionLesser(currentVersion, minVersion!);
  }

  /// Compares two semver version strings (e.g. 1.0.0, v1.0.1, 1.0.0+2).
  /// Returns `true` if [current] is strictly less than [minimum].
  static bool isVersionLesser(String current, String minimum) {
    if (minimum.trim().isEmpty) return false;

    // Strip leading 'v' or 'V'
    String cleanCur = current.trim().toLowerCase().replaceAll(RegExp(r'^v'), '');
    String cleanMin = minimum.trim().toLowerCase().replaceAll(RegExp(r'^v'), '');

    // Split version and build number (e.g. 1.0.0+2)
    final curBuildParts = cleanCur.split('+');
    final minBuildParts = cleanMin.split('+');

    final curVerParts = curBuildParts[0]
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final minVerParts = minBuildParts[0]
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    // Pad with zeros to 3 parts (major, minor, patch)
    while (curVerParts.length < 3) {
      curVerParts.add(0);
    }
    while (minVerParts.length < 3) {
      minVerParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (curVerParts[i] < minVerParts[i]) return true;
      if (curVerParts[i] > minVerParts[i]) return false;
    }

    // If semver parts are identical, compare build number if provided in minimum
    if (minBuildParts.length > 1) {
      final minBuild = int.tryParse(minBuildParts[1]) ?? 0;
      final curBuild = curBuildParts.length > 1
          ? (int.tryParse(curBuildParts[1]) ?? 0)
          : 0;
      if (curBuild < minBuild) return true;
    }

    return false;
  }

  factory AppDownloadConfig.fromMap(Map<String, dynamic> map) {
    DateTime? updated;
    final rawUpdated = map['updatedAt'];
    if (rawUpdated is Timestamp) {
      updated = rawUpdated.toDate();
    } else if (rawUpdated is String) {
      updated = DateTime.tryParse(rawUpdated);
    }

    return AppDownloadConfig(
      downloadUrl: (map['downloadUrl'] as String?)?.trim() ?? '',
      minVersion: (map['minVersion'] as String?)?.trim(),
      updatedAt: updated,
      updatedBy: map['updatedBy'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'downloadUrl': downloadUrl,
      if (minVersion != null && minVersion!.trim().isNotEmpty)
        'minVersion': minVersion!.trim(),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (notes != null) 'notes': notes,
    };
  }

  AppDownloadConfig copyWith({
    String? downloadUrl,
    String? minVersion,
    DateTime? updatedAt,
    String? updatedBy,
    String? notes,
  }) {
    return AppDownloadConfig(
      downloadUrl: downloadUrl ?? this.downloadUrl,
      minVersion: minVersion ?? this.minVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      notes: notes ?? this.notes,
    );
  }
}
