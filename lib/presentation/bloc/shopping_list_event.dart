part of 'shopping_list_bloc.dart';

abstract class ShoppingListEvent extends Equatable {
  const ShoppingListEvent();

  @override
  List<Object> get props => [];
}

class LoadShoppingLists extends ShoppingListEvent {}

class ShoppingListsUpdated extends ShoppingListEvent {
  final List<ShoppingList> lists;

  const ShoppingListsUpdated(this.lists);

  @override
  List<Object> get props => [lists];
}

class AddShoppingList extends ShoppingListEvent {
  final String name;

  const AddShoppingList(this.name);

  @override
  List<Object> get props => [name];
}

class UpdateShoppingList extends ShoppingListEvent {
  final ShoppingList list;

  const UpdateShoppingList(this.list);

  @override
  List<Object> get props => [list];
}

class DeleteShoppingList extends ShoppingListEvent {
  final String id;

  const DeleteShoppingList(this.id);

  @override
  List<Object> get props => [id];
}
