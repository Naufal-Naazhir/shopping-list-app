import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fpdart/fpdart.dart';

class PaymentFailure {
  final String message;
  PaymentFailure(this.message);

  @override
  String toString() => message;
}

class PaymentRepository {
  final Functions _functions;

  PaymentRepository({required Functions functions}) : _functions = functions;

  String get _handlePaymentFunctionId =>
      dotenv.get('APPWRITE_HANDLE_PAYMENT_FUNCTION_ID');
  String get _checkTransactionFunctionId =>
      dotenv.get('APPWRITE_CHECK_TRANSACTION_FUNCTION_ID');

  Future<Either<PaymentFailure, String>> initiatePayment({
    required int amount,
    required String productDetails,
    required String merchantOrderId,
  }) async {
    try {
      final requestBody = jsonEncode({
        'amount': amount,
        'productDetails': productDetails,
        'merchantOrderId': merchantOrderId,
      });

      print('Sending body to Appwrite function: $requestBody'); // Added logging

      final result = await _functions.createExecution(
        functionId: _handlePaymentFunctionId,
        body: requestBody,
      );

      if (result.status.name == 'completed') {
        final responseData = jsonDecode(result.responseBody);
        if (responseData['paymentUrl'] != null) {
          return right(responseData['paymentUrl']);
        } else {
          final error =
              responseData['error'] ?? 'Payment URL not found in response.';
          return left(PaymentFailure('Failed to get payment URL: $error'));
        }
      } else {
        final error =
            jsonDecode(result.responseBody)['error'] ??
            'Unknown error during payment initiation.';
        return left(PaymentFailure('Failed to initiate payment: $error'));
      }
    } on AppwriteException catch (e) {
      return left(
        PaymentFailure(e.message ?? 'An unknown Appwrite error occurred.'),
      );
    } catch (e) {
      return left(PaymentFailure('An unexpected error occurred: $e'));
    }
  }

  Future<Either<PaymentFailure, Map<String, dynamic>>> checkPaymentStatus({
    required String merchantOrderId,
  }) async {
    try {
      final result = await _functions.createExecution(
        functionId: _checkTransactionFunctionId,
        body: jsonEncode({'merchantOrderId': merchantOrderId}),
      );

      if (result.status.name == 'completed') {
        final responseData = jsonDecode(result.responseBody);
        if (responseData['success'] == true) {
          return right(responseData['transactionStatus']);
        } else {
          return left(
            PaymentFailure(
              responseData['message'] ?? 'Failed to verify payment.',
            ),
          );
        }
      } else {
        final error =
            jsonDecode(result.responseBody)['error'] ??
            'Unknown error during payment verification.';
        return left(PaymentFailure('Failed to check payment status: $error'));
      }
    } on AppwriteException catch (e) {
      return left(
        PaymentFailure(e.message ?? 'An unknown Appwrite error occurred.'),
      );
    } catch (e) {
      return left(PaymentFailure('An unexpected error occurred: $e'));
    }
  }
}
