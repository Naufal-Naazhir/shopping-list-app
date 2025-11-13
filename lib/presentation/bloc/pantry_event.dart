import 'package:equatable/equatable.dart';
import 'package:belanja_praktis/data/models/pantry_item.dart';

abstract class PantryEvent extends Equatable {
  const PantryEvent();

  @override
  List<Object> get props => [];
}

class LoadPantry extends PantryEvent {}

class AddPantryItem extends PantryEvent {
  final PantryItem item;

  const AddPantryItem(this.item);

  @override
  List<Object> get props => [item];
}

class UpdatePantryItem extends PantryEvent {
  final PantryItem item;

  const UpdatePantryItem(this.item);

  @override
  List<Object> get props => [item];
}

class DeletePantryItem extends PantryEvent {
  final String id;

  const DeletePantryItem(this.id);

  @override
  List<Object> get props => [id];
}

class ReturnItemToList extends PantryEvent {
  final PantryItem item;

  const ReturnItemToList(this.item);

  @override
  List<Object> get props => [item];
}
