import 'package:equatable/equatable.dart';
import 'package:belanja_praktis/data/models/shopping_list_model.dart'; // Corrected import

abstract class ListDetailState extends Equatable {
  const ListDetailState();

  @override
  List<Object> get props => [];
}

class ListDetailInitial extends ListDetailState {}

class ListDetailLoading extends ListDetailState {}

class ListDetailLoaded extends ListDetailState {
  final List<ShoppingItem> items;

  const ListDetailLoaded(this.items);

  @override
  List<Object> get props => [items];
}

class ListDetailError extends ListDetailState {
  final String message;

  const ListDetailError(this.message);

  @override
  List<Object> get props => [message];
}
