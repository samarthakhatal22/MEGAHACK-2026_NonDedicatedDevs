import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' show ImageFilter;
import '../services/fact_check_service.dart';
import '../services/cloudinary_service.dart';
import '../models/fact_result.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  final String text;
  final MessageRole role;
  final FactResult? result;
  final Uint8List? imageBytes;
  final String? imageUrl;

  ChatMessage({
    required this.text,
    required this.role,
    this.result,
    this.imageBytes,
    this.imageUrl,
  });
}

class FactCheckChatPage extends StatefulWidget {
  final FactCheckService service;

  const FactCheckChatPage({super.key, required this.service});

  @override
  State<FactCheckChatPage> createState() => _FactCheckChatPageState();
}

class _FactCheckChatPageState extends State<FactCheckChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _historyLoading = true;

  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(ChatMessage(
      text: "Hello! I'm your Civic Shield assistant. Send me any rumor or claim, and I'll verify it against official sources.",
      role: MessageRole.assistant,
    ));
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _historyLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("fact_checks")
          .where('userId', isEqualTo: user.uid)
          .get();

      // Sort client-side to avoid needing a composite index for timestamp
      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aTime = a['timestamp'] as Timestamp?;
          final bTime = b['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return aTime.compareTo(bTime);
        });

      final historicalMessages = docs.map((doc) {
        final data = doc.data();
        final resultData = data['result'] as Map<String, dynamic>?;
        
        FactResult? result;
        if (resultData != null) {
          result = FactResult(
            status: resultData['status'] ?? 'Unknown',
            score: (resultData['accuracy_percentage'] ?? 0).toInt(),
            simpleDescription: resultData['explanation'] ?? '',
            references: List<String>.from(resultData['references'] ?? []),
            isAiGenerated: resultData['isAiGenerated'],
            authenticityReason: resultData['authenticityReason'],
          );
        }

        return [
          ChatMessage(
            text: data['queryText'] ?? '',
            role: MessageRole.user,
          ),
          ChatMessage(
            text: result?.isAiGenerated == true 
                ? "⚠️ Potential AI Manipulation Detected." 
                : (data['imageUrl'] != null 
                    ? "Verification complete. Image Link: ${data['imageUrl']}" 
                    : "Verification complete."),
            role: MessageRole.assistant,
            result: result,
            imageUrl: data['imageUrl'],
          ),
        ];
      }).expand((i) => i).toList();

      setState(() {
        _messages.addAll(historicalMessages);
        _historyLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      setState(() => _historyLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitFactCheck() async {
    final query = _textController.text.trim();
    if (query.isEmpty && _imageBytes == null) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: query.isEmpty ? "Checking this image..." : query,
          role: MessageRole.user,
          imageBytes: _imageBytes,
        ),
      );
      _isLoading = true;
    });

    final bytesToSend = _imageBytes;
    final fileToUpload = _selectedImage != null
        ? File(_selectedImage!.path)
        : null;

    _textController.clear();
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
    });

    _scrollToBottom();
    FocusScope.of(context).unfocus();

    try {
      String? imageUrl;

      // 1. Upload to Cloudinary if image exists
      if (fileToUpload != null) {
        final cloudinary = CloudinaryService();
        imageUrl = await cloudinary.uploadImage(fileToUpload);
      }

      // 2. Verify with FactCheckService
      final result = await widget.service.verifyClaim(
        text: query,
        imageBytes: bytesToSend, // Keep bytes as backup/fallback
        imageUrl: imageUrl, // Pass the new URL
      );

      setState(() {
        _messages.add(
          ChatMessage(
            text: result.isAiGenerated == true
                ? "⚠️ Potential AI Manipulation Detected."
                : (imageUrl != null
                      ? "Verification complete. Image Link: $imageUrl"
                      : "Verification complete."),
            role: MessageRole.assistant,
            result: result,
            imageUrl: imageUrl,
          ),
        );
      });

      // 3. Store result in Firestore
      try {
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection("fact_checks").add({
          'userId': user?.uid ?? 'anonymous',
          'queryText': query,
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'result': {
            'status': result.status,
            'accuracy_percentage': result.score,
            'explanation': result.simpleDescription,
            'references': result.references,
            'isAiGenerated': result.isAiGenerated,
            'authenticityReason': result.authenticityReason,
          },
        });
        debugPrint('Fact check saved to Firestore successfully.');
      } catch (firestoreError) {
        debugPrint('CRITICAL: Error saving to Firestore: $firestoreError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save to history: $firestoreError')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry, I encountered an error: ${e.toString()}",
            role: MessageRole.assistant,
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _launchURL(String url) async {
    String trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return;

    // Ensure URL has a scheme, otherwise url_launcher will fail
    if (!trimmedUrl.startsWith('http://') &&
        !trimmedUrl.startsWith('https://')) {
      trimmedUrl = 'https://$trimmedUrl';
    }

    final uri = Uri.parse(trimmedUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('Could not launch $trimmedUrl');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open browser for: $trimmedUrl')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fact Check assistant'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: _historyLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    final message = _messages[index];
                    return _buildChatBubble(message);
                  },
                ),
              ),
          
          // Image Preview (if selected)
          if (_selectedImage != null)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImage!.path),
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedImage = null;
                        _imageBytes = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Chat Input Area
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: colorScheme.primary, size: 22),
                    onPressed: () => _showImageSourceActionSheet(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Enter a rumor or pick an image...',
                        hintStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitFactCheck(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ScaleTransition(
                    scale: AlwaysStoppedAnimation(_isLoading ? 0.8 : 1.0),
                    child: IconButton.filled(
                      icon: _isLoading 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 20),
                      onPressed: (_isLoading || (_textController.text.trim().isEmpty && _selectedImage == null)) 
                          ? null 
                          : _submitFactCheck,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.role == MessageRole.user;
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUser 
                            ? colorScheme.primary.withOpacity(0.9) 
                            : colorScheme.secondaryContainer.withOpacity(0.7),
                          border: Border.all(
                            color: isUser 
                              ? Colors.white.withOpacity(0.2) 
                              : colorScheme.outline.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isUser ? 20 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.imageBytes != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    message.imageBytes!,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            if (message.imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    message.imageUrl!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200,
                                        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                        child: const Center(child: CircularProgressIndicator()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            if (message.text.isNotEmpty)
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: isUser ? colorScheme.onPrimary : colorScheme.onSecondaryContainer,
                                  fontSize: 15,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (message.result != null) ...[
                    const SizedBox(height: 8),
                    _buildResultCard(message.result!),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Verifying claim...',
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(FactResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    Color statusColor;
    IconData statusIcon;

    switch (result.status.toLowerCase()) {
      case 'true':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'false':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'VERDICT',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor.withOpacity(0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${result.score}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      fontSize: 24,
                    ),
                  ),
                ),
              ],
            ),
            if (result.isAiGenerated != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.isAiGenerated!
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: result.isAiGenerated!
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          result.isAiGenerated!
                              ? Icons.auto_awesome
                              : Icons.verified_user,
                          size: 16,
                          color: result.isAiGenerated!
                              ? Colors.red
                              : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          result.isAiGenerated!
                              ? 'AI MANIPULATION SUSPECTED'
                              : 'IMAGE AUTHENTICITY VERIFIED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: result.isAiGenerated!
                                ? Colors.red
                                : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    if (result.authenticityReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.authenticityReason!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const Divider(height: 24),
            Text(
              result.simpleDescription,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: colorScheme.onSurface,
              ),
            ),
            if (result.references.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'OFFICIAL SOURCES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              ...result.references.map(
                (url) => Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _launchURL(url),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 4.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                url,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
