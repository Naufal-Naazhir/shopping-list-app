import 'package:belanja_praktis/data/models/shopping_list_model.dart';
import 'package:belanja_praktis/data/repositories/shopping_list_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class ListCard extends StatefulWidget {
  final ShoppingList list;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ListCard({
    super.key,
    required this.list,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ListCard> createState() => _ListCardState();
}

class _ListCardState extends State<ListCard> {
  final ShoppingListRepository _shoppingListRepository =
      GetIt.I<ShoppingListRepository>();
  int _totalItems = 0;
  int _checkedItems = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItemCounts();
  }

  @override
  void didUpdateWidget(covariant ListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the list object is different (e.g., due to a stream update with a new timestamp),
    // re-fetch the counts.
    if (widget.list != oldWidget.list) {
      _fetchItemCounts();
    }
  }

  Future<void> _fetchItemCounts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _shoppingListRepository.getShoppingItems(
        widget.list.id,
      );
      if (mounted) {
        setState(() {
          _totalItems = items.length;
          _checkedItems = items.where((item) => item.isBought).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Optionally handle error display here
      print('Failed to load item counts for list ${widget.list.id}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = _totalItems > 0 ? (_checkedItems / _totalItems) : 0.0;

    return GestureDetector(
      onTap: () {
        context.go('/list/${widget.list.id}');
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.list.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          '$_checkedItems/$_totalItems',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                          ),
                        ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      _showListMenu(context);
                    },
                    child: const Icon(
                      Icons.more_vert,
                      color: Color(0xFF888888),
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE9ECEF),
                color: const Color(0xFF22B14C),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showListMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 24),
              ),
              Text(
                widget.list.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(bc); // Close bottom sheet
                    widget.onEdit();
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'Edit Name',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF2196F3).withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(bc); // Close bottom sheet
                    widget.onDelete();
                  },
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text(
                    'Delete List',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFFFF6B6B).withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(bc); // Close bottom sheet
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
