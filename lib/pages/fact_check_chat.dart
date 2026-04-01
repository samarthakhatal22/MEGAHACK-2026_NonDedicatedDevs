import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
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
  // ADDED: Track document ID and if deep analysis has been requested for this msg
  String? firestoreDocId;
  bool isDeepAnalysisRequested;

  ChatMessage({
    required this.text,
    required this.role,
    this.result,
    this.imageBytes,
    this.imageUrl,
    this.firestoreDocId,
    this.isDeepAnalysisRequested = false,
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
    _messages.add(
      ChatMessage(
        text:
            "Hello! I'm your Civic Shield assistant. Send me any rumor or claim, and I'll verify it against official sources.",
        role: MessageRole.assistant,
      ),
    );
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

      final historicalMessages = docs
          .map((doc) {
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
                socialSourcesChecked: resultData['socialSourcesChecked'] != null
                    ? List<String>.from(resultData['socialSourcesChecked'])
                    : null,
              );
            }

            final docId = doc.id;
            final deepAnalysis = data['deepAnalysis'] as String?;

            final msgs = [
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
                firestoreDocId: docId,
                isDeepAnalysisRequested: deepAnalysis != null,
              ),
            ];

            // ADDED: Re-inject the deep analysis to the chat view on reload
            if (deepAnalysis != null && deepAnalysis.isNotEmpty) {
              msgs.add(
                ChatMessage(text: deepAnalysis, role: MessageRole.assistant),
              );
            }

            return msgs;
          })
          .expand((i) => i)
          .toList();

      if (!mounted) return;
      setState(() {
        _messages.addAll(historicalMessages);
        _historyLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      if (!mounted) return;
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

      final assistantMsg = ChatMessage(
        text: result.isAiGenerated == true
            ? "⚠️ Potential AI Manipulation Detected."
            : (imageUrl != null
                  ? "Verification complete. Image Link: $imageUrl"
                  : "Verification complete."),
        role: MessageRole.assistant,
        result: result,
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(assistantMsg);
      });

      // 3. Store result in Firestore (Change 3)
      try {
        final user = FirebaseAuth.instance.currentUser;
        final docRef = await FirebaseFirestore.instance
            .collection("fact_checks")
            .add({
              'userId': user?.uid ?? 'anonymous',
              'queryText': query,
              'imageUrl': imageUrl,
              'timestamp': FieldValue.serverTimestamp(),
              'deepAnalysis': null,
              'result': {
                'status': result.status,
                'accuracy_percentage': result.score,
                'explanation': result.simpleDescription,
                'references': result.references,
                'isAiGenerated': result.isAiGenerated,
                'authenticityReason': result.authenticityReason,
                'socialSourcesChecked': result.socialSourcesChecked ?? [],
                'verdictColor': result.status,
              },
            });
        // Attach docRef.id to history object so Know More API can find it
        if (mounted) {
          setState(() {
            assistantMsg.firestoreDocId = docRef.id;
          });
        }
        debugPrint(
          'Fact check saved to Firestore successfully. Doc: ${docRef.id}',
        );
      } catch (firestoreError) {
        debugPrint('CRITICAL: Error saving to Firestore: $firestoreError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not save to history: $firestoreError'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "Sorry, I encountered an error: ${e.toString()}",
              role: MessageRole.assistant,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Civic Assistant',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.premiumNavy,
                AppColors.premiumNavy.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      body: _historyLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ADDED: Global Scope Indicator (Change 1)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌍', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 6),
                      Text(
                        'Fact-checking against global official sources',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
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
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.premiumNavy : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkNavy.withOpacity(0.8) : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.premiumGold,
                            size: 22,
                          ),
                          onPressed: () => _showImageSourceActionSheet(context),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Enter a rumor or pick an image...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 10,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _submitFactCheck(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ScaleTransition(
                          scale: AlwaysStoppedAnimation(_isLoading ? 0.8 : 1.0),
                          child: IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 20),
                            onPressed:
                                (_isLoading ||
                                    (_textController.text.trim().isEmpty &&
                                        _selectedImage == null))
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
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
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: isUser
                              ? const LinearGradient(
                                  colors: [AppColors.deepPurple, AppColors.electricBlue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isUser
                              ? null
                              : isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.white,
                          border: Border.all(
                            color: isUser
                                ? Colors.white.withOpacity(0.1)
                                : isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(22),
                            topRight: const Radius.circular(22),
                            bottomLeft: Radius.circular(isUser ? 22 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 22),
                          ),
                          boxShadow: [
                            if (!isUser)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
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
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            height: 200,
                                            color: colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.3),
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                  ),
                                ),
                              ),
                            if (message.text.isNotEmpty)
                              Text(
                                message.text,
                                style: GoogleFonts.inter(
                                  color: isUser
                                      ? Colors.white
                                      : isDark
                                          ? Colors.white.withOpacity(0.9)
                                          : AppColors.textDark,
                                  fontSize: 15,
                                  fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                                  height: 1.4,
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
                    // ADDED: Collapsible Sources Cross-Referenced section (Change 2)
                    _buildSourcesCrossReferenced(message.result!),

                    // ADDED: Know More Button functionality (Change 1)
                    if (!message.isDeepAnalysisRequested &&
                        message.role == MessageRole.assistant)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _requestDeepAnalysis(message),
                            icon: const Icon(Icons.info_outline, size: 16),
                            label: const Text(
                              'Know More',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary.withValues(
                                alpha: 0.8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ADDED: Connect "Know More" button to deep analysis API and update Firestore (Change 2)
  Future<void> _requestDeepAnalysis(ChatMessage sourceMessage) async {
    setState(() {
      sourceMessage.isDeepAnalysisRequested = true;
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final historyIndex = _messages.indexOf(sourceMessage);
      final relevantMessages = _messages.sublist(0, historyIndex + 1);

      List<Map<String, dynamic>> apiHistory = [];
      for (var msg in relevantMessages) {
        if (msg.role == MessageRole.user) {
          apiHistory.add({'role': 'user', 'content': msg.text});
        } else {
          String content = msg.text;
          if (msg.result != null) {
            content +=
                '\nResult: ${msg.result!.status}, Accuracy: ${msg.result!.score}%\nExplanation: ${msg.result!.simpleDescription}';
          }
          apiHistory.add({'role': 'assistant', 'content': content});
        }
      }

      final prompt =
          "Based on your previous fact-check response, provide deeper analysis:\n"
          "1. Detailed background context about this topic\n"
          "2. Historical precedents or similar past incidents\n"
          "3. Which specific official sources or social media accounts confirmed or denied this\n"
          "4. What experts or official bodies have said about this\n"
          "5. Any related misinformation patterns to be aware of\n"
          "Keep it factual and cite sources where possible.";

      apiHistory.add({'role': 'user', 'content': prompt});

      final deepAnalysisResponse = await widget.service.getDeepAnalysis(
        apiHistory,
      );

      setState(() {
        _messages.add(
          ChatMessage(text: deepAnalysisResponse, role: MessageRole.assistant),
        );
      });

      if (sourceMessage.firestoreDocId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('fact_checks')
              .doc(sourceMessage.firestoreDocId)
              .update({'deepAnalysis': deepAnalysisResponse});
        } catch (e) {
          debugPrint('Error updating deep analysis to Firestore: $e');
        }
      }
    } catch (e) {
      setState(() {
        sourceMessage.isDeepAnalysisRequested = false;
        _messages.add(
          ChatMessage(
            text: "Failed to get deeper analysis: $e",
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


  Widget _buildResultCard(FactResult result) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    IconData statusIcon;
    Color statusColor;
    
    switch (result.status.toLowerCase().trim()) {
      case 'authentic':
      case 'success':
        statusIcon = Icons.verified;
        statusColor = AppColors.emeraldGreen;
        break;
      case 'counterfeit':
      case 'error':
      case 'fake':
        statusIcon = Icons.dangerous;
        statusColor = AppColors.crimsonRed;
        break;
      case 'misleading':
      case 'warning':
        statusIcon = Icons.warning;
        statusColor = AppColors.amberWarning;
        break;
      default:
        statusIcon = Icons.help_outline;
        statusColor = AppColors.electricBlue;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: statusColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.status.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${result.score}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.isAiGenerated == true) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.amberWarning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.amberWarning.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology, color: AppColors.amberWarning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI-Generated Content Detected',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amberWarning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Analysis Verdict',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.simpleDescription,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
                    ),
                  ),
                  if (result.references.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Official Sources',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.premiumGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: result.references.map((url) => InkWell(
                        onTap: () => _launchURL(url),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.link, size: 14, color: AppColors.electricBlue),
                              const SizedBox(width: 6),
                              Text(
                                'View Source',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.electricBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  // ADDED: Collapsible Sources Cross-Referenced section
  Widget _buildSourcesCrossReferenced(FactResult result) {
    if (result.socialSourcesChecked == null || result.socialSourcesChecked!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sources Cross-Referenced:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: result.socialSourcesChecked!.map((source) => Chip(
              label: Text(
                source,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
              backgroundColor: Colors.white.withOpacity(0.05),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Support for re-rendering typing indicator if needed
  Widget _buildTypingIndicator() {
    return Container(); // Simplified for now
  }
}
