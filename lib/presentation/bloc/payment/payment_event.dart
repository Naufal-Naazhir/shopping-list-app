part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

class InitiatePayment extends PaymentEvent {
  final int amount;
  final String productDetails;

  const InitiatePayment({required this.amount, required this.productDetails});

  @override
  List<Object> get props => [amount, productDetails];
}

class CheckPaymentStatus extends PaymentEvent {
  final String merchantOrderId;

  const CheckPaymentStatus({required this.merchantOrderId});

  @override
  List<Object> get props => [merchantOrderId];
}
