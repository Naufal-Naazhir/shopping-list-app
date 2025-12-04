part of 'payment_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentFailure extends PaymentState {
  final String message;

  const PaymentFailure(this.message);

  @override
  List<Object> get props => [message];
}

// State to signal the UI to open the WebView
class PaymentWebViewRequired extends PaymentState {
  final String paymentUrl;
  final String merchantOrderId;

  const PaymentWebViewRequired({required this.paymentUrl, required this.merchantOrderId});

  @override
  List<Object> get props => [paymentUrl, merchantOrderId];
}

// State for when payment is successfully verified
class PaymentSuccess extends PaymentState {
  final String statusMessage;
  final String merchantOrderId;

  const PaymentSuccess({required this.statusMessage, required this.merchantOrderId});

  @override
  List<Object> get props => [statusMessage, merchantOrderId];
}
