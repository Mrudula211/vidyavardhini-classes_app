import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/fee_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../fees/providers/fee_providers.dart';

class AddPaymentSheet extends ConsumerStatefulWidget {
  final MonthlyFeeModel monthlyFee;

  const AddPaymentSheet({
    super.key,
    required this.monthlyFee,
  });

  @override
  ConsumerState<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _paymentMethod = 'upi';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.monthlyFee.remainingAmount > 0
          ? widget.monthlyFee.remainingAmount.toStringAsFixed(0)
          : widget.monthlyFee.expectedAmount.toStringAsFixed(0),
    );
    _dateController.text = DateTime.now().toIso8601String().split('T').first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      await ref.read(feeRepositoryProvider).recordFeePayment(
            monthlyFeeId: widget.monthlyFee.id,
            amount: amount,
            paymentMethod: _paymentMethod,
            paymentDate: _dateController.text.trim(),
            referenceNumber: _refController.text.trim().isNotEmpty ? _refController.text.trim() : null,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
            collectedBy: currentUser.id,
          );

      ref.invalidate(adminFeeOverviewProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ₹${amount.toStringAsFixed(0)} recorded for ${widget.monthlyFee.studentName}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Record Payment — ${widget.monthlyFee.studentName ?? "Student"}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Summary Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Expected', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('₹${widget.monthlyFee.expectedAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Paid So Far', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('₹${widget.monthlyFee.paidAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Remaining', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('₹${widget.monthlyFee.remainingAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (₹) *',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || double.tryParse(val.trim()) == null || double.parse(val.trim()) <= 0) {
                    return 'Enter a valid payment amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'upi', child: Text('UPI / GPay / PhonePe')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer (NEFT/IMPS)')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Payment Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateController.text = picked.toIso8601String().split('T').first;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _refController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number / UPI Ref ID (Optional)',
                  hintText: 'e.g. 123456789012',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g. Part payment for April',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSubmitting ? null : _submitPayment,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SAVE PAYMENT RECORD',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
