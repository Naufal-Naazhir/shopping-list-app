abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

// State ketika pembayaran terkonfirmasi sukses
class PaymentSuccess extends PaymentState {
  final String message;
  PaymentSuccess(this.message);
}
