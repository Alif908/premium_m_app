import 'package:flutter/material.dart';
import 'package:premium_m_app/models/store_model.dart';
import 'package:premium_m_app/services/store_api_service.dart';

class PopupsListScreen extends StatefulWidget {
  const PopupsListScreen({super.key});

  @override
  State<PopupsListScreen> createState() => _PopupsListScreenState();
}

class _PopupsListScreenState extends State<PopupsListScreen> {
  List<PopupModel> _popups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPopups();
  }

  Future<void> _loadPopups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final popups = await StoreApiService.getPopups();
      if (!mounted) return;
      setState(() {
        _popups = popups;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load popups';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(PopupModel popup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Popup'),
        content: Text('Delete "${popup.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await StoreApiService.deletePopup(popup.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Popup deleted')));
      _loadPopups();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete popup')));
    }
  }

  Future<void> _confirmToggleActive(PopupModel popup) async {
    final newStatus = !popup.isActive;
    try {
      await StoreApiService.updatePopup(id: popup.id, isActive: newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Popup activated' : 'Popup deactivated'),
        ),
      );
      _loadPopups();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update popup status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F3),
      appBar: AppBar(
        title: const Text('My Popups'),
        backgroundColor: const Color(0xFFEC4899),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPopups,
        color: const Color(0xFFEC4899),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFEC4899)),
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFF8E8E8E)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _loadPopups,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              )
            : _popups.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 140),
                  Icon(
                    Icons.campaign_outlined,
                    size: 56,
                    color: Color(0xFFCCCCCC),
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No popups added yet',
                      style: TextStyle(color: Color(0xFF8E8E8E)),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _popups.length,
                itemBuilder: (context, index) {
                  final popup = _popups[index];
                  final bannerUrl = StoreApiService.resolveBannerUrl(
                    popup.banner,
                  );
                  final isActive = popup.isActive;
                  final isExpired = popup.isExpired;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4D94).withOpacity(0.07),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (bannerUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              bannerUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE4EE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Color(0xFFFF4D94),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4EE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.campaign,
                              color: Color(0xFFFF4D94),
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                popup.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                popup.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8E8E8E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                popup.expiryDate != null
                                    ? 'Expires: ${popup.formattedExpiry}'
                                    : 'Expires: -',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8E8E8E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _confirmToggleActive(popup),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (isActive && !isExpired)
                                            ? const Color(
                                                0xFF34C759,
                                              ).withOpacity(0.15)
                                            : Colors.grey.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isExpired
                                            ? 'Expired'
                                            : (isActive
                                                  ? 'Active'
                                                  : 'Inactive'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: (isActive && !isExpired)
                                              ? const Color(0xFF34C759)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                          onPressed: () => _confirmDelete(popup),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
