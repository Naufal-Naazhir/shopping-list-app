import 'package:equatable/equatable.dart';
import 'package:belanja_praktis/data/models/pantry_item.dart';

abstract class PantryState extends Equatable {
  const PantryState();

  @override
  List<Object> get props => [];
}

class PantryInitial extends PantryState {}

class PantryLoading extends PantryState {}

class PantryLoaded extends PantryState {
  final List<PantryItem> items;

  const PantryLoaded(this.items);

  @override
  List<Object> get props => [items];
}

class PantryError extends PantryLoaded {
  final String message;

  const PantryError(List<PantryItem> items, this.message) : super(items);

  @override
  List<Object> get props => [items, message];
}
