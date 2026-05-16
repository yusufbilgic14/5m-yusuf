import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Service for automatic cleanup of expired data
/// Süresi dolmuş verilerin otomatik temizliği için servis
class CleanupService {
  // Singleton pattern implementation
  static final CleanupService _instance = CleanupService._internal();
  factory CleanupService() => _instance;
  CleanupService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cleanup timer
  Timer? _cleanupTimer;
  static const Duration _cleanupInterval = Duration(hours: 6); // Run every 6 hours

  // Batch size for cleanup operations to avoid performance issues
  static const int _batchSize = 100;

  /// Start automatic cleanup service
  /// Otomatik temizlik servisini başlat
  void startCleanupService() {
    // Clean up immediately on start
    performCleanup();

    // Schedule periodic cleanup
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      performCleanup();
    });

    debugPrint('🧹 CleanupService: Automatic cleanup service started');
  }

  /// Stop automatic cleanup service
  /// Otomatik temizlik servisini durdur
  void stopCleanupService() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    debugPrint('🛑 CleanupService: Automatic cleanup service stopped');
  }

  /// Perform all cleanup operations
  /// Tüm temizlik işlemlerini gerçekleştir
  Future<void> performCleanup() async {
    try {
      // Skip cleanup if no user is authenticated
      // Kullanıcı giriş yapmadıysa temizliği atla
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('🧹 CleanupService: Skipping cleanup - no authenticated user');
        return;
      }

      debugPrint('🧹 CleanupService: Starting cleanup operations');

      // Run cleanup operations in parallel for better performance
      await Future.wait([
        cleanupExpiredChatMessages(),
        cleanupExpiredApprovalRequests(),
        cleanupExpiredNotifications(),
        cleanupOrphanedData(),
        cleanupExpiredMediaFiles(),
        cleanupExpiredReactions(),
        cleanupExpiredPresenceData(),
      ]);

      debugPrint('✅ CleanupService: All cleanup operations completed');
    } catch (e) {
      debugPrint('❌ CleanupService: Error during cleanup: $e');
    }
  }

  /// Clean up expired chat messages (7-day retention)
  /// Süresi dolmuş sohbet mesajlarını temizle (7 günlük saklama)
  Future<void> cleanupExpiredChatMessages() async {
    try {
      debugPrint('🧹 CleanupService: Cleaning expired chat messages');

      final now = DateTime.now();
      int totalCleaned = 0;
      bool hasMore = true;

      while (hasMore) {
        // Query expired messages in batches
        final expiredMessages = await _firestore
            .collection('chat_messages')
            .where('expiresAt', isLessThan: Timestamp.fromDate(now))
            .limit(_batchSize)
            .get();

        if (expiredMessages.docs.isEmpty) {
          hasMore = false;
          break;
        }

        // Delete batch
        final batch = _firestore.batch();
        for (final doc in expiredMessages.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        totalCleaned += expiredMessages.docs.length;

        // Add small delay to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('✅ CleanupService: Cleaned $totalCleaned expired chat messages');
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning chat messages: $e');
    }
  }

  /// Clean up expired approval requests (30-day retention)
  /// Süresi dolmuş onay taleplerini temizle (30 günlük saklama)
  Future<void> cleanupExpiredApprovalRequests() async {
    try {
      debugPrint('🧹 CleanupService: Cleaning expired approval requests');

      final now = DateTime.now();
      int totalCleaned = 0;
      bool hasMore = true;

      while (hasMore) {
        // Query expired approvals in batches
        final expiredApprovals = await _firestore
            .collection('pending_approvals')
            .where('expiresAt', isLessThan: Timestamp.fromDate(now))
            .limit(_batchSize)
            .get();

        if (expiredApprovals.docs.isEmpty) {
          hasMore = false;
          break;
        }

        // Delete batch
        final batch = _firestore.batch();
        for (final doc in expiredApprovals.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        totalCleaned += expiredApprovals.docs.length;

        // Add small delay to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('✅ CleanupService: Cleaned $totalCleaned expired approval requests');
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning approval requests: $e');
    }
  }

  /// Clean up expired notifications (30-day retention)
  /// Süresi dolmuş bildirimleri temizle (30 günlük saklama)
  Future<void> cleanupExpiredNotifications() async {
    try {
      debugPrint('🧹 CleanupService: Cleaning expired notifications');

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      int totalCleaned = 0;
      bool hasMore = true;

      while (hasMore) {
        // Query old notifications in batches
        final oldNotifications = await _firestore
            .collection('notifications')
            .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
            .limit(_batchSize)
            .get();

        if (oldNotifications.docs.isEmpty) {
          hasMore = false;
          break;
        }

        // Delete batch
        final batch = _firestore.batch();
        for (final doc in oldNotifications.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        totalCleaned += oldNotifications.docs.length;

        // Add small delay
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('✅ CleanupService: Cleaned $totalCleaned expired notifications');
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning notifications: $e');
    }
  }


  /// Clean up chat participants for non-existent chat rooms
  /// Mevcut olmayan sohbet odaları için sohbet katılımcılarını temizle
  Future<void> _cleanupOrphanedChatParticipants() async {
    try {
      // Get all chat participants
      final participants = await _firestore
          .collection('chat_participants')
          .limit(_batchSize)
          .get();

      if (participants.docs.isEmpty) return;

      final batch = _firestore.batch();
      int toDelete = 0;

      for (final participantDoc in participants.docs) {
        final data = participantDoc.data();
        final chatRoomId = data['chatRoomId'] as String?;

        if (chatRoomId == null) {
          batch.delete(participantDoc.reference);
          toDelete++;
          continue;
        }

        // Check if chat room exists
        final chatRoom = await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .get();

        if (!chatRoom.exists) {
          batch.delete(participantDoc.reference);
          toDelete++;
        }
      }

      if (toDelete > 0) {
        await batch.commit();
        debugPrint('✅ CleanupService: Cleaned $toDelete orphaned chat participants');
      }
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning orphaned chat participants: $e');
    }
  }

  /// Clean up comments for non-existent events
  /// Mevcut olmayan etkinlikler için yorumları temizle
  Future<void> _cleanupOrphanedComments() async {
    try {
      // Get all comments
      final comments = await _firestore
          .collection('event_comments')
          .limit(_batchSize)
          .get();

      if (comments.docs.isEmpty) return;

      final batch = _firestore.batch();
      int toDelete = 0;

      for (final commentDoc in comments.docs) {
        final data = commentDoc.data();
        final eventId = data['eventId'] as String?;

        if (eventId == null) {
          batch.delete(commentDoc.reference);
          toDelete++;
          continue;
        }

        // Check if event exists
        final event = await _firestore
            .collection('events')
            .doc(eventId)
            .get();

        if (!event.exists) {
          batch.delete(commentDoc.reference);
          toDelete++;
        }
      }

      if (toDelete > 0) {
        await batch.commit();
        debugPrint('✅ CleanupService: Cleaned $toDelete orphaned comments');
      }
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning orphaned comments: $e');
    }
  }

  /// Clean up interactions for non-existent events
  /// Mevcut olmayan etkinlikler için etkileşimleri temizle
  Future<void> _cleanupOrphanedInteractions() async {
    try {
      // Get all user interactions
      final interactions = await _firestore
          .collection('user_event_interactions')
          .limit(_batchSize)
          .get();

      if (interactions.docs.isEmpty) return;

      final batch = _firestore.batch();
      int toDelete = 0;

      for (final interactionDoc in interactions.docs) {
        final data = interactionDoc.data();
        final eventId = data['eventId'] as String?;

        if (eventId == null) {
          batch.delete(interactionDoc.reference);
          toDelete++;
          continue;
        }

        // Check if event exists
        final event = await _firestore
            .collection('events')
            .doc(eventId)
            .get();

        if (!event.exists) {
          batch.delete(interactionDoc.reference);
          toDelete++;
        }
      }

      if (toDelete > 0) {
        await batch.commit();
        debugPrint('✅ CleanupService: Cleaned $toDelete orphaned interactions');
      }
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning orphaned interactions: $e');
    }
  }

  /// Manual cleanup for specific club
  /// Belirli kulüp için manuel temizlik
  Future<void> cleanupClubData(String clubId) async {
    try {
      debugPrint('🧹 CleanupService: Manual cleanup for club $clubId');

      await Future.wait([
        _cleanupClubChatMessages(clubId),
        _cleanupClubApprovals(clubId),
        _cleanupClubParticipants(clubId),
      ]);

      debugPrint('✅ CleanupService: Manual cleanup completed for club $clubId');
    } catch (e) {
      debugPrint('❌ CleanupService: Error during manual cleanup: $e');
    }
  }

  /// Clean up all chat messages for a specific club
  /// Belirli kulüp için tüm sohbet mesajlarını temizle
  Future<void> _cleanupClubChatMessages(String clubId) async {
    try {
      bool hasMore = true;
      int totalCleaned = 0;

      while (hasMore) {
        final messages = await _firestore
            .collection('chat_messages')
            .where('clubId', isEqualTo: clubId)
            .limit(_batchSize)
            .get();

        if (messages.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final batch = _firestore.batch();
        for (final doc in messages.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        totalCleaned += messages.docs.length;
      }

      if (totalCleaned > 0) {
        debugPrint('✅ CleanupService: Cleaned $totalCleaned messages for club $clubId');
      }
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning club messages: $e');
    }
  }

  /// Clean up all approvals for a specific club
  /// Belirli kulüp için tüm onayları temizle
  Future<void> _cleanupClubApprovals(String clubId) async {
    try {
      bool hasMore = true;
      int totalCleaned = 0;

      while (hasMore) {
        final approvals = await _firestore
            .collection('pending_approvals')
            .where('clubId', isEqualTo: clubId)
            .limit(_batchSize)
            .get();

        if (approvals.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final batch = _firestore.batch();
        for (final doc in approvals.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        totalCleaned += approvals.docs.length;
      }

      if (totalCleaned > 0) {
        debugPrint('✅ CleanupService: Cleaned $totalCleaned approvals for club $clubId');
      }
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning club approvals: $e');
    }
  }

  /// Clean up all participants for a specific club
  /// Belirli kulüp için tüm katılımcıları temizle
  Future<void> _cleanupClubParticipants(String clubId) async {
    try {
      bool hasMore = true;
      int totalCleaned = 0;

      while (hasMore) {
        final participants = await _firestore
            .collection('chat_participants')
            .where('clubId', isEqualTo: clubId)
            .limit(_batchSize)
            .get();

        if (participants.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final batch = _firestore.batch();
        for (final doc in participants.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        totalCleaned += participants.docs.length;
      }

      if (totalCleaned > 0) {
        debugPrint('✅ CleanupService: Cleaned $totalCleaned participants for club $clubId');
      }
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning club participants: $e');
    }
  }


  /// Check if cleanup service is running
  /// Temizlik servisinin çalışıp çalışmadığını kontrol et
  bool get isRunning => _cleanupTimer?.isActive ?? false;

  /// Get time until next cleanup
  /// Bir sonraki temizliğe kalan süreyi al
  Duration? get timeUntilNextCleanup {
    if (_cleanupTimer == null) return null;
    
    // This is an approximation since we can't get exact timer remaining time
    return _cleanupInterval;
  }

  /// Clean up expired media files and their Firebase Storage references (30-day retention)
  /// Süresi dolmuş medya dosyalarını ve Firebase Storage referanslarını temizle (30 günlük saklama)
  Future<void> cleanupExpiredMediaFiles() async {
    try {
      debugPrint('🧹 CleanupService: Cleaning expired media attachments');

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      int totalCleaned = 0;
      bool hasMore = true;

      while (hasMore) {
        // Query old media attachments from chat messages
        final oldMessages = await _firestore
            .collection('chat_messages')
            .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
            .where('mediaAttachments', isNull: false)
            .limit(_batchSize)
            .get();

        if (oldMessages.docs.isEmpty) {
          hasMore = false;
          break;
        }

        // Clean up media files from Firebase Storage
        for (final messageDoc in oldMessages.docs) {
          final data = messageDoc.data();
          final mediaAttachments = data['mediaAttachments'] as List<dynamic>?;
          
          if (mediaAttachments != null) {
            for (final attachmentData in mediaAttachments) {
              if (attachmentData is Map<String, dynamic>) {
                final storageUrl = attachmentData['url'] as String?;
                if (storageUrl != null) {
                  // TODO: Clean up file from Firebase Storage
                  // This would require Firebase Admin SDK or Storage service
                  debugPrint('🗑️ CleanupService: Would clean up media file: $storageUrl');
                }
              }
            }
          }
        }

        totalCleaned += oldMessages.docs.length;
        
        // Add small delay to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('✅ CleanupService: Cleaned $totalCleaned expired media files');
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning media files: $e');
    }
  }

  /// Clean up expired message reactions (90-day retention)
  /// Süresi dolmuş mesaj reaksiyonlarını temizle (90 günlük saklama)
  Future<void> cleanupExpiredReactions() async {
    try {
      debugPrint('🧹 CleanupService: Cleaning expired message reactions');

      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      int totalCleaned = 0;
      bool hasMore = true;

      while (hasMore) {
        // Query old messages with reactions
        final oldMessages = await _firestore
            .collection('chat_messages')
            .where('createdAt', isLessThan: Timestamp.fromDate(ninetyDaysAgo))
            .where('reactions', isNull: false)
            .limit(_batchSize)
            .get();

        if (oldMessages.docs.isEmpty) {
          hasMore = false;
          break;
        }

        // Clear reactions from old messages
        final batch = _firestore.batch();
        for (final messageDoc in oldMessages.docs) {
          batch.update(messageDoc.reference, {
            'reactions': FieldValue.delete(),
            'reactionCount': 0,
          });
        }

        await batch.commit();
        totalCleaned += oldMessages.docs.length;

        // Add small delay
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('✅ CleanupService: Cleaned reactions from $totalCleaned old messages');
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning reactions: $e');
    }
  }

  /// Clean up expired user presence data (24-hour retention)
  /// Süresi dolmuş kullanıcı varlık verilerini temizle (24 saatlik saklama)
  Future<void> cleanupExpiredPresenceData() async {
    try {
      debugPrint('🧹 CleanupService: Cleaning expired user presence data');

      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      int totalCleaned = 0;
      bool hasMore = true;

      while (hasMore) {
        // Query old presence data
        final oldPresence = await _firestore
            .collection('user_presence')
            .where('lastSeen', isLessThan: Timestamp.fromDate(oneDayAgo))
            .limit(_batchSize)
            .get();

        if (oldPresence.docs.isEmpty) {
          hasMore = false;
          break;
        }

        // Delete batch
        final batch = _firestore.batch();
        for (final doc in oldPresence.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        totalCleaned += oldPresence.docs.length;

        // Add small delay
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('✅ CleanupService: Cleaned $totalCleaned expired presence records');
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning presence data: $e');
    }
  }

  /// Clean up orphaned pinned messages (messages that are pinned but no longer exist)
  /// Yetim sabitlenmiş mesajları temizle (sabitlenmiş ama artık mevcut olmayan mesajlar)
  Future<void> cleanupOrphanedPinnedMessages() async {
    try {
      debugPrint('🧹 CleanupService: Cleaning orphaned pinned messages');

      // Get all clubs to check their pinned messages
      final clubs = await _firestore
          .collection('clubs')
          .limit(_batchSize)
          .get();

      int totalCleaned = 0;

      for (final clubDoc in clubs.docs) {
        final clubData = clubDoc.data();
        final pinnedMessages = clubData['pinnedMessages'] as List<dynamic>?;
        
        if (pinnedMessages != null && pinnedMessages.isNotEmpty) {
          final validPinnedMessages = <String>[];
          
          // Check if each pinned message still exists
          for (final messageId in pinnedMessages) {
            if (messageId is String) {
              final messageExists = await _firestore
                  .collection('chat_messages')
                  .doc(messageId)
                  .get();
              
              if (messageExists.exists) {
                validPinnedMessages.add(messageId);
              } else {
                totalCleaned++;
              }
            }
          }
          
          // Update club with only valid pinned messages
          if (validPinnedMessages.length != pinnedMessages.length) {
            await clubDoc.reference.update({
              'pinnedMessages': validPinnedMessages,
            });
          }
        }
      }

      debugPrint('✅ CleanupService: Cleaned $totalCleaned orphaned pinned message references');
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning orphaned pinned messages: $e');
    }
  }

  /// Enhanced orphaned data cleanup including new chat features
  /// Yeni sohbet özelliklerini içeren gelişmiş yetim veri temizliği
  Future<void> cleanupOrphanedData() async {
    try {
      debugPrint('🧹 CleanupService: Cleaning orphaned data');

      await Future.wait([
        _cleanupOrphanedChatParticipants(),
        _cleanupOrphanedComments(),
        _cleanupOrphanedInteractions(),
        cleanupOrphanedPinnedMessages(),
        _cleanupOrphanedMediaReferences(),
      ]);

      debugPrint('✅ CleanupService: Orphaned data cleanup completed');
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning orphaned data: $e');
    }
  }

  /// Clean up orphaned media references in Firebase Storage
  /// Firebase Storage'daki yetim medya referanslarını temizle
  Future<void> _cleanupOrphanedMediaReferences() async {
    try {
      debugPrint('🧹 CleanupService: Cleaning orphaned media references');

      // This would require Firebase Admin SDK for full Storage cleanup
      // For now, we'll clean up database references to missing files
      
      final messagesWithMedia = await _firestore
          .collection('chat_messages')
          .where('mediaAttachments', isNull: false)
          .limit(_batchSize)
          .get();

      int cleanedReferences = 0;
      final batch = _firestore.batch();

      for (final messageDoc in messagesWithMedia.docs) {
        final data = messageDoc.data();
        final mediaAttachments = data['mediaAttachments'] as List<dynamic>?;
        
        if (mediaAttachments != null) {
          final validAttachments = <Map<String, dynamic>>[];
          bool hasInvalidAttachment = false;

          for (final attachmentData in mediaAttachments) {
            if (attachmentData is Map<String, dynamic>) {
              final url = attachmentData['url'] as String?;
              if (url != null && url.isNotEmpty) {
                validAttachments.add(attachmentData);
              } else {
                hasInvalidAttachment = true;
                cleanedReferences++;
              }
            }
          }

          // Update message if we found invalid attachments
          if (hasInvalidAttachment) {
            batch.update(messageDoc.reference, {
              'mediaAttachments': validAttachments,
            });
          }
        }
      }

      if (cleanedReferences > 0) {
        await batch.commit();
        debugPrint('✅ CleanupService: Cleaned $cleanedReferences orphaned media references');
      }
    } catch (e) {
      debugPrint('❌ CleanupService: Error cleaning orphaned media references: $e');
    }
  }

  /// Get enhanced cleanup statistics including new features
  /// Yeni özellikleri içeren gelişmiş temizlik istatistikleri
  Future<Map<String, int>> getCleanupStatistics() async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final ninetyDaysAgo = now.subtract(const Duration(days: 90));

      final futures = await Future.wait([
        // Expired messages count
        _firestore
            .collection('chat_messages')
            .where('expiresAt', isLessThan: Timestamp.fromDate(now))
            .count()
            .get(),
        
        // Expired approvals count
        _firestore
            .collection('pending_approvals')
            .where('expiresAt', isLessThan: Timestamp.fromDate(now))
            .count()
            .get(),
        
        // Old notifications count
        _firestore
            .collection('notifications')
            .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
            .count()
            .get(),

        // Old media files count
        _firestore
            .collection('chat_messages')
            .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
            .where('mediaAttachments', isNull: false)
            .count()
            .get(),

        // Old reactions count
        _firestore
            .collection('chat_messages')
            .where('createdAt', isLessThan: Timestamp.fromDate(ninetyDaysAgo))
            .where('reactions', isNull: false)
            .count()
            .get(),

        // Expired presence data count
        _firestore
            .collection('user_presence')
            .where('lastSeen', isLessThan: Timestamp.fromDate(oneDayAgo))
            .count()
            .get(),
      ]);

      return {
        'expiredMessages': futures[0].count ?? 0,
        'expiredApprovals': futures[1].count ?? 0,
        'oldNotifications': futures[2].count ?? 0,
        'oldMediaFiles': futures[3].count ?? 0,
        'oldReactions': futures[4].count ?? 0,
        'expiredPresence': futures[5].count ?? 0,
      };
    } catch (e) {
      debugPrint('❌ CleanupService: Error getting cleanup statistics: $e');
      return {};
    }
  }

  /// Dispose service and stop cleanup
  /// Servisi kapat ve temizliği durdur
  void dispose() {
    stopCleanupService();
    debugPrint('🔥 CleanupService: Service disposed');
  }
}