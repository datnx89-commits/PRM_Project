class RevenueByDay {
  final String date;
  final double revenue;
  final int bookingCount;

  RevenueByDay({
    required this.date,
    required this.revenue,
    required this.bookingCount,
  });
}

class TopField {
  final String fieldName;
  final int bookingCount;
  final double revenue;

  TopField({
    required this.fieldName,
    required this.bookingCount,
    required this.revenue,
  });
}

class ReportSummary {
  final double totalRevenue;
  final int totalBookings;
  final int totalCustomers;
  final int totalFields;
  final List<RevenueByDay> revenueByDays;
  final List<TopField> topFields;

  ReportSummary({
    required this.totalRevenue,
    required this.totalBookings,
    required this.totalCustomers,
    required this.totalFields,
    required this.revenueByDays,
    required this.topFields,
  });
}
