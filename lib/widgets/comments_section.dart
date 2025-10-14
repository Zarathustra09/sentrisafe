import 'package:flutter/material.dart';
import 'package:sentrisafe/models/comment_model.dart';
import 'package:sentrisafe/services/comment/comment_service.dart';
import 'package:moment_dart/moment_dart.dart';

class CommentsSection extends StatefulWidget {
  final int announcementId;
  final ScrollController?
      parentScrollController; // Optional parent scroll controller

  const CommentsSection({
    Key? key,
    required this.announcementId,
    this.parentScrollController,
  }) : super(key: key);

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _hasMorePages = false;
  int _currentPage = 1;
  final TextEditingController _commentController = TextEditingController();
  Comment? _replyingTo; // Track which comment we're replying to
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentInputKey =
      GlobalKey(); // Key for comment input section
  final Map<int, GlobalKey> _commentKeys = {}; // Keys for each comment

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final page = loadMore ? _currentPage + 1 : 1;

    final result = await CommentService.getComments(
      announcementId: widget.announcementId,
      page: page,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;

        if (result['success']) {
          final newComments = result['comments'] as List<Comment>;
          if (loadMore) {
            _comments.addAll(newComments);
          } else {
            _comments = newComments;
          }

          final pagination = result['pagination'];
          _currentPage = pagination['current_page'];
          _hasMorePages = pagination['current_page'] < pagination['last_page'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['error'] ?? 'Failed to load comments')),
          );
        }
      });
    }
  }

  void _scrollToCommentInput() {
    // Scroll to the comment input key position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_commentInputKey.currentContext != null) {
        Scrollable.ensureVisible(
          _commentInputKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.0, // Position at the top
        );
      }
    });
  }

  void _scrollToComment(int commentId) {
    // Find the comment and scroll to it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _commentKeys[commentId];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.2, // Position comment near the top
        );
      }
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final content = _commentController.text.trim();
    final replyingToId = _replyingTo?.id; // Store before clearing
    _commentController.clear();

    final result = await CommentService.addComment(
      announcementId: widget.announcementId,
      content: content,
      parentId: _replyingTo?.id, // Include parent ID if replying
    );

    if (mounted) {
      setState(() {
        _replyingTo = null; // Clear reply state
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Comment added')),
        );
        await _loadComments(); // Reload to show new comment

        // Scroll back to the replied comment if there was one
        if (replyingToId != null) {
          _scrollToComment(replyingToId);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to add comment')),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await CommentService.deleteComment(
      commentId: commentId,
    );

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Comment deleted')),
        );
        _loadComments(); // Reload comments
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['error'] ?? 'Failed to delete comment')),
        );
      }
    }
  }

  Future<void> _editComment(Comment comment) async {
    final controller = TextEditingController(text: comment.content);
    String? newContent;

    try {
      newContent = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter your comment',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      // Dispose controller after dialog is completely closed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }

    if (newContent == null || newContent.isEmpty) return;

    final result = await CommentService.updateComment(
      commentId: comment.id,
      content: newContent,
    );

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Comment updated')),
        );
        _loadComments(); // Reload comments
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['error'] ?? 'Failed to update comment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comment input field - Reddit style
        Container(
          key: _commentInputKey, // Add key for scrolling
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              bottom: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_replyingTo != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[900]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border(
                      left: BorderSide(color: Colors.blue, width: 3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Replying to ${_replyingTo!.user?.name ?? "Unknown"}',
                              style: TextStyle(
                                color: Colors.blue[300],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _replyingTo!.displayContent,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 20, color: Colors.grey[400]),
                        onPressed: () {
                          setState(() {
                            _replyingTo = null;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[800],
                    child:
                        Icon(Icons.person, size: 20, color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[700]!, width: 1),
                      ),
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: _replyingTo != null
                              ? 'Write a reply...'
                              : 'What are your thoughts?',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, size: 20),
                      onPressed: _addComment,
                      color: Colors.white,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Comments list
        if (_isLoading && _comments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(Icons.comment_outlined,
                      size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'No comments yet',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share your thoughts',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length + (_hasMorePages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _comments.length) {
                // Load more button - Reddit style
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : OutlinedButton.icon(
                            onPressed: () => _loadComments(loadMore: true),
                            icon: const Icon(Icons.expand_more),
                            label: const Text('Load More Comments'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue[400],
                              side: BorderSide(color: Colors.grey[700]!),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                  ),
                );
              }

              final comment = _comments[index];
              // Create or get key for this comment
              _commentKeys.putIfAbsent(comment.id, () => GlobalKey());

              return _CommentCard(
                key: _commentKeys[comment.id],
                comment: comment,
                onDelete: _deleteComment,
                onEdit: _editComment,
                onReply: (parentComment) {
                  setState(() {
                    _replyingTo = parentComment;
                  });
                  _commentController.clear();
                  // Scroll to comment input
                  _scrollToCommentInput();
                },
                level: 0, // Top-level comment
              );
            },
          ),
      ],
    );
  }
}

