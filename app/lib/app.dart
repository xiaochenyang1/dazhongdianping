import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_config.dart';
import 'package:dazhongdianping_app/core/app_settings.dart';
import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/auth/login_screen.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/home_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_editor_screen.dart';
import 'package:dazhongdianping_app/features/circle/circle_repository.dart';
import 'package:dazhongdianping_app/features/circle/circle_square_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_repository.dart';
import 'package:dazhongdianping_app/features/notification/notification_repository.dart';
import 'package:dazhongdianping_app/features/notification/notification_screen.dart';
import 'package:dazhongdianping_app/features/message/conversation_list_screen.dart';
import 'package:dazhongdianping_app/features/message/message_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/user/user_center_screen.dart';
import 'package:dazhongdianping_app/features/user/device_lifecycle.dart';
import 'package:dazhongdianping_app/features/user/privacy_repository.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:dazhongdianping_app/features/user/public_user_profile_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class DazhongDianpingApp extends StatefulWidget {
  const DazhongDianpingApp({super.key});

  @override
  State<DazhongDianpingApp> createState() => _DazhongDianpingAppState();
}

class _DazhongDianpingAppState extends State<DazhongDianpingApp> {
  final settings = AppSettings();
  final sessionStore = SecureSessionStore();
  late final ApiClient apiClient;
  late final AuthController authController;

  @override
  void initState() {
    super.initState();
    apiClient = ApiClient(
      config: const AppConfig(),
      tokenProvider: sessionStore.readAccessToken,
      regionProvider: () => settings.region,
      languageProvider: () => settings.localeTag,
    );
    authController = AuthController(
      repository: AuthRepository(apiClient),
      store: sessionStore,
      deviceLifecycle: ApiDeviceLifecycle(
        repository: PrivacyRepository(apiClient),
        identityStore: SecureDeviceIdentityStore(),
      ),
    );
    authController.initialize();
  }

  @override
  void dispose() {
    settings.dispose();
    authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([settings, authController]),
      builder: (context, _) {
        final repository = ApiBrowseRepository(apiClient);
        final tradeRepository = TradeRepository(apiClient);
        final reservationRepository = ReservationRepository(apiClient);
        final communityRepository = CommunityRepository(apiClient);
        final reviewRepository = authController.currentUser == null
            ? null
            : ReviewRepository(apiClient);
        return MaterialApp(
          title: 'Local Life EU',
          debugShowCheckedModeBanner: false,
          locale: _localeFromTag(settings.localeTag),
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('zh', 'TW'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE85D2A),
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F5F2),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
          ),
          home: HomeScreen(
            repository: repository,
            region: settings.region,
            onRegionChanged: settings.setRegion,
            localeTag: settings.localeTag,
            onLocaleChanged: settings.setLocaleTag,
            thirdPartyConfig: const ThirdPartyConfig(),
            tradeRepository: tradeRepository,
            reservationRepository: reservationRepository,
            reviewRepository: reviewRepository,
            communityRepository: communityRepository,
            circleRepository: CircleRepository(apiClient),
            topicRepository: TopicRepository(apiClient),
            onCommunityLoginRequired: (screenContext) {
              Navigator.of(screenContext).push(
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    controller: authController,
                    onAuthenticated: (_) => Navigator.of(screenContext).pop(),
                  ),
                ),
              );
            },
            canCommunityInteract: authController.currentUser != null,
            onCommunityUserTap: (screenContext, userId) {
              Navigator.of(screenContext).push(
                MaterialPageRoute(
                  builder: (_) => PublicUserProfileScreen(
                    repository: UserRepository(apiClient),
                    userId: userId,
                    canFollow: authController.currentUser != null,
                    currentUserId: authController.currentUser?.id,
                    onMessage: (peerUserId) => Navigator.of(screenContext).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          repository: MessageRepository(apiClient),
                          conversation: ConversationSummary(
                            id: 0,
                            peerUserId: peerUserId,
                            peerNickname: '私信用户',
                            peerAvatar: '',
                            lastMessagePreview: '',
                            lastMessageAt: '',
                            unreadCount: 0,
                          ),
                          currentUserId: authController.currentUser!.id,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            currentUserLabel: authController.currentUser?.nickname,
            onNotificationTap: (screenContext) {
              if (authController.currentUser == null) {
                Navigator.of(screenContext).push(
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(
                      controller: authController,
                      onAuthenticated: (_) => Navigator.of(screenContext).pop(),
                    ),
                  ),
                );
                return;
              }
              Navigator.of(screenContext).push(
                MaterialPageRoute(
                  builder: (_) => NotificationScreen(
                    repository: NotificationRepository(apiClient),
                    onUserTap: (userId) {
                      Navigator.of(screenContext).push(
                        MaterialPageRoute(
                          builder: (_) => PublicUserProfileScreen(
                            repository: UserRepository(apiClient),
                            userId: userId,
                            canFollow: true,
                            currentUserId: authController.currentUser?.id,
                            onMessage: (peerUserId) =>
                                Navigator.of(screenContext).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      repository: MessageRepository(apiClient),
                                      conversation: ConversationSummary(
                                        id: 0,
                                        peerUserId: peerUserId,
                                        peerNickname: '私信用户',
                                        peerAvatar: '',
                                        lastMessagePreview: '',
                                        lastMessageAt: '',
                                        unreadCount: 0,
                                      ),
                                      currentUserId:
                                          authController.currentUser!.id,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            onProfileTap: (screenContext) {
              if (authController.currentUser != null) {
                Navigator.of(screenContext).push(
                  MaterialPageRoute(
                    builder: (_) => UserCenterScreen(
                      repository: UserRepository(apiClient),
                      authController: authController,
                      onMessages: () => Navigator.of(screenContext).push(
                        MaterialPageRoute(
                          builder: (_) => ConversationListScreen(
                            repository: MessageRepository(apiClient),
                            currentUserId: authController.currentUser!.id,
                          ),
                        ),
                      ),
                      onCircles: () => Navigator.of(screenContext).push(
                        MaterialPageRoute(
                          builder: (_) => CircleSquareScreen(
                            repository: CircleRepository(apiClient),
                            canInteract: true,
                            showJoinedOnly: true,
                            onCreatePost: (circle) =>
                                Navigator.of(screenContext).push(
                                  MaterialPageRoute(
                                    builder: (_) => PostEditorScreen(
                                      repository: communityRepository,
                                      circleId: circle.id,
                                      circleName: circle.name,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                return;
              }
              Navigator.of(screenContext).push(
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    controller: authController,
                    onAuthenticated: (_) => Navigator.of(screenContext).pop(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Locale _localeFromTag(String tag) {
    final parts = tag.split('-');
    return Locale(parts.first, parts.length > 1 ? parts[1] : null);
  }
}
