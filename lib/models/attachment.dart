class Attachment {
  final int id;
  final int demandeId;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String uploadedAt;

  Attachment({
    required this.id,
    required this.demandeId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: int.parse(json['id'].toString()),
      demandeId: int.parse(json['demande_id'].toString()),
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: int.parse(json['file_size'].toString()),
      uploadedAt: json['uploaded_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'demande_id': demandeId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_at': uploadedAt,
    };
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get fileExtension {
    return fileName.split('.').last.toUpperCase();
  }

  bool get isImage {
    final ext = fileExtension.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
  }
}
