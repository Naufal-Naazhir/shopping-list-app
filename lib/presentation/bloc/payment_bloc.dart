import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appwrite/appwrite.dart';
import 'package:belanja_praktis/config/appwrite_db.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  late Realtime realtime;
  RealtimeSubscription? subscription;
  final Client client;

  // Constructor: Inisialisasi Appwrite Client
  PaymentBloc(this.client) : super(PaymentInitial()) {
    realtime = Realtime(client);

    // Registrasi Handler
    on<StartPaymentMonitoring>(_onStartMonitoring);
    on<PaymentStatusUpdated>(_onStatusUpdated);
  }

  // Logic 1: Mulai Berlangganan (Subscribe)
  void _onStartMonitoring(StartPaymentMonitoring event, Emitter<PaymentState> emit) {
    // Pastikan tidak double subscription
    subscription?.close();

    final dbId = AppwriteDB.databaseId;
    final colId = AppwriteDB.usersCollectionId;
    final docId = event.userId;

    // Subscribe ke dokumen spesifik user ini
    subscription = realtime.subscribe([
      'databases.$dbId.collections.$colId.documents.$docId'
    ]);

    // Dengarkan stream
    subscription!.stream.listen((realtimeEvent) {
      if (realtimeEvent.events.any((e) => e.contains('.documents.${event.userId}.update'))) {
        final payload = realtimeEvent.payload;
        
        // Cek apakah status berubah jadi premium
        if (payload['is_premium'] == true) {
          // JANGAN emit langsung di dalam listen, tapi panggil Event baru
          add(PaymentStatusUpdated(true));
        }
      }
    });
  }

  // Logic 2: Update State ke UI
  void _onStatusUpdated(PaymentStatusUpdated event, Emitter<PaymentState> emit) {
    if (event.isPremium) {
      emit(PaymentSuccess("Selamat! Akun Anda kini Premium."));
    }
  }

  @override
  Future<void> close() {
    subscription?.close(); // PENTING: Tutup koneksi agar tidak memory leak
    return super.close();
  }
}
