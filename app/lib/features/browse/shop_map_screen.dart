import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/location_service.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/browse/browse_error_localizer.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef ShopMapBuilder =
    Widget Function(
      BuildContext context,
      List<ShopSummary> shops,
      int selectedShopId,
      ValueChanged<int> onShopSelected,
    );

class ShopMapScreen extends StatefulWidget {
  const ShopMapScreen({
    super.key,
    required this.repository,
    required this.thirdPartyConfig,
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.canInteractReviews = false,
    this.mapBuilder,
    this.locationService = const GeolocatorLocationService(),
  });

  final BrowseRepository repository;
  final ThirdPartyConfig thirdPartyConfig;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final bool canInteractReviews;
  final ShopMapBuilder? mapBuilder;
  final LocationService locationService;

  @override
  State<ShopMapScreen> createState() => _ShopMapScreenState();
}

class _ShopMapScreenState extends State<ShopMapScreen> {
  late Future<List<ShopSummary>> _shops;
  int? _selectedShopId;
  bool _reloading = false;
  bool _locating = false;
  bool _loadingMapViewport = false;
  bool _locationPermissionGranted = false;
  UserLocation? _userLocation;
  GoogleMapController? _mapController;
  String? _lastViewportSignature;
  int _viewportRequestId = 0;

