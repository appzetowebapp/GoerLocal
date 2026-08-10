import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_upload_area.dart';
import 'package:hyper_local_seller/widgets/custom/image_source_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/bloc/brands_bloc.dart';

class AddBrandSheet extends StatefulWidget {
  const AddBrandSheet({super.key});

  @override
  State<AddBrandSheet> createState() => _AddBrandSheetState();
}

class _AddBrandSheetState extends State<AddBrandSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _imagePath;
  bool _isActive = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImageSourceType? source = await showModalBottomSheet<ImageSourceType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImageSourceSheet(),
    );

    if (source != null) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source == ImageSourceType.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_imagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a brand logo.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<BrandsBloc>().add(
        AddBrandEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imagePath: _imagePath!,
          status: _isActive ? 'active' : 'inactive',
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.read<ScreenSizeBloc>().state.screenType;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Private Brand",
                    style: TextStyle(
                      fontSize: UIUtils.body(screenType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(height: UIUtils.gapMD(screenType)),
              
              CustomTextField(
                label: l10n?.title ?? "Brand Name",
                controller: _titleController,
                hint: "Enter brand name",
                isRequired: true,
                validator: (v) => v!.isEmpty ? (l10n?.fieldRequired ?? 'Field required') : null,
              ),
              SizedBox(height: UIUtils.gapMD(screenType)),
              
              CustomTextField(
                label: l10n?.productDescription ?? "Description",
                controller: _descriptionController,
                hint: "Enter description",
                maxLines: 3,
                isRequired: true,
                validator: (v) => v!.isEmpty ? (l10n?.fieldRequired ?? 'Field required') : null,
              ),
              SizedBox(height: UIUtils.gapMD(screenType)),

              CustomUploadArea(
                hint: "Select Brand Logo",
                fileName: _imagePath,
                icon: Icons.image_outlined,
                onTap: _pickImage,
                onRemove: () => setState(() => _imagePath = null),
              ),
              SizedBox(height: UIUtils.gapMD(screenType)),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Status (Active)",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: UIUtils.body(screenType),
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),

              SizedBox(height: UIUtils.gapLG(screenType)),
              PrimaryButton(
                text: "Add Brand",
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
