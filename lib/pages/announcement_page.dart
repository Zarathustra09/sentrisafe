import 'package:flutter/material.dart';
import 'package:sentrisafe/models/announcement_model.dart';
import 'package:sentrisafe/services/announcement/announcement_service.dart';
import 'package:sentrisafe/widgets/comments_section.dart';
import '../constants.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({Key? key}) : super(key: key);

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  List<Announcement> announcements = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  int currentPage = 1;
  int lastPage = 1;
  bool isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // For showing announcement details with comments
  bool _showAnnouncementDetail = false;
  Announcement? _selectedAnnouncement;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreAnnouncements();
    }
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    final result = await AnnouncementService.getAnnouncements(page: 1);

    if (mounted) {
      setState(() {
        isLoading = false;
        if (result['success']) {
          announcements = result['announcements'];
          currentPage = result['pagination']['current_page'];
          lastPage = result['pagination']['last_page'];
        } else {
          hasError = true;
          errorMessage = result['error'];
        }
      });
    }
  }

  Future<void> _loadMoreAnnouncements() async {
    if (isLoadingMore || currentPage >= lastPage) return;

    setState(() {
      isLoadingMore = true;
    });

    final result =
        await AnnouncementService.getAnnouncements(page: currentPage + 1);

    if (mounted) {
      setState(() {
        isLoadingMore = false;
        if (result['success']) {
          announcements.addAll(result['announcements']);
          currentPage = result['pagination']['current_page'];
        }
      });
    }
  }

  Future<void> _refreshAnnouncements() async {
    // Reset pagination and reload from first page
    setState(() {
      currentPage = 1;
      lastPage = 1;
      hasError = false;
      errorMessage = '';
    });

    await _loadAnnouncements();

    // Show success message after refresh
    if (mounted && !hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Announcements refreshed'),
          backgroundColor: Constants.success,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Similar pattern to home_page.dart
    if (_showAnnouncementDetail && _selectedAnnouncement != null) {
      return _buildAnnouncementDetail();
    }

    return RefreshIndicator(
      onRefresh: _refreshAnnouncements,
      color: Constants.primary,
      backgroundColor: Constants.surface,
      strokeWidth: 3,
      displacement: 50,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (hasError) {
      return _buildErrorState();
    }

    if (announcements.isEmpty) {
      return _buildEmptyState();
    }

    return _buildAnnouncementsList();
  }

  Widget _buildLoadingState() {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.4),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Constants.primary,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'Loading announcements...',
                style: TextStyle(
                  color: Constants.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingXL),
                  decoration: BoxDecoration(
                    color: Constants.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    boxShadow: [
                      BoxShadow(
                        color: Constants.black.withOpacity(0.1),
                        blurRadius: AppConstants.elevationL,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Constants.error,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        'Error Loading Announcements',
                        style: TextStyle(
                          color: Constants.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          color: Constants.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      ElevatedButton(
                        onPressed: _loadAnnouncements,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primary,
                          foregroundColor: Constants.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingXL),
                  decoration: BoxDecoration(
                    color: Constants.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    boxShadow: [
                      BoxShadow(
                        color: Constants.black.withOpacity(0.1),
                        blurRadius: AppConstants.elevationL,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.announcement_outlined,
                        size: 48,
                        color: Constants.accent,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        'No Announcements',
                        style: TextStyle(
                          color: Constants.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Text(
                        'Pull down to refresh and check for new announcements',
                        style: TextStyle(
                          color: Constants.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              Icon(
                Icons.announcement,
                color: Constants.primary,
                size: 24,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                'Announcements',
                style: TextStyle(
                  color: Constants.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                '${announcements.length} item${announcements.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Constants.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
            itemCount: announcements.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == announcements.length) {
                return _buildLoadingMoreIndicator();
              }
              return _buildAnnouncementCard(announcements[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: const Center(
        child: CircularProgressIndicator(
          color: Constants.primary,
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return GestureDetector(
      onTap: () {
        // Show detail view inline (like home page pattern)
        setState(() {
          _showAnnouncementDetail = true;
          _selectedAnnouncement = announcement;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
        decoration: BoxDecoration(
          color: Constants.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          boxShadow: [
            BoxShadow(
              color: Constants.black.withOpacity(0.1),
              blurRadius: AppConstants.elevationM,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and date
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Constants.primary,
                    radius: 20,
                    child: Text(
                      announcement.user?.name.substring(0, 1).toUpperCase() ??
                          'A',
                      style: const TextStyle(
                        color: Constants.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.user?.name ?? 'Administrator',
                          style: const TextStyle(
                            color: Constants.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatDate(announcement.createdAt),
                          style: const TextStyle(
                            color: Constants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (announcement.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Constants.success,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusS),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Constants.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Title
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
              child: Text(
                announcement.title,
                style: const TextStyle(
                  color: Constants.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingS),

            // Description
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
              child: Text(
                announcement.description,
                style: const TextStyle(
                  color: Constants.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),

            // Images if available
            if (announcement.images.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(AppConstants.spacingM),
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: announcement.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(
                        right: index < announcement.images.length - 1
                            ? AppConstants.spacingS
                            : 0,
                      ),
                      width: 300,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                        child: Image.network(
                          announcement.images[index].fullUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Constants.greyDark,
                              child: const Icon(
                                Icons.broken_image,
                                color: Constants.textSecondary,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            // View details/comments indicator
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 18,
                        color: Constants.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'View Comments',
                        style: TextStyle(
                          color: Constants.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Constants.textSecondary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingS),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Build announcement detail view with comments (inline, like home page pattern)
  Widget _buildAnnouncementDetail() {
    if (_selectedAnnouncement == null) return Container();

    return Container(
      color: Constants.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Back button and header
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: Constants.surface,
              boxShadow: [
                BoxShadow(
                  color: Constants.black.withOpacity(0.1),
                  blurRadius: AppConstants.elevationS,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showAnnouncementDetail = false;
                      _selectedAnnouncement = null;
                    });
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: Constants.textPrimary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Text(
                    'Announcement Details',
                    style: TextStyle(
                      color: Constants.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Announcement images
          if (_selectedAnnouncement!.images.isNotEmpty)
            Container(
              height: 250,
              color: Constants.greyDark,
              child: PageView.builder(
                itemCount: _selectedAnnouncement!.images.length,
                itemBuilder: (context, index) {
                  final image = _selectedAnnouncement!.images[index];
                  return Image.network(
                    image.fullUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Constants.greyDark,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Constants.textSecondary,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          // Announcement content
          Container(
            color: Constants.surface,
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info and date
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Constants.primary,
                      radius: 24,
                      child: Text(
                        _selectedAnnouncement!.user?.name
                                .substring(0, 1)
                                .toUpperCase() ??
                            'A',
                        style: const TextStyle(
                          color: Constants.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAnnouncement!.user?.name ??
                                'Administrator',
                            style: const TextStyle(
                              color: Constants.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Constants.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(_selectedAnnouncement!.createdAt),
                                style: const TextStyle(
                                  color: Constants.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_selectedAnnouncement!.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingS,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Constants.success,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusS),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Constants.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingL),

                // Title
                Text(
                  _selectedAnnouncement!.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Constants.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),

                // Description
                Text(
                  _selectedAnnouncement!.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Constants.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingS),

          // Comments Section
          Container(
            color: Constants.surface,
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.comment,
                      color: Constants.primary,
                      size: 22,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Constants.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                CommentsSection(
                  announcementId: _selectedAnnouncement!.id,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