  bool get _supportsInteractiveMap =>
      widget.thirdPartyConfig.googleMapsInteractiveEnabled &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _shops = _loadShops();
  }

  Future<List<ShopSummary>> _loadShops() async {
    final shops = await widget.repository.loadMapShops();
    final mapped = shops.where(_hasValidCoordinates).toList();
    if (mapped.isNotEmpty &&
        !mapped.any((shop) => shop.id == _selectedShopId)) {
      _selectedShopId = mapped.first.id;
    }
    return mapped;
  }

  bool _hasValidCoordinates(ShopSummary shop) {
    final latitude = shop.latitude;
    final longitude = shop.longitude;
    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  Future<void> _reload() async {
    if (_reloading) return;
    final future = _loadShops();
    setState(() {
      _shops = future;
      _reloading = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  void _selectShop(int shopId) {
    if (_selectedShopId == shopId) return;
    setState(() => _selectedShopId = shopId);
    _focusShop(shopId);
  }

  Future<void> _focusShop(int shopId) async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      final shops = await _shops;
      ShopSummary? shop;
      for (final item in shops) {
        if (item.id == shopId) {
          shop = item;
          break;
        }
      }
      if (shop == null || !mounted) return;
      await controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(shop.latitude!, shop.longitude!)),
      );
    } catch (_) {
      // Loading and map errors are handled by the surrounding screen.
    }
  }

  Future<void> _locateUser() async {
    if (_locating || !_supportsInteractiveMap) return;
    final strings = AppLocalizations.of(context);
    setState(() => _locating = true);
    try {
      final serviceEnabled = await widget.locationService.isServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        _showLocationMessage(
          strings.locationServiceDisabled,
          actionLabel: strings.openLocationSettings,
          onAction: widget.locationService.openLocationSettings,
        );
        return;
      }

      var permission = await widget.locationService.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermissionState.denied ||
          permission == LocationPermissionState.unableToDetermine) {
        permission = await widget.locationService.requestPermission();
        if (!mounted) return;
      }
      if (permission == LocationPermissionState.deniedForever) {
        _showLocationMessage(
          strings.locationPermissionPermanentlyDenied,
          actionLabel: strings.openAppSettings,
          onAction: widget.locationService.openAppSettings,
        );
        return;
      }
      if (!permission.isGranted) {
        _showLocationMessage(strings.locationPermissionDenied);
        return;
      }

      final location = await widget.locationService.getCurrentLocation();
      if (!mounted) return;
      if (!_isValidLocation(location)) {
        _showLocationMessage(strings.locationFailed);
        return;
      }
      var shops = await _shops;
      try {
        final nearby = await widget.repository.loadNearbyMapShops(
          latitude: location.latitude,
          longitude: location.longitude,
        );
        final mappedNearby = nearby.where(_hasValidCoordinates).toList();
        if (mappedNearby.isNotEmpty) shops = mappedNearby;
      } catch (_) {
        // Location remains useful with the already loaded map shops when the
        // distance-sorted refresh is temporarily unavailable.
      }
      final nearestShop = shops.isEmpty
          ? null
          : _sortShopsByDistance(shops, location).first;
      if (!mounted) return;
      setState(() {
        _locationPermissionGranted = true;
        _userLocation = location;
        _shops = Future.value(shops);
        if (nearestShop != null) _selectedShopId = nearestShop.id;
      });
      await _focusUserLocation(location);
    } catch (_) {
      if (mounted) _showLocationMessage(strings.locationFailed);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  bool _isValidLocation(UserLocation location) =>
      location.latitude.isFinite &&
      location.longitude.isFinite &&
      location.latitude >= -90 &&
      location.latitude <= 90 &&
      location.longitude >= -180 &&
      location.longitude <= 180;

  List<ShopSummary> _sortShopsByDistance(
    List<ShopSummary> shops,
    UserLocation location,
  ) {
    final sorted = List<ShopSummary>.of(shops);
    sorted.sort((left, right) {
      final comparison = _distanceToShop(
        left,
        location,
      ).compareTo(_distanceToShop(right, location));
      return comparison != 0 ? comparison : left.id.compareTo(right.id);
    });
    return sorted;
  }

  double _distanceToShop(ShopSummary shop, UserLocation location) {
    final serverDistance = shop.distanceMeters;
    if (serverDistance != null &&
        serverDistance.isFinite &&
        serverDistance >= 0) {
      return serverDistance;
    }
    return GeolocatorLocationService.distanceBetween(
      startLatitude: location.latitude,
      startLongitude: location.longitude,
      endLatitude: shop.latitude!,
      endLongitude: shop.longitude!,
    );
  }

  Future<void> _focusUserLocation(UserLocation location) async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(location.latitude, location.longitude),
            zoom: 15,
          ),
        ),
      );
    } catch (_) {
      // The location remains available even if the platform map is disposed
      // while the camera animation is starting.
    }
  }

  Future<void> _refreshVisibleMapShops() async {
    final controller = _mapController;
    if (controller == null || !_supportsInteractiveMap) return;
    int? requestId;
    try {
      final bounds = await controller.getVisibleRegion();
      if (!mounted) return;
      final signature = [
        bounds.northeast.latitude,
        bounds.southwest.latitude,
        bounds.northeast.longitude,
        bounds.southwest.longitude,
      ].map((value) => value.toStringAsFixed(4)).join(':');
      if (signature == _lastViewportSignature) return;

      requestId = ++_viewportRequestId;
      setState(() => _loadingMapViewport = true);
      final location = _userLocation;
      final loaded = await widget.repository.loadMapShopsInBounds(
        north: bounds.northeast.latitude,
        south: bounds.southwest.latitude,
        east: bounds.northeast.longitude,
        west: bounds.southwest.longitude,
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
      if (!mounted || requestId != _viewportRequestId) return;
      final mapped = loaded.where(_hasValidCoordinates).toList();
      _lastViewportSignature = signature;
      if (mapped.isEmpty) {
        setState(() => _loadingMapViewport = false);
        _showLocationMessage(AppLocalizations.of(context).noShopsInMapArea);
        return;
      }
      final shops = location == null
          ? mapped
          : _sortShopsByDistance(mapped, location);
      setState(() {
        _loadingMapViewport = false;
        _shops = Future.value(shops);
        if (!shops.any((shop) => shop.id == _selectedShopId)) {
          _selectedShopId = shops.first.id;
        }
      });
    } catch (_) {
      if (!mounted || (requestId != null && requestId != _viewportRequestId)) {
        return;
      }
      setState(() => _loadingMapViewport = false);
      _showLocationMessage(AppLocalizations.of(context).mapAreaLoadFailed);
    }
  }

  void _showLocationMessage(
    String message, {
    String? actionLabel,
    Future<bool> Function()? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                onPressed: () {
                  onAction();
                },
              ),
      ),
    );
  }

  void _openShop(ShopSummary shop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopDetailScreen(
          repository: widget.repository,
          shopId: shop.id,
          tradeRepository: widget.tradeRepository,
          reservationRepository: widget.reservationRepository,
          reviewRepository: widget.reviewRepository,
          canInteractReviews: widget.canInteractReviews,
          thirdPartyConfig: widget.thirdPartyConfig,
        ),
      ),
    );
  }

  Widget _defaultMapBuilder(
    BuildContext context,
    List<ShopSummary> shops,
    int selectedShopId,
    ValueChanged<int> onShopSelected,
  ) {
    if (_supportsInteractiveMap) {
      final strings = AppLocalizations.of(context);
      final selected = shops.firstWhere(
        (shop) => shop.id == selectedShopId,
        orElse: () => shops.first,
      );
      return GoogleMap(
        key: const Key('shop-google-map'),
        initialCameraPosition: CameraPosition(
          target: LatLng(selected.latitude!, selected.longitude!),
          zoom: 12,
        ),
        markers: {
          for (final shop in shops)
            Marker(
              markerId: MarkerId('shop-${shop.id}'),
              position: LatLng(shop.latitude!, shop.longitude!),
              infoWindow: InfoWindow(
                title: shop.name,
                snippet: _userLocation == null
                    ? (shop.address.isEmpty ? shop.category : shop.address)
                    : strings.distanceFromYou(
                        _distanceToShop(shop, _userLocation!),
                      ),
              ),
              icon: shop.id == selectedShopId
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    )
                  : BitmapDescriptor.defaultMarker,
              onTap: () => onShopSelected(shop.id),
            ),
        },
        mapToolbarEnabled: false,
        myLocationEnabled: _locationPermissionGranted,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          _mapController = controller;
          final userLocation = _userLocation;
          if (userLocation != null) {
            _focusUserLocation(userLocation);
          }
        },
        onCameraIdle: _refreshVisibleMapShops,
      );
    }
    final uri = widget.thirdPartyConfig.googleMapsStaticUri(
      shops
          .take(20)
          .map(
            (shop) => (latitude: shop.latitude!, longitude: shop.longitude!),
          ),
    );
    return Image.network(
      uri.toString(),
      key: const Key('shop-google-map'),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.map_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.map)),
      body: !widget.thirdPartyConfig.googleMapsEnabled
          ? Center(child: Text(strings.mapsUnavailable))
          : FutureBuilder<List<ShopSummary>>(
              future: _shops,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = localizeBrowseError(strings, snapshot.error!);
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(strings.mapPlacesLoadFailed(error)),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          key: const Key('shop-map-retry'),
                          onPressed: _reloading ? null : _reload,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            _reloading ? strings.processing : strings.retry,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final loadedShops = snapshot.data ?? const [];
                if (loadedShops.isEmpty) {
                  return Center(child: Text(strings.noMapPlaces));
                }
                final userLocation = _userLocation;
                final shops = userLocation == null
                    ? loadedShops
                    : _sortShopsByDistance(loadedShops, userLocation);
                final selectedShopId = _selectedShopId ?? shops.first.id;
                final selected = shops.firstWhere(
                  (shop) => shop.id == selectedShopId,
                  orElse: () => shops.first,
                );
                final builder = widget.mapBuilder ?? _defaultMapBuilder;
                final map = builder(context, shops, selected.id, _selectShop);
                return Column(
                  children: [
                    Expanded(
                      child: _supportsInteractiveMap
                          ? Stack(
                              children: [
                                Positioned.fill(child: map),
                                if (_loadingMapViewport)
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox.square(
                                              dimension: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(strings.updatingMapArea),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  right: 16,
                                  bottom: 16,
                                  child: FloatingActionButton.small(
                                    key: const Key('shop-map-locate-user'),
                                    heroTag: 'shop-map-locate-user',
                                    tooltip: _locating
                                        ? strings.locating
                                        : strings.locateMe,
                                    onPressed: _locating ? null : _locateUser,
                                    child: _locating
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            _userLocation == null
                                                ? Icons.my_location_outlined
                                                : Icons.my_location,
                                          ),
                                  ),
                                ),
                              ],
                            )
                          : map,
                    ),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        key: const Key('shop-map-place-list'),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        scrollDirection: Axis.horizontal,
                        itemCount: shops.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final shop = shops[index];
                          return ChoiceChip(
                            key: Key('shop-map-place-${shop.id}'),
                            selected: shop.id == selected.id,
                            onSelected: (_) => _selectShop(shop.id),
                            avatar: const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                            ),
                            label: Text(
                              userLocation == null
                                  ? shop.name
                                  : '${shop.name} · ${strings.distanceFromYou(_distanceToShop(shop, userLocation))}',
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Card(
                          key: const Key('shop-map-selected-card'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${selected.category} · ★ ${selected.score.toStringAsFixed(1)}',
                                ),
                                if (userLocation != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    strings.distanceFromYou(
                                      _distanceToShop(selected, userLocation),
                                    ),
                                  ),
                                ],
                                if (selected.address.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(selected.address),
                                ],
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    key: const Key('shop-map-view-detail'),
                                    onPressed: () => _openShop(selected),
                                    icon: const Icon(Icons.storefront_outlined),
                                    label: Text(strings.viewShopDetails),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
