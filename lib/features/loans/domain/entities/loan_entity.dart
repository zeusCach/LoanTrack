import 'package:equatable/equatable.dart';

enum LoanFrequency { weekly, biweekly, monthly }

enum LoanStatus { active, completed, defaulted }

class LoanEntity extends Equatable {
  final String id;
  final String clientId;
  final String adminId;
  final double totalAmount;
  final int totalPayments;
  final double paymentAmount;
  final LoanFrequency frequency;
  final DateTime startDate;
  final DateTime endDate;
  final LoanStatus status;
  final double interestRate;
  final DateTime createdAt;

  const LoanEntity({
    required this.id,
    required this.clientId,
    required this.adminId,
    required this.totalAmount,
    required this.totalPayments,
    required this.paymentAmount,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.interestRate,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, clientId, status];
}
