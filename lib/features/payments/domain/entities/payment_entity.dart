import 'package:equatable/equatable.dart';

enum PaymentStatus { pending, paid, late, early }

enum PaymentMethod { cash, transfer }

class PaymentEntity extends Equatable {
  final String id;
  final String loanId;
  final String clientId;
  final String adminId;
  final double amount;
  final DateTime expectedDate;
  final DateTime? paidDate;
  final PaymentStatus status;
  final PaymentMethod? method;
  final double penaltyAmount;
  final String penaltyReason;
  final int paymentNumber;
  final String notes;
  final DateTime createdAt;

  const PaymentEntity({
    required this.id,
    required this.loanId,
    required this.clientId,
    required this.adminId,
    required this.amount,
    required this.expectedDate,
    this.paidDate,
    required this.status,
    this.method,
    required this.penaltyAmount,
    required this.penaltyReason,
    required this.paymentNumber,
    required this.notes,
    required this.createdAt,
  });

  bool get isPaid => status == PaymentStatus.paid;
  bool get isLate => status == PaymentStatus.late;
  bool get hasPenalty => penaltyAmount > 0;

  @override
  List<Object?> get props => [id, loanId, paymentNumber];
}
