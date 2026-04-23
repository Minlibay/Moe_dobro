import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/legal_provider.dart';
import '../../models/legal_document.dart';

class LegalDocumentScreen extends StatefulWidget {
  final String documentType;
  final String title;

  const LegalDocumentScreen({
    super.key,
    required this.documentType,
    required this.title,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LegalProvider>(context, listen: false).loadDocument(widget.documentType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Consumer<LegalProvider>(
        builder: (context, provider, child) {
          final doc = _getDocument(provider);
          
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (doc == null) {
            return const Center(child: Text('Документ не найден'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  doc.content,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                if (doc.updatedAt != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Обновлено: ${_formatDate(doc.updatedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  LegalDocument? _getDocument(LegalProvider provider) {
    switch (widget.documentType) {
      case 'privacy':
        return provider.privacyPolicy;
      case 'terms':
        return provider.termsOfService;
      case 'offer':
        return provider.offer;
      default:
        return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}