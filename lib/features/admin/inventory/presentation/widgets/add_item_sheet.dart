import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/widgets/top_snackbar.dart';
import 'package:ferrer_rental_shop/core/services/item_photo_encoder.dart';
import 'package:ferrer_rental_shop/core/utils/validators.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';

typedef SaveItemCallback = Future<String?> Function({
  required String name,
  required String category,
  required String description,
  required double basePrice,
  required double securityDeposit,
  required List<String> sizes,
  required List<String> occasions,
  required List<File> photos,
});

typedef UpdateItemCallback = Future<bool> Function({
  required CatalogItem item,
  required List<File> newPhotos,
  required List<String> keptPhotos,
  required bool photosChanged,
});

class AddItemSheet extends StatefulWidget {
  final SaveItemCallback onSave;
  final UpdateItemCallback? onUpdate;

  /// Non-null puts the sheet in edit mode with the fields prefilled.
  final CatalogItem? item;
  final List<String> initialPhotos;

  const AddItemSheet({
    super.key,
    required this.onSave,
    this.onUpdate,
    this.item,
    this.initialPhotos = const [],
  }) : assert(item == null || onUpdate != null,
            'onUpdate must be provided when editing an item');

  static Future<void> show(
    BuildContext context, {
    required SaveItemCallback onSave,
    UpdateItemCallback? onUpdate,
    CatalogItem? item,
    List<String> initialPhotos = const [],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .92,
        ),
        decoration: const BoxDecoration(
          color: AppColors.adminCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AddItemSheet(
          onSave: onSave,
          onUpdate: onUpdate,
          item: item,
          initialPhotos: initialPhotos,
        ),
      ),
    );
  }

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();

  String _category = 'dress';
  bool _saving = false;
  final Set<String> _sizes = {};
  final Set<String> _occasions = {};
  final List<File> _images = [];

  /// Already-stored photos (data URIs) the admin keeps in edit mode.
  List<String> _existingPhotos = [];
  bool _photosTouched = false;

  static const _maxImages = 6;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _existingPhotos = [...widget.initialPhotos];
    if (item != null) {
      _category = item.category;
      _nameController.text = item.name;
      _descriptionController.text = item.description;
      _priceController.text = item.basePrice.toStringAsFixed(0);
      _depositController.text = item.securityDeposit.toStringAsFixed(0);
      _sizes.addAll(item.sizes);
      _occasions.addAll(item.occasions);
    }
  }

  bool get _isEdit => widget.item != null;

  int get _totalPhotos => _existingPhotos.length + _images.length;

  Future<void> _pickImages() async {
    try {
      final remaining = _maxImages - _totalPhotos;
      if (remaining <= 0) {
        showTopSnackBar(context, 'Up to $_maxImages photos per item.');
        return;
      }
      final picked = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 72,
      );
      if (picked.isEmpty) return;
      setState(() {
        _images.addAll(picked.take(remaining).map((x) => File(x.path)));
        _photosTouched = true;
      });
    } catch (_) {
      if (!mounted) return;
      showTopSnackBar(
        context,
        'Could not open your photos. Please try again.',
        backgroundColor: AppColors.adminRed,
      );
    }
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotos.removeAt(index);
      _photosTouched = true;
    });
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _images.removeAt(index);
      _photosTouched = true;
    });
  }

  static const adultSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const kiddieSizes = ['2T', '3T', '4T', '5-6', '7-8', '9-10', '11-12'];
  static const occasionOptions = ['wedding', 'party', 'debut', 'costume', 'school'];

  List<String> get _sizeOptions =>
      _category == 'kiddie' ? kiddieSizes : adultSizes;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  void _switchCategory(String value) {
    setState(() {
      _category = value;
      _sizes.removeWhere((s) => !_sizeOptions.contains(s));
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_sizes.isEmpty) {
      showTopSnackBar(context, 'Select at least one available size');
      return;
    }
    setState(() => _saving = true);

    final name = _nameController.text.trim();
    var ok = false;
    try {
      if (_isEdit) {
        ok = await widget.onUpdate!(
          item: widget.item!.copyWith(
            name: name,
            category: _category,
            description: _descriptionController.text.trim(),
            basePrice: double.parse(_priceController.text.trim()),
            securityDeposit: double.parse(_depositController.text.trim()),
            sizes: _sizes.toList(),
            occasions: _occasions.toList(),
          ),
          newPhotos: List<File>.from(_images),
          keptPhotos: _existingPhotos,
          photosChanged: _photosTouched,
        );
      } else {
        final id = await widget.onSave(
          name: name,
          category: _category,
          description: _descriptionController.text.trim(),
          basePrice: double.parse(_priceController.text.trim()),
          securityDeposit: double.parse(_depositController.text.trim()),
          sizes: _sizes.toList(),
          occasions: _occasions.toList(),
          photos: List<File>.from(_images),
        );
        ok = id != null;
      }
    } on PhotoTooLargeException {
      if (!mounted) return;
      setState(() => _saving = false);
      showTopSnackBar(
        context,
        'These photos are too large to store. Remove one or two and try again.',
        backgroundColor: AppColors.adminRed,
      );
      return;
    } catch (_) {
      // fall through to the generic failure below
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      showTopSnackBar(
        context,
        _isEdit ? '$name updated' : '$name added to inventory',
        backgroundColor: AppColors.adminPrimary,
      );
    } else {
      showTopSnackBar(
        context,
        'Could not save item. Please try again.',
        backgroundColor: AppColors.adminRed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.adminPrimary.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                      _isEdit
                          ? Icons.edit_rounded
                          : Icons.add_photo_alternate_outlined,
                      size: 19,
                      color: AppColors.adminPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_isEdit ? 'Edit Item' : 'Add New Item',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.adminInk)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _label('ITEM NAME'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.notEmpty(v, label: 'Item name'),
              decoration:
                  const InputDecoration(hintText: 'e.g. Blush Satin Evening Gown'),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('CATEGORY'),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        items: const [
                          DropdownMenuItem(value: 'dress', child: Text('Dress')),
                          DropdownMenuItem(value: 'kiddie', child: Text('Kiddie')),
                        ],
                        onChanged: (v) {
                          if (v != null) _switchCategory(v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('BASE RENTAL PRICE'),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            Validators.positiveNumber(v, label: 'Rental price'),
                        decoration: const InputDecoration(
                            hintText: '1,800', prefixText: '₱ '),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _label('SECURITY DEPOSIT'),
            TextFormField(
              controller: _depositController,
              keyboardType: TextInputType.number,
              validator: (v) => Validators.positiveNumber(v, label: 'Deposit'),
              decoration:
                  const InputDecoration(hintText: '1,000', prefixText: '₱ '),
            ),
            const SizedBox(height: 14),
            _label('DESCRIPTION'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                  hintText: 'Fabric, cut, and details customers should know...'),
            ),
            const SizedBox(height: 16),
            _label('AVAILABLE SIZES'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final size in _sizeOptions)
                  FilterChip(
                    label: Text(size),
                    selected: _sizes.contains(size),
                    onSelected: (selected) => setState(() {
                      selected ? _sizes.add(size) : _sizes.remove(size);
                    }),
                    selectedColor: AppColors.adminPrimarySoft,
                    checkmarkColor: AppColors.adminPrimary,
                    side: BorderSide(
                        color: _sizes.contains(size)
                            ? AppColors.adminPrimary
                            : AppColors.adminBorder),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _sizes.contains(size)
                          ? AppColors.adminPrimary
                          : AppColors.adminMuted,
                    ),
                    showCheckmark: true,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _label('OCCASIONS'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final occasion in occasionOptions)
                  FilterChip(
                    label: Text(
                        '${occasion[0].toUpperCase()}${occasion.substring(1)}'),
                    selected: _occasions.contains(occasion),
                    onSelected: (selected) => setState(() {
                      selected
                          ? _occasions.add(occasion)
                          : _occasions.remove(occasion);
                    }),
                    selectedColor: AppColors.adminAmber.withValues(alpha: .15),
                    checkmarkColor: AppColors.adminAmber,
                    side: BorderSide(
                        color: _occasions.contains(occasion)
                            ? AppColors.adminAmber
                            : AppColors.adminBorder),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _occasions.contains(occasion)
                          ? AppColors.adminAmber
                          : AppColors.adminMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _label('PHOTOS  ·  UP TO $_maxImages'),
            if (_existingPhotos.isNotEmpty || _images.isNotEmpty)
              SizedBox(
                height: 86,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < _existingPhotos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _EditablePhotoThumb(
                          image: itemImage(_existingPhotos[i]),
                          onRemove: _saving
                              ? null
                              : () => _removeExistingPhoto(i),
                        ),
                      ),
                    for (var i = 0; i < _images.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _EditablePhotoThumb(
                          image: Image.file(_images[i], fit: BoxFit.cover),
                          onRemove:
                              _saving ? null : () => _removeNewPhoto(i),
                        ),
                      ),
                  ],
                ),
              ),
            GestureDetector(
              onTap: _saving ? null : _pickImages,
              child: DashedUploadPlaceholder(
                onTapHint: _totalPhotos == 0
                    ? 'Tap to add photos'
                    : 'Tap to add more photos',
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_saving
                    ? 'Saving...'
                    : (_isEdit ? 'Save Changes' : 'Save Item')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class DashedUploadPlaceholder extends StatelessWidget {
  final String onTapHint;

  const DashedUploadPlaceholder({super.key, required this.onTapHint});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        height: 92,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined,
                size: 22, color: Colors.grey.shade400),
            const SizedBox(width: 10),
            Text(
              onTapHint,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditablePhotoThumb extends StatelessWidget {
  final Widget image;
  final VoidCallback? onRemove;

  const _EditablePhotoThumb({required this.image, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 86,
            height: 86,
            child: image,
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: AppColors.adminInk),
              ),
            ),
          ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const dashWidth = 5.0;
    const dashGap = 3.5;
    const radius = 12.0;

    for (final y in [0.7, size.height - 0.7]) {
      var x = radius;
      while (x < size.width - radius) {
        final end =
            (x + dashWidth) > size.width - radius ? size.width - radius : x + dashWidth;
        canvas.drawLine(Offset(x, y), Offset(end, y), paint);
        x = end + dashGap;
      }
    }
    final corner = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(radius, radius), radius: radius),
        math.pi,
        math.pi / 2,
        false,
        corner);
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(size.width - radius, radius), radius: radius),
        -math.pi / 2,
        math.pi / 2,
        false,
        corner);
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(radius, size.height - radius), radius: radius),
        math.pi / 2,
        math.pi / 2,
        false,
        corner);
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(size.width - radius, size.height - radius),
            radius: radius),
        0,
        math.pi / 2,
        false,
        corner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




