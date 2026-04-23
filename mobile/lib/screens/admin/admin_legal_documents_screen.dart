import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/legal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/legal_document.dart';

class AdminLegalDocumentsScreen extends StatefulWidget {
  const AdminLegalDocumentsScreen({super.key});

  @override
  State<AdminLegalDocumentsScreen> createState() => _AdminLegalDocumentsScreenState();
}

class _AdminLegalDocumentsScreenState extends State<AdminLegalDocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LegalProvider>(context, listen: false).loadAllDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Правовые документы'),
      ),
      body: Consumer<LegalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDocumentCard(
                context,
                'privacy',
                '📜 Политика конфиденциальности',
                provider.privacyPolicy,
              ),
              const SizedBox(height: 12),
              _buildDocumentCard(
                context,
                'terms',
                '📋 Пользовательское соглашение',
                provider.termsOfService,
              ),
              const SizedBox(height: 12),
              _buildDocumentCard(
                context,
                'offer',
                '💰 Оферта',
                provider.offer,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, String type, String title, dynamic doc) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showEditDialog(context, type, title, doc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (doc != null && doc.updatedAt != null)
                      Text(
                        'Обновлено: ${_formatDate(doc.updatedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.edit),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String type, String title, dynamic doc) {
    final titleController = TextEditingController(text: doc?.title ?? '');
    final contentController = TextEditingController(text: doc?.content ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Редактировать $title',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Заголовок',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'Содержание',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заполните все поля')),
                  );
                  return;
                }

                final provider = Provider.of<LegalProvider>(context, listen: false);
                final success = await provider.updateDocument(
                  type,
                  titleController.text,
                  contentController.text,
                );

                if (!mounted) return;

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Сохранено!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.error ?? 'Ошибка')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}