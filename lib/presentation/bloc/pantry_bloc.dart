import 'dart:async';
import 'package:belanja_praktis/data/repositories/pantry_repository.dart';
import 'package:belanja_praktis/data/repositories/shopping_list_repository.dart';
import 'package:belanja_praktis/data/models/pantry_item.dart'; // Re-adding the missing import
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:belanja_praktis/presentation/bloc/pantry_event.dart';
import 'package:belanja_praktis/presentation/bloc/pantry_state.dart';

export 'package:belanja_praktis/presentation/bloc/pantry_state.dart';

class PantryBloc extends Bloc<PantryEvent, PantryState> {
  final PantryRepository _pantryRepository;
  final ShoppingListRepository _shoppingListRepository; // New dependency
  StreamSubscription? _pantrySubscription;

  PantryBloc(this._pantryRepository, this._shoppingListRepository)
    : super(PantryInitial()) {
    on<LoadPantry>((event, emit) async {
      emit(PantryLoading());
      await emit.forEach<List<PantryItem>>(
        _pantryRepository.getPantryItems(),
        onData: (items) => PantryLoaded(items),
        onError: (error, stackTrace) => PantryError(
          [],
          error.toString(),
        ), // Pass empty list for initial load errors
      );
    });

    on<AddPantryItem>((event, emit) async {
      try {
        await _pantryRepository.addPantryItem(event.item);
        // No need to add LoadPantry() here, stream will update automatically
      } catch (e) {
        emit(
          PantryError((state as PantryLoaded).items, e.toString()),
        ); // Pass current items
      }
    });

    on<UpdatePantryItem>((event, emit) async {
      try {
        await _pantryRepository.updatePantryItem(event.item);
        // No need to add LoadPantry() here, stream will update automatically
      } catch (e) {
        emit(
          PantryError((state as PantryLoaded).items, e.toString()),
        ); // Pass current items
      }
    });

    on<DeletePantryItem>((event, emit) async {
      try {
        await _pantryRepository.deletePantryItem(event.id);
        // No need to add LoadPantry() here, stream will update automatically
      } catch (e) {
        emit(
          PantryError((state as PantryLoaded).items, e.toString()),
        ); // Pass current items
      }
    });

    on<ReturnItemToList>((event, emit) async {
      final errorMessage = await _shoppingListRepository.returnPantryItemToList(
        event.item,
      );
      if (errorMessage != null) {
        emit(
          PantryError((state as PantryLoaded).items, errorMessage),
        ); // Pass current items
      }
      // The stream listener will automatically handle the UI update if successful.
    });
  }

  @override
  Future<void> close() {
    _pantrySubscription?.cancel();
    return super.close();
  }
}
