import 'dart:io';
import 'package:flutter/material.dart';

import '../models/campaign_shop.dart';
import '../models/item_definition.dart';
import '../services/item_library_service.dart';
import 'item_form_screen.dart';

class CampaignShopFormScreen extends StatefulWidget {
  final CampaignShop? shop;
  const CampaignShopFormScreen({super.key, this.shop});

  @override
  State<CampaignShopFormScreen> createState() => _CampaignShopFormScreenState();
}

class _CampaignShopFormScreenState extends State<CampaignShopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _currencyName;
  late CampaignShopCurrencyKind _currencyKind;
  ItemDefinition? _currencyItem;
  late List<CampaignShopProduct> _products;

  @override
  void initState() {
    super.initState();
    final shop = widget.shop;
    _name = TextEditingController(text: shop?.name ?? '');
    _description = TextEditingController(text: shop?.description ?? '');
    _currencyName = TextEditingController(text: shop?.currencyName ?? 'Oro');
    _currencyKind = shop?.currencyKind ?? CampaignShopCurrencyKind.resource;
    _currencyItem = shop?.currencyItem == null
        ? null
        : ItemDefinition.fromMap(shop!.currencyItem!.toMap());
    _products =
        shop?.products
            .map(
              (p) => CampaignShopProduct(
                id: p.id,
                definition: ItemDefinition.fromMap(p.definition.toMap()),
                price: p.price,
                prohibited: p.prohibited,
              ),
            )
            .toList() ??
        <CampaignShopProduct>[];
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _currencyName.dispose();
    super.dispose();
  }

  Future<void> _createItem() async {
    final definition = await Navigator.push<ItemDefinition>(
      context,
      MaterialPageRoute(builder: (_) => const ItemFormScreen()),
    );
    if (definition == null || !mounted) return;
    final price = await _askPrice(definition.name);
    if (price == null || !mounted) return;
    setState(() {
      _products.add(
        CampaignShopProduct(
          id: 'shop_product_${DateTime.now().microsecondsSinceEpoch}',
          definition: definition,
          price: price,
        ),
      );
    });
  }

  Future<void> _addFromLibrary() async {
    final library = await ItemLibraryService.loadLibrary();
    if (!mounted) return;
    if (library.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La biblioteca de objetos está vacía.')),
      );
      return;
    }
    final definition = await showModalBottomSheet<ItemDefinition>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: library.length,
            itemBuilder: (_, i) {
              final entry = library[i];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.inventory_2_rounded),
                ),
                title: Text(entry.name),
                subtitle: Text(entry.type.label),
                onTap: () => Navigator.pop(
                  sheetContext,
                  ItemDefinition.fromMap(entry.definition.toMap()),
                ),
              );
            },
          ),
        ),
      ),
    );
    if (definition == null || !mounted) return;
    final price = await _askPrice(definition.name);
    if (price == null || !mounted) return;
    setState(
      () => _products.add(
        CampaignShopProduct(
          id: 'shop_product_${DateTime.now().microsecondsSinceEpoch}',
          definition: definition,
          price: price,
        ),
      ),
    );
  }

  Future<void> _chooseCurrencyItem() async {
    final library = await ItemLibraryService.loadLibrary();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<ItemDefinition>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          children: [
            const ListTile(title: Text('Objeto usado como moneda')),
            ...library.map(
              (entry) => ListTile(
                title: Text(entry.name),
                subtitle: Text(entry.type.label),
                onTap: () => Navigator.pop(
                  sheetContext,
                  ItemDefinition.fromMap(entry.definition.toMap()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) setState(() => _currencyItem = chosen);
  }

  Future<int?> _askPrice(String itemName, {int initial = 0}) {
    final suffix = _currencyKind == CampaignShopCurrencyKind.resource
        ? _currencyName.text.trim()
        : _currencyItem?.name;
    return showDialog<int>(
      context: context,
      builder: (_) =>
          _PriceDialog(itemName: itemName, initial: initial, suffix: suffix),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_currencyKind == CampaignShopCurrencyKind.item &&
        _currencyItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elige el objeto que se usará como moneda.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      CampaignShop(
        id: widget.shop?.id ?? 'shop_${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        description: _description.text.trim(),
        currencyKind: _currencyKind,
        currencyName: _currencyKind == CampaignShopCurrencyKind.resource
            ? (_currencyName.text.trim().isEmpty
                  ? 'Oro'
                  : _currencyName.text.trim())
            : (_currencyItem?.name ?? 'Objeto'),
        currencyItem: _currencyItem,
        products: _products,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currencyLabel = _currencyKind == CampaignShopCurrencyKind.resource
        ? (_currencyName.text.trim().isEmpty ? 'Oro' : _currencyName.text.trim())
        : (_currencyItem?.name ?? 'Objeto');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shop == null ? 'Nueva tienda' : 'Editar tienda'),
        actions: [
          IconButton(
            onPressed: _save,
            tooltip: 'Guardar',
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            _ShopEditorHero(
              isNew: widget.shop == null,
              productCount: _products.length,
              prohibitedCount: _products.where((p) => p.prohibited).length,
            ),
            const SizedBox(height: 18),
            _EditorSection(
              icon: Icons.storefront_rounded,
              title: 'Identidad de la tienda',
              subtitle: 'Cómo la verán los personajes en la campaña.',
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la tienda',
                      prefixIcon: Icon(Icons.store_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Escribe un nombre'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                      hintText: 'Ambiente, especialidad, propietario…',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _EditorSection(
              icon: Icons.paid_rounded,
              title: 'Moneda principal',
              subtitle: 'Define con qué pagan los personajes.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<CampaignShopCurrencyKind>(
                    segments: const [
                      ButtonSegment(
                        value: CampaignShopCurrencyKind.resource,
                        icon: Icon(Icons.paid_rounded),
                        label: Text('Recurso'),
                      ),
                      ButtonSegment(
                        value: CampaignShopCurrencyKind.item,
                        icon: Icon(Icons.inventory_2_rounded),
                        label: Text('Objeto'),
                      ),
                    ],
                    selected: {_currencyKind},
                    onSelectionChanged: (v) =>
                        setState(() => _currencyKind = v.first),
                  ),
                  const SizedBox(height: 14),
                  if (_currencyKind == CampaignShopCurrencyKind.resource)
                    TextField(
                      controller: _currencyName,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Nombre del recurso',
                        hintText: 'Oro, fichas, cristales…',
                        prefixIcon: Icon(Icons.toll_rounded),
                      ),
                    )
                  else
                    Material(
                      color: colors.surfaceContainerHighest.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colors.primaryContainer,
                          child: Icon(Icons.toll_rounded, color: colors.primary),
                        ),
                        title: Text(
                          _currencyItem?.name ?? 'Elegir objeto-moneda',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text('Se gastarán unidades de este objeto.'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _chooseCurrencyItem,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _EditorSection(
              icon: Icons.inventory_2_rounded,
              title: 'Catálogo',
              subtitle: '${_products.length} productos · ${_products.where((p) => p.prohibited).length} prohibidos',
              trailing: PopupMenuButton<String>(
                tooltip: 'Añadir producto',
                onSelected: (v) {
                  if (v == 'create') _createItem();
                  if (v == 'library') _addFromLibrary();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'create',
                    child: ListTile(
                      leading: Icon(Icons.add_box_rounded),
                      title: Text('Crear objeto aquí'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'library',
                    child: ListTile(
                      leading: Icon(Icons.local_library_rounded),
                      title: Text('Añadir de biblioteca'),
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: colors.onPrimary, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Añadir',
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: _products.isEmpty
                  ? _EmptyProducts(onAdd: _addFromLibrary)
                  : Column(
                      children: List.generate(_products.length, (index) {
                        final product = _products[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _products.length - 1 ? 0 : 10,
                          ),
                          child: _ProductEditorCard(
                            product: product,
                            currencyLabel: currencyLabel,
                            onEdit: () async {
                              final edited = await Navigator.push<ItemDefinition>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ItemFormScreen(
                                    definition: product.definition,
                                  ),
                                ),
                              );
                              if (edited != null && mounted) {
                                setState(() => product.definition = edited);
                              }
                            },
                            onPrice: () async {
                              final value = await _askPrice(
                                product.definition.name,
                                initial: product.price,
                              );
                              if (value != null && mounted) {
                                setState(() => product.price = value);
                              }
                            },
                            onToggleProhibited: () => setState(
                              () => product.prohibited = !product.prohibited,
                            ),
                            onRemove: () => setState(() => _products.removeAt(index)),
                          ),
                        );
                      }),
                    ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(widget.shop == null ? 'Crear tienda' : 'Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopEditorHero extends StatelessWidget {
  final bool isNew;
  final int productCount;
  final int prohibitedCount;
  const _ShopEditorHero({
    required this.isNew,
    required this.productCount,
    required this.prohibitedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer,
            colors.tertiaryContainer.withValues(alpha: .75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: .8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.storefront_rounded, size: 32, color: colors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNew ? 'Diseña una nueva tienda' : 'Editor de tienda',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '$productCount productos${prohibitedCount > 0 ? ' · $prohibitedCount prohibidos' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  const _EditorSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProductEditorCard extends StatelessWidget {
  final CampaignShopProduct product;
  final String currencyLabel;
  final VoidCallback onEdit;
  final VoidCallback onPrice;
  final VoidCallback onToggleProhibited;
  final VoidCallback onRemove;
  const _ProductEditorCard({
    required this.product,
    required this.currencyLabel,
    required this.onEdit,
    required this.onPrice,
    required this.onToggleProhibited,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final path = product.definition.imagePath;
    final hasImage = path != null && path.trim().isNotEmpty && File(path).existsSync();
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: .38),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: hasImage
                      ? Image.file(File(path!), fit: BoxFit.cover)
                      : Container(
                          color: colors.primaryContainer,
                          child: Icon(Icons.inventory_2_rounded, color: colors.primary, size: 30),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.definition.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (product.prohibited)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.errorContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Prohibido',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onErrorContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(product.definition.type.label, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(Icons.paid_rounded, size: 17, color: colors.primary),
                        const SizedBox(width: 5),
                        Text('$currencyLabel · ${product.price}', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'price') onPrice();
                  if (v == 'prohibited') onToggleProhibited();
                  if (v == 'remove') onRemove();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Editar objeto'))),
                  const PopupMenuItem(value: 'price', child: ListTile(leading: Icon(Icons.paid_rounded), title: Text('Cambiar precio'))),
                  PopupMenuItem(value: 'prohibited', child: ListTile(leading: Icon(product.prohibited ? Icons.lock_open_rounded : Icons.block_rounded), title: Text(product.prohibited ? 'Permitir compra' : 'Prohibir compra'))),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'remove', child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Quitar'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyProducts({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 38, color: colors.onSurfaceVariant),
          const SizedBox(height: 10),
          const Text('Todavía no hay productos', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Añade objetos de la biblioteca o créalos directamente aquí.', textAlign: TextAlign.center, style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.local_library_rounded), label: const Text('Abrir biblioteca')),
        ],
      ),
    );
  }
}

class _PriceDialog extends StatefulWidget {
  final String itemName;
  final int initial;
  final String? suffix;

  const _PriceDialog({
    required this.itemName,
    required this.initial,
    this.suffix,
  });

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initial}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _accept() {
    final value = int.tryParse(_controller.text.trim()) ?? 0;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Precio · ${widget.itemName}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _accept(),
        decoration: InputDecoration(
          labelText: 'Precio',
          suffixText: widget.suffix,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _accept, child: const Text('Aceptar')),
      ],
    );
  }
}
