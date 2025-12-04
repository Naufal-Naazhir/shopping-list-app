abstract class PaymentEvent {}

// Event untuk mulai memantau status user (dipanggil saat Home dibuka)
class StartPaymentMonitoring extends PaymentEvent {
  final String userId;
  StartPaymentMonitoring(this.userId);
}

// Event internal ketika ada data masuk dari Realtime
class PaymentStatusUpdated extends PaymentEvent {
  final bool isPremium;
  PaymentStatusUpdated(this.isPremium);
}
