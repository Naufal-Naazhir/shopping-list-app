import 'package:belanja_praktis/data/models/shopping_list_model.dart';
import 'package:flutter/material.dart';

class ShoppingItemCard extends StatelessWidget {
  final ShoppingItem item;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onMoveToPantry; // New callback
  final VoidCallback onEdit;
  final String Function(double) formatPrice;

  const ShoppingItemCard({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onMoveToPantry, // New callback
    required this.onEdit,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final itemPrice = formatPrice(item.price);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        children: [
          Checkbox(
            value: item.isBought,
            onChanged: onToggle,
            activeColor: Theme.of(context).colorScheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 17,
                    color: item.isBought
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5)
                        : Theme.of(context).colorScheme.onSurface,
                    decoration: item.isBought
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                Text(
                  itemPrice,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.isBought
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5)
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.kitchen_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: onMoveToPantry, // New trigger
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