class _CommentCard extends StatefulWidget {
  final Comment comment;
  final Function(int) onDelete;
  final Function(Comment) onEdit;
  final Function(Comment) onReply;
  final int level; // Indentation level for nested comments

  const _CommentCard({
    Key? key,
    required this.comment,
    required this.onDelete,
    required this.onEdit,
    required this.onReply,
    required this.level,
  }) : super(key: key);

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  bool _showReplies = true; // Show replies by default

  String _getTimeAgo(DateTime dateTime) {
    final moment = Moment(dateTime);
    return moment.fromNow();
  }

  Color _getThreadLineColor() {
    final colors = [
      Colors.blue[700]!,
      Colors.orange[700]!,
      Colors.green[700]!,
      Colors.purple[700]!,
      Colors.red[700]!,
      Colors.teal[700]!,
    ];
    return colors[widget.level % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // Limit indentation to prevent overflow (max 5 levels to stay safe)
    final maxLevel = 5;
    final effectiveLevel = widget.level > maxLevel ? maxLevel : widget.level;
    // Use much reduced padding for deeper levels to prevent overflow
    final leftPadding = effectiveLevel <= 2
        ? (effectiveLevel * 8.0) // 8px for first 2 levels (16px total)
        : (16.0 + (effectiveLevel - 2) * 4.0); // Then 4px for each additional
    final showThreadLine = widget.level > 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left padding/spacing
          SizedBox(width: leftPadding),

          // Thread line
          if (showThreadLine)
            Container(
              width: 2,
              color: _getThreadLineColor(),
              margin: const EdgeInsets.only(right: 8), // Reduced from 10 to 8
            ),

          // Comment content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[850]!, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comment header and content
                  Container(
                    padding: EdgeInsets.only(
                      left: showThreadLine ? 0 : 12, // Reduced from 16 to 12
                      right: widget.level > 2
                          ? 4
                          : 8, // Less padding for deep nesting
                      top: 12,
                      bottom: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info and metadata
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                widget.comment.user?.name
                                        .substring(0, 1)
                                        .toUpperCase() ??
                                    'U',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.comment.user?.name ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getTimeAgo(widget.comment.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (widget.comment.updatedAt !=
                                widget.comment.createdAt) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(edited)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const Spacer(),
                            // Options menu (only if not deleted)
                            if (!widget.comment.isDeleted)
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_horiz,
                                    size: 20, color: Colors.grey[600]),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    widget.onEdit(widget.comment);
                                  } else if (value == 'delete') {
                                    widget.onDelete(widget.comment.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Comment content
                        Text(
                          widget.comment.displayContent,
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.comment.isDeleted
                                ? Colors.grey[600]
                                : Colors.white,
                            fontStyle: widget.comment.isDeleted
                                ? FontStyle.italic
                                : FontStyle.normal,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Action buttons
                        if (!widget.comment.isDeleted)
                          Row(
                            children: [
                              // Reply button
                              InkWell(
                                onTap: () => widget.onReply(widget.comment),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.reply,
                                          size: 16, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Reply',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Collapse/expand replies button
                              if (widget.comment.replies.isNotEmpty)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showReplies = !_showReplies;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _showReplies
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          size: 16,
                                          color: Colors.blue[400],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${widget.comment.replies.length} ${widget.comment.replies.length == 1 ? 'reply' : 'replies'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Nested replies
                  if (_showReplies && widget.comment.replies.isNotEmpty)
                    ...widget.comment.replies.map((reply) => _CommentCard(
                          comment: reply,
                          onDelete: widget.onDelete,
                          onEdit: widget.onEdit,
                          onReply: widget.onReply,
                          level: widget.level + 1,
                        )),
                ], // End of Column children
              ), // End of Column
            ), // End of Container
          ), // End of Expanded
        ], // End of Row children
      ), // End of Row
    ); // End of IntrinsicHeight
  }
}
