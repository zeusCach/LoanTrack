import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/loan_entity.dart';

class LoanModel {
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

  const LoanModel({
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

  factory LoanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoanModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      adminId: data['adminId'] ?? '',
      totalAmount: (data['totalAmount'] as num).toDouble(),
      totalPayments: data['totalPayments'] ?? 0,
      paymentAmount: (data['paymentAmount'] as num).toDouble(),
      frequency: frequencyFromString(data['frequency']),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: _statusFromString(data['status']),
      interestRate: (data['interestRate'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  LoanEntity toEntity() => LoanEntity(
        id: id,
        clientId: clientId,
        adminId: adminId,
        totalAmount: totalAmount,
        totalPayments: totalPayments,
        paymentAmount: paymentAmount,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        status: status,
        interestRate: interestRate,
        createdAt: createdAt,
      );

  Map<String, dynamic> toFirestore() => {
        'clientId': clientId,
        'adminId': adminId,
        'totalAmount': totalAmount,
        'totalPayments': totalPayments,
        'paymentAmount': paymentAmount,
        'frequency': frequency.name,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'status': status.name,
        'interestRate': interestRate,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static LoanFrequency frequencyFromString(String value) {
    switch (value) {
      case 'weekly':
        return LoanFrequency.weekly;
      case 'biweekly':
        return LoanFrequency.biweekly;
      default:
        return LoanFrequency.monthly;
    }
  }

  static LoanStatus _statusFromString(String value) {
    switch (value) {
      case 'completed':
        return LoanStatus.completed;
      case 'defaulted':
        return LoanStatus.defaulted;
      default:
        return LoanStatus.active;
    }
  }
}
