import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:belanja_praktis/data/repositories/payment_repository.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;

  PaymentBloc({required PaymentRepository paymentRepository})
      : _paymentRepository = paymentRepository,
        super(PaymentInitial()) {
    on<InitiatePayment>(_onInitiatePayment);
    on<CheckPaymentStatus>(_onCheckPaymentStatus);
  }

  Future<void> _onInitiatePayment(
    InitiatePayment event,
    Emitter<PaymentState> emit,
  ) async {
    print('PaymentBloc: _onInitiatePayment event received'); // Added logging
    emit(PaymentLoading());
    
    // Generate a unique order ID for this transaction
    final merchantOrderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';

    final result = await _paymentRepository.initiatePayment(
      amount: event.amount,
      productDetails: event.productDetails,
      merchantOrderId: merchantOrderId,
    );

    result.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (paymentUrl) => emit(PaymentWebViewRequired(
        paymentUrl: paymentUrl,
        merchantOrderId: merchantOrderId,
      )),
    );
  }

  Future<void> _onCheckPaymentStatus(
    CheckPaymentStatus event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    final result = await _paymentRepository.checkPaymentStatus(
      merchantOrderId: event.merchantOrderId,
    );

    result.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (status) {
        // Duitku status codes: 00=Success, 01=Pending, 02=Failed
        final statusCode = status['statusCode'];
        final statusMessage = status['statusMessage'];

        if (statusCode == '00') {
          emit(PaymentSuccess(
            statusMessage: statusMessage,
            merchantOrderId: event.merchantOrderId,
          ));
        } else {
          emit(PaymentFailure(
            'Payment not successful. Status: $statusMessage',
          ));
        }
      },
    );
  }
}
