class CrimeReport {
  final int? id;
  final String title;
  final String description;
  final String severity;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime incidentDate;
  final int? reportedBy;
  final String? reportImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CrimeReport({
    this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.incidentDate,
    this.reportedBy,
    this.reportImage,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'severity': severity,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'incident_date': incidentDate.toIso8601String().split('T')[0],
      'reported_by': reportedBy,
    };
  }

  factory CrimeReport.fromJson(Map<String, dynamic> json) {
    return CrimeReport(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: json['severity'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      address: json['address'],
      incidentDate: DateTime.parse(json['incident_date']),
      reportedBy: json['reported_by'],
      reportImage: json['report_image'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}