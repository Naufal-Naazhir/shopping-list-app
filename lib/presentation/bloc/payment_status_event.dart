abstract class PaymentStatusEvent {}

// Event untuk mulai memantau status user (dipanggil saat Home dibuka)
class StartPaymentStatusMonitoring extends PaymentStatusEvent {
  final String userId;
  StartPaymentStatusMonitoring(this.userId);
}

// Event internal ketika ada data masuk dari Realtime
class PaymentStatusUpdated extends PaymentStatusEvent {
  final bool isPremium;
  PaymentStatusUpdated(this.isPremium);
}
