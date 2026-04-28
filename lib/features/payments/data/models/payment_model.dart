import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentModel {
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

  const PaymentModel({
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

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      loanId: data['loanId'] ?? '',
      clientId: data['clientId'] ?? '',
      adminId: data['adminId'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      expectedDate: (data['expectedDate'] as Timestamp).toDate(),
      paidDate: data['paidDate'] != null
          ? (data['paidDate'] as Timestamp).toDate()
          : null,
      status: _statusFromString(data['status']),
      method: _methodFromString(data['method']),
      penaltyAmount: (data['penaltyAmount'] as num? ?? 0).toDouble(),
      penaltyReason: data['penaltyReason'] ?? '',
      paymentNumber: data['paymentNumber'] ?? 0,
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  PaymentEntity toEntity() => PaymentEntity(
        id: id,
        loanId: loanId,
        clientId: clientId,
        adminId: adminId,
        amount: amount,
        expectedDate: expectedDate,
        paidDate: paidDate,
        status: status,
        method: method,
        penaltyAmount: penaltyAmount,
        penaltyReason: penaltyReason,
        paymentNumber: paymentNumber,
        notes: notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toFirestore() => {
        'loanId': loanId,
        'clientId': clientId,
        'adminId': adminId,
        'amount': amount,
        'expectedDate': Timestamp.fromDate(expectedDate),
        'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
        'status': status.name,
        'method': method?.name,
        'penaltyAmount': penaltyAmount,
        'penaltyReason': penaltyReason,
        'paymentNumber': paymentNumber,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static PaymentStatus _statusFromString(String value) {
    switch (value) {
      case 'paid':
        return PaymentStatus.paid;
      case 'late':
        return PaymentStatus.late;
      case 'early':
        return PaymentStatus.early;
      default:
        return PaymentStatus.pending;
    }
  }

  static PaymentMethod? _methodFromString(String? value) {
    if (value == null) return null;
    return value == 'cash' ? PaymentMethod.cash : PaymentMethod.transfer;
  }
}
