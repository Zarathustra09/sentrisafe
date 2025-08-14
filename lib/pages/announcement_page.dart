import 'package:flutter/material.dart';
import 'package:sentrisafe/models/announcement_model.dart';
import 'package:sentrisafe/services/announcement/announcement_service.dart';
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

    final result = await AnnouncementService.getAnnouncements(page: currentPage + 1);

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
    await _loadAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAnnouncements,
      color: Constants.primary,
      backgroundColor: Constants.surface,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Constants.primary,
          ),
          SizedBox(height: AppConstants.spacingM),
          Text(
            'Loading announcements...',
            style: TextStyle(
              color: Constants.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
                    'There are no announcements available at the moment',
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
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
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
    return Container(
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
                    announcement.user?.name.substring(0, 1).toUpperCase() ?? 'A',
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
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
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
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
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
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
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
                        ? AppConstants.spacingS : 0,
                    ),
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
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

          const SizedBox(height: AppConstants.spacingS),
        ],
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
}