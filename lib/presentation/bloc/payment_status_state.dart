abstract class PaymentStatusState {}

class PaymentStatusInitial extends PaymentStatusState {}

// State ketika pembayaran terkonfirmasi sukses
class PaymentStatusSuccess extends PaymentStatusState {
  final String message;
  PaymentStatusSuccess(this.message);
}
