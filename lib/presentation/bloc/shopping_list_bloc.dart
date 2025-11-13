import 'dart:async';
import 'package:belanja_praktis/data/models/shopping_list_model.dart';
import 'package:belanja_praktis/data/repositories/shopping_list_repository.dart';
import 'package:belanja_praktis/data/repositories/auth_repository.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
// import 'package:firebase_auth/firebase_auth.dart' as firebase; // Not directly used here

part 'shopping_list_event.dart';
part 'shopping_list_state.dart';

class ShoppingListBloc extends Bloc<ShoppingListEvent, ShoppingListState> {
  final ShoppingListRepository _shoppingListRepository;
  final AuthRepository _authRepository;
  StreamSubscription? _shoppingListSubscription;
  StreamSubscription? _authStatusSubscription; // Renamed to avoid confusion

  ShoppingListBloc(this._shoppingListRepository, this._authRepository)
    : super(ShoppingListInitial()) {
    // Listen to auth status changes to load/clear lists
    _authStatusSubscription = _authRepository.isLoggedIn().asStream().listen((
      isLoggedIn,
    ) {
      if (isLoggedIn) {
        add(LoadShoppingLists());
      } else {
        // Clear lists if logged out
        add(
          const ShoppingListsUpdated([]),
        ); // Add an event instead of emitting directly
      }
    });

    on<LoadShoppingLists>((event, emit) {
      _shoppingListSubscription?.cancel();
      _shoppingListSubscription = _shoppingListRepository
          .getShoppingLists()
          .listen(
            (lists) => add(ShoppingListsUpdated(lists)),
            onError: (error) => emit(ShoppingListError(error.toString())),
          );
    });

    on<ShoppingListsUpdated>((event, emit) {
      emit(ShoppingListLoaded(event.lists));
    });

    on<AddShoppingList>((event, emit) async {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        emit(const ShoppingListError('User not logged in.'));
        return;
      }
      final newList = ShoppingList(
        id: '', // Firestore will generate this
        userId: currentUser.uid,
        name: event.name,
        createdAt: DateTime.now(),
      );
      await _shoppingListRepository.addList(newList);
    });

    on<UpdateShoppingList>((event, emit) async {
      await _shoppingListRepository.updateList(event.list);
    });

    on<DeleteShoppingList>((event, emit) async {
      try {
        // The repository now handles the logic of moving items and then deleting the list.
        await _shoppingListRepository.deleteListAndMoveItemsToPantry(event.id);
        // The stream listener will automatically handle the UI update.
      } catch (e) {
        emit(ShoppingListError(e.toString()));
      }
    });
  }

  @override
  Future<void> close() {
    _shoppingListSubscription?.cancel();
    _authStatusSubscription?.cancel();
    return super.close();
  }
}
