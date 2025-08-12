class AnnouncementAttachment {
  final int id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String fileType;
  final DateTime uploadedAt;

  AnnouncementAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.uploadedAt,
  });

  factory AnnouncementAttachment.fromJson(Map<String, dynamic> json) {
    return AnnouncementAttachment(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fileName: json['file_name']?.toString() ?? '',
      filePath: json['file_path']?.toString() ?? '',
      fileSize: int.tryParse(json['file_size']?.toString() ?? '0') ?? 0,
      fileType: json['file_type']?.toString() ?? '',
      uploadedAt: DateTime.tryParse(json['uploaded_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  bool get isImage {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final extension = filePath.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  String get fullUrl {
    // Assuming the base URL for attachments
    const String baseUrl = 'https://thistruck.app';
    return '$baseUrl/$filePath';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'file_type': fileType,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

class AnnouncementModel {
  final int id;
  final String title;
  final String content;
  final bool isActive;
  final int priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<int> targetGroups;
  final List<AnnouncementAttachment> attachments;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.isActive,
    required this.priority,
    this.startDate,
    this.endDate,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.targetGroups,
    required this.attachments,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isActive: json['is_active']?.toString() == '1',
      priority: int.tryParse(json['priority']?.toString() ?? '1') ?? 1,
      startDate: json['start_date'] != null 
          ? DateTime.tryParse(json['start_date'].toString()) 
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.tryParse(json['end_date'].toString()) 
          : null,
      createdBy: json['created_by'] != null 
          ? int.tryParse(json['created_by'].toString()) 
          : null,
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now(),
      targetGroups: json['target_groups'] is List 
          ? List<int>.from(json['target_groups'])
          : [],
      attachments: json['attachments'] is List 
          ? (json['attachments'] as List)
              .map((attachment) => AnnouncementAttachment.fromJson(attachment))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_active': isActive ? 1 : 0,
      'priority': priority,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'target_groups': targetGroups,
      'attachments': attachments.map((attachment) => attachment.toJson()).toList(),
    };
  }

  String get priorityText {
    switch (priority) {
      case 1:
        return 'ต่ำ';
      case 2:
        return 'ปานกลาง';
      case 3:
        return 'สูง';
      case 4:
        return 'ด่วนมาก';
      default:
        return 'ปานกลาง';
    }
  }

  bool get isCurrentlyActive {
    if (!isActive) return false;
    
    final now = DateTime.now();
    
    // ตรวจสอบวันที่เริ่มต้น
    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }
    
    // ตรวจสอบวันที่สิ้นสุด
    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }
    
    return true;
  }

  bool get isForDrivers {
    return targetGroups.contains(2); // 2 = Drivers
  }

  List<AnnouncementAttachment> get imageAttachments {
    return attachments.where((attachment) => attachment.isImage).toList();
  }

  bool get hasImages {
    return imageAttachments.isNotEmpty;
  }
}