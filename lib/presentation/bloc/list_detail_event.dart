part of 'list_detail_bloc.dart';

abstract class ListDetailEvent extends Equatable {
  const ListDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadListDetail extends ListDetailEvent {
  final String listId;

  const LoadListDetail(this.listId);

  @override
  List<Object?> get props => [listId];
}

class AddShoppingItem extends ListDetailEvent {
  final String listId;
  final ShoppingItem item;

  const AddShoppingItem(this.listId, this.item);

  @override
  List<Object?> get props => [listId, item];
}

class ToggleShoppingItem extends ListDetailEvent {
  final String listId;
  final String itemId;
  final bool isCompleted;

  const ToggleShoppingItem(this.listId, this.itemId, this.isCompleted);

  @override
  List<Object?> get props => [listId, itemId, isCompleted];
}

class DeleteShoppingItem extends ListDetailEvent {
  final String listId;
  final String itemId;

  const DeleteShoppingItem(this.listId, this.itemId);

  @override
  List<Object?> get props => [listId, itemId];
}

class MoveToPantry extends ListDetailEvent {
  final String listId;
  final ShoppingItem item;
  final DateTime? expiryDate;

  const MoveToPantry(this.listId, this.item, {this.expiryDate});

  @override
  List<Object?> get props => [listId, item, expiryDate];
}

class UpdateShoppingItem extends ListDetailEvent {
  final String listId;
  final ShoppingItem item;

  const UpdateShoppingItem(this.listId, this.item);

  @override
  List<Object?> get props => [listId, item];
}
