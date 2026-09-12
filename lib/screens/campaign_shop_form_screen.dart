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

  Future<int?> _askPrice(String itemName, {int initial = 0}) async {
    final controller = TextEditingController(text: '$initial');
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Precio · $itemName'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Precio',
            suffixText: _currencyKind == CampaignShopCurrencyKind.resource
                ? _currencyName.text.trim()
                : _currencyItem?.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              int.tryParse(controller.text.trim()) ?? 0,
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shop == null ? 'Nueva tienda' : 'Editar tienda'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nombre de la tienda',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 22),
            Text(
              'Moneda principal',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SegmentedButton<CampaignShopCurrencyKind>(
              segments: const [
                ButtonSegment(
                  value: CampaignShopCurrencyKind.resource,
                  icon: Icon(Icons.paid_rounded),
                  label: Text('Oro / recurso'),
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
            const SizedBox(height: 12),
            if (_currencyKind == CampaignShopCurrencyKind.resource)
              TextField(
                controller: _currencyName,
                decoration: const InputDecoration(
                  labelText: 'Nombre del recurso',
                  hintText: 'Oro, fichas, cristales…',
                ),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.toll_rounded)),
                title: Text(_currencyItem?.name ?? 'Elegir objeto-moneda'),
                subtitle: const Text(
                  'Los personajes pagarán gastando unidades de este objeto.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _chooseCurrencyItem,
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Productos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
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
                  child: FilledButton.tonalIcon(
                    onPressed: null,
                    icon: Icon(Icons.add_rounded),
                    label: Text('Añadir'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_products.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Todavía no hay productos. Puedes crear un objeto directamente desde esta tienda.',
                  ),
                ),
              )
            else
              ...List.generate(_products.length, (index) {
                final product = _products[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.inventory_2_rounded),
                    ),
                    title: Text(product.definition.name),
                    subtitle: Text(
                      '${product.price} ${_currencyKind == CampaignShopCurrencyKind.resource ? _currencyName.text : (_currencyItem?.name ?? 'moneda')}',
                    ),
                    onTap: () async {
                      final edited = await Navigator.push<ItemDefinition>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ItemFormScreen(definition: product.definition),
                        ),
                      );
                      if (edited != null && mounted)
                        setState(() => product.definition = edited);
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'price') {
                          final value = await _askPrice(
                            product.definition.name,
                            initial: product.price,
                          );
                          if (value != null && mounted)
                            setState(() => product.price = value);
                        } else if (v == 'remove') {
                          setState(() => _products.removeAt(index));
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'price',
                          child: Text('Cambiar precio'),
                        ),
                        PopupMenuItem(value: 'remove', child: Text('Quitar')),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Guardar tienda'),
            ),
          ],
        ),
      ),
    );
  }
}
