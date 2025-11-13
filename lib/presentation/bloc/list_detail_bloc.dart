import 'package:belanja_praktis/data/models/shopping_list_model.dart';
import 'package:belanja_praktis/data/repositories/shopping_list_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:belanja_praktis/presentation/bloc/list_detail_state.dart';
export 'package:belanja_praktis/presentation/bloc/list_detail_state.dart';
part 'list_detail_event.dart';

class ListDetailBloc extends Bloc<ListDetailEvent, ListDetailState> {
  final ShoppingListRepository _shoppingListRepository;

  ListDetailBloc(this._shoppingListRepository) : super(ListDetailInitial()) {
    on<LoadListDetail>((event, emit) async {
      emit(ListDetailLoading());
      try {
        // We don't need to get the full shopping list object here,
        // just the items for the given listId.
        final items = await _shoppingListRepository.getShoppingItems(
          event.listId,
        );
        emit(ListDetailLoaded(items));
      } catch (e) {
        emit(ListDetailError(e.toString()));
      }
    });

    on<AddShoppingItem>((event, emit) async {
      try {
        await _shoppingListRepository.addItemToList(event.listId, event.item);
        add(LoadListDetail(event.listId)); // Reload the list to reflect changes
      } catch (e) {
        emit(ListDetailError(e.toString()));
      }
    });

    on<ToggleShoppingItem>((event, emit) async {
      try {
        await _shoppingListRepository.toggleItemCompletion(
          event.listId,
          event.itemId,
          event.isCompleted,
        );
        add(LoadListDetail(event.listId)); // Reload the list to reflect changes
      } catch (e) {
        emit(ListDetailError(e.toString()));
      }
    });

    on<DeleteShoppingItem>((event, emit) async {
      try {
        await _shoppingListRepository.deleteItemFromList(
          event.listId,
          event.itemId,
        );
        add(LoadListDetail(event.listId)); // Reload the list to reflect changes
      } catch (e) {
        emit(ListDetailError(e.toString()));
      }
    });

    on<MoveToPantry>((event, emit) async {
      try {
        await _shoppingListRepository.moveItemToPantry(
          event.listId,
          event.item,
        );
        add(
          LoadListDetail(event.listId),
        ); // Reload the list to show the item has been removed
      } catch (e) {
        emit(ListDetailError(e.toString()));
      }
    });

    on<UpdateShoppingItem>((event, emit) async {
      try {
        await _shoppingListRepository.updateItemInList(
          event.listId,
          event.item,
        );
        add(LoadListDetail(event.listId)); // Reload the list to reflect changes
      } catch (e) {
        emit(ListDetailError(e.toString()));
      }
    });
  }
}
