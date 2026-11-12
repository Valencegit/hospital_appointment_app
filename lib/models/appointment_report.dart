class AppointmentReport {
  final int total;
  final Map<String, int> statusCounts;
  final Map<String, int> departmentCounts;

  const AppointmentReport({
    required this.total,
    required this.statusCounts,
    required this.departmentCounts,
  });
}
