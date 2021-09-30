// ignore_for_file: require_trailing_commas
// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: constant_identifier_names
part of firebase_analytics;

/// Firebase Analytics API.
class FirebaseAnalytics extends FirebasePluginPlatform {
  FirebaseAnalytics._({required this.app})
      : super(app.name, 'plugins.flutter.io/firebase_crashlytics');

  static Map<String, FirebaseAnalytics> _firebaseAnalyticsInstances = {};

  // Cached and lazily loaded instance of [FirebaseAnalyticsPlatform] to avoid
  // creating a [MethodChannelFirebaseAnalytics] when not needed or creating an
  // instance with the default app before a user specifies an app.
  FirebaseAnalyticsPlatform? _delegatePackingProperty;

  FirebaseAnalyticsPlatform get _delegate {
    return _delegatePackingProperty ??=
        FirebaseAnalyticsPlatform.instanceFor(app: app);
  }

  //  Analytics does not yet support multiple Firebase Apps. Default app only.
  /// Returns an instance using a specified [FirebaseApp].
  factory FirebaseAnalytics._instanceFor({required FirebaseApp app}) {
    return _firebaseAnalyticsInstances.putIfAbsent(app.name, () {
      return FirebaseAnalytics._(app: app);
    });
  }

  /// The [FirebaseApp] for this current [FirebaseAnalytics] instance.
  FirebaseApp app;

  /// Returns an instance using the default [FirebaseApp].
  static FirebaseAnalytics get instance {
    FirebaseApp defaultAppInstance = Firebase.app();
    return FirebaseAnalytics._instanceFor(app: defaultAppInstance);
  }

  /// Namespace for analytics API available on Android only.
  ///
  /// The value of this field is `null` on non-Android platforms. If you are
  /// writing cross-platform code, consider using null-aware operator when
  /// accessing it.
  ///
  /// Example:
  ///
  ///     FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  ///     analytics.android?.setSessionTimeoutDuration(true);
  final FirebaseAnalyticsAndroid? android =
      defaultTargetPlatform == TargetPlatform.android && !kIsWeb
          ? FirebaseAnalyticsAndroid()
          : null;

  /// Logs a custom Flutter Analytics event with the given [name] and event [parameters].
  Future<void> logEvent(
      {required String name, Map<String, Object?>? parameters}) async {
    if (_reservedEventNames.contains(name)) {
      throw ArgumentError.value(
          name, 'name', 'Event name is reserved and cannot be used');
    }

    const String kReservedPrefix = 'firebase_';

    if (name.startsWith(kReservedPrefix)) {
      throw ArgumentError.value(name, 'name',
          'Prefix "$kReservedPrefix" is reserved and cannot be used.');
    }

    await _delegate.logEvent(name: name, parameters: parameters);
  }

  // Sets the applicable end user consent state. 'default' value for 'adStorage' & 'analyticsStorage' is 'granted'
  Future<void> setConsent({
    ConsentStatus? adStorage,
    ConsentStatus? analyticsStorage,
  }) async {
    await _delegate.setConsent(
      adStorage:adStorage,
      analyticsStorage:analyticsStorage,
    );
  }

  // Adds parameters that will be set on every event logged from the SDK, including automatic ones.
  Future<void> setDefaultEventParameters(
      Map<String, Object> defaultParameters) async {
    await _delegate.setDefaultEventParameters(defaultParameters);
  }

  /// Sets whether analytics collection is enabled for this app on this device.
  ///
  /// This setting is persisted across app sessions. By default it is enabled.
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    await _delegate.setAnalyticsCollectionEnabled(enabled);
  }

  /// Sets the user ID property.
  ///
  /// Setting a null [id] removes the user id.
  ///
  /// This feature must be used in accordance with [Google's Privacy Policy][1].
  ///
  /// [1]: https://www.google.com/policies/privacy/
  Future<void> setUserId(String? id) async {
    await _delegate.setUserId(id);
  }

  /// Sets the current [screenName], which specifies the current visual context
  /// in your app.
  ///
  /// This helps identify the areas in your app where users spend their time
  /// and how they interact with your app.
  ///
  /// The class name can optionally be overridden by the [screenClassOverride]
  /// parameter.
  ///
  /// The [screenName] and [screenClassOverride] remain in effect until the
  /// current `Activity` (in Android) or `UIViewController` (in iOS) changes or
  /// a new call to [setCurrentScreen] is made.
  ///
  /// Setting a null [screenName] clears the current screen name.
  ///
  /// See also:
  ///
  ///  * https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.html#setCurrentScreen(android.app.Activity, java.lang.String, java.lang.String)
  ///  * https://firebase.google.com/docs/reference/ios/firebaseanalytics/api/reference/Classes/FIRAnalytics#setscreennamescreenclass
  Future<void> setCurrentScreen(
      {required String? screenName,
      String screenClassOverride = 'Flutter'}) async {
    await _delegate.setCurrentScreen(
      screenName: screenName,
      screenClassOverride: screenClassOverride,
    );
  }

  static final RegExp _nonAlphaNumeric = RegExp('[^a-zA-Z0-9_]');
  static final RegExp _alpha = RegExp('[a-zA-Z]');

  /// Sets a user property to a given value.
  ///
  /// Up to 25 user property names are supported. Once set, user property
  /// values persist throughout the app lifecycle and across sessions.
  ///
  /// [name] is the name of the user property to set. Should contain 1 to 24
  /// alphanumeric characters or underscores and must start with an alphabetic
  /// character. The "firebase_" prefix is reserved and should not be used for
  /// user property names.
  ///
  /// Setting a null [value] removes the user property.
  Future<void> setUserProperty(
      {required String name, required String? value}) async {
    if (name.isEmpty ||
        name.length > 24 ||
        name.indexOf(_alpha) != 0 ||
        name.contains(_nonAlphaNumeric)) {
      throw ArgumentError.value(
          name, 'name', 'must contain 1 to 24 alphanumeric characters.');
    }

    if (name.startsWith('firebase_')) {
      throw ArgumentError.value(name, 'name', '"firebase_" prefix is reserved');
    }

    await _delegate.setUserProperty(name: name, value: value);
  }

  /// Clears all analytics data for this app from the device and resets the app instance id.
  Future<void> resetAnalyticsData() async {
    await _delegate.resetAnalyticsData();
  }

  /// Logs the standard `add_payment_info` event.
  ///
  /// This event signifies that a user has submitted their payment information
  /// to your app.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#ADD_PAYMENT_INFO
  Future<void> logAddPaymentInfo({
    String? coupon,
    String? currency,
    String? paymentType,
    double? value,
    List<Item>? items,
  }) {
    return logEvent(name: 'add_payment_info', parameters: {
      _COUPON: coupon,
      _CURRENCY: currency,
      _PAYMENT_TYPE: paymentType,
      _VALUE: value,
      _ITEMS: items,
    });
  }

  /// Logs the standard `add_shipping_info` event.
  ///
  /// This event signifies that a user has submitted their shipping information
  /// to your app.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#ADD_PAYMENT_INFO
  Future<void> logAddShippingInfo({
    String? coupon,
    String? currency,
    double? value,
    String? shippingTier,
    List<Item>? items,
  }) {
    return logEvent(name: 'add_shipping_info', parameters: {
      _COUPON: coupon,
      _CURRENCY: currency,
      _SHIPPING_TIER: shippingTier,
      _VALUE: value,
      _ITEMS: items,
    });
  }

  /// Logs the standard `add_to_cart` event.
  ///
  /// This event signifies that an item was added to a cart for purchase. Add
  /// this event to a funnel with [logEcommercePurchase] to gauge the
  /// effectiveness of your checkout process. Note: If you supply the
  /// [value] parameter, you must also supply the [currency] parameter so that
  /// revenue metrics can be computed accurately.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#ADD_TO_CART
  Future<void> logAddToCart({
    List<Item>? items,
    double? value,
    String? currency,
  }) {
    _requireValueAndCurrencyTogether(value, currency);

    return logEvent(
      name: 'add_to_cart',
      parameters: filterOutNulls(<String, Object?>{
        _ITEMS: items,
        _VALUE: value,
        _CURRENCY: currency,
      }),
    );
  }

  /// Logs the standard `add_to_wishlist` event.
  ///
  /// This event signifies that an item was added to a wishlist. Use this event
  /// to identify popular gift items in your app. Note: If you supply the
  /// [value] parameter, you must also supply the [currency] parameter so that
  /// revenue metrics can be computed accurately.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#ADD_TO_WISHLIST
  Future<void> logAddToWishlist({
    List<Item>? items,
    double? value,
    String? currency,
  }) {
    _requireValueAndCurrencyTogether(value, currency);

    return logEvent(
      name: 'add_to_wishlist',
      parameters: filterOutNulls(<String, Object?>{
        _ITEMS: items,
        _VALUE: value,
        _CURRENCY: currency,
      }),
    );
  }

  /// Logs the standard `add_to_wishlist` event.
  ///
  /// This event signifies that an item was added to a wishlist. Use this event
  /// to identify popular gift items in your app. Note: If you supply the
  /// [value] parameter, you must also supply the [currency] parameter so that
  /// revenue metrics can be computed accurately.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#ADD_TO_WISHLIST
  Future<void> logAdImpression({
    String? adPlatform,
    String? adSource,
    String? adFormat,
    String? adUnitName,
    double? value,
    String? currency,
  }) {
    _requireValueAndCurrencyTogether(value, currency);

    return logEvent(
      name: 'ad_impression',
      parameters: filterOutNulls(<String, Object?>{
        _AD_PLATFORM: adPlatform,
        _AD_SOURCE: adSource,
        _AD_FORMAT: adFormat,
        _AD_UNIT_NAME: adUnitName,
        _VALUE: value,
        _CURRENCY: currency,
      }),
    );
  }

  /// Logs the standard `app_open` event.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#APP_OPEN
  Future<void> logAppOpen() {
    return logEvent(name: 'app_open');
  }

  /// Logs the standard `begin_checkout` event.
  ///
  /// This event signifies that a user has begun the process of checking out.
  /// Add this event to a funnel with your [logEcommercePurchase] event to
  /// gauge the effectiveness of your checkout process. Note: If you supply the
  /// [value] parameter, you must also supply the [currency] parameter so that
  /// revenue metrics can be computed accurately.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#BEGIN_CHECKOUT
  Future<void> logBeginCheckout({
    double? value,
    String? currency,
    List<Item>? items,
    String? coupon,
  }) {
    _requireValueAndCurrencyTogether(value, currency);

    return logEvent(
      name: 'begin_checkout',
      parameters: filterOutNulls(<String, Object?>{
        _VALUE: value,
        _CURRENCY: currency,
        _ITEMS: items,
        _COUPON: coupon,
      }),
    );
  }

  /// Logs the standard `campaign_details` event.
  ///
  /// Log this event to supply the referral details of a re-engagement campaign.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#CAMPAIGN_DETAILS
  Future<void> logCampaignDetails({
    required String source,
    required String medium,
    required String campaign,
    String? term,
    String? content,
    String? aclid,
    String? cp1,
  }) {
    return logEvent(
      name: 'campaign_details',
      parameters: filterOutNulls(<String, String?>{
        _SOURCE: source,
        _MEDIUM: medium,
        _CAMPAIGN: campaign,
        _TERM: term,
        _CONTENT: content,
        _ACLID: aclid,
        _CP1: cp1,
      }),
    );
  }

  /// Logs the standard `earn_virtual_currency` event.
  ///
  /// This event tracks the awarding of virtual currency in your app. Log this
  /// along with [logSpendVirtualCurrency] to better understand your virtual
  /// economy.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#EARN_VIRTUAL_CURRENCY
  Future<void> logEarnVirtualCurrency({
    required String virtualCurrencyName,
    required num value,
  }) {
    return logEvent(
      name: 'earn_virtual_currency',
      parameters: filterOutNulls(<String, Object?>{
        _VIRTUAL_CURRENCY_NAME: virtualCurrencyName,
        _VALUE: value,
      }),
    );
  }

  /// Logs the standard `generate_lead` event.
  ///
  /// Log this event when a lead has been generated in the app to understand
  /// the efficacy of your install and re-engagement campaigns. Note: If you
  /// supply the [value] parameter, you must also supply the [currency]
  /// parameter so that revenue metrics can be computed accurately.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#GENERATE_LEAD
  Future<void> logGenerateLead({
    String? currency,
    double? value,
  }) {
    _requireValueAndCurrencyTogether(value, currency);

    return logEvent(
      name: 'generate_lead',
      parameters: filterOutNulls(<String, Object?>{
        _CURRENCY: currency,
        _VALUE: value,
      }),
    );
  }

  /// Logs the standard `join_group` event.
  ///
  /// Log this event when a user joins a group such as a guild, team or family.
  /// Use this event to analyze how popular certain groups or social features
  /// are in your app.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#JOIN_GROUP
  Future<void> logJoinGroup({
    required String groupId,
  }) {
    return logEvent(
      name: 'join_group',
      parameters: filterOutNulls(<String, Object?>{
        _GROUP_ID: groupId,
      }),
    );
  }

  /// Logs the standard `level_up` event.
  ///
  /// This event signifies that a player has leveled up in your gaming app. It
  /// can help you gauge the level distribution of your userbase and help you
  /// identify certain levels that are difficult to pass.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#LEVEL_UP
  Future<void> logLevelUp({
    required int level,
    String? character,
  }) {
    return logEvent(
      name: 'level_up',
      parameters: filterOutNulls(<String, Object?>{
        _LEVEL: level,
        _CHARACTER: character,
      }),
    );
  }

  /// Logs the standard `level_start` event.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#LEVEL_START
  Future<void> logLevelStart({
    required String levelName,
  }) {
    return logEvent(
      name: 'level_start',
      parameters: filterOutNulls(<String, Object?>{
        _LEVEL_NAME: levelName,
      }),
    );
  }

  /// Logs the standard `level_end` event.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#LEVEL_END
  Future<void> logLevelEnd({
    required String levelName,
    int? success,
  }) {
    return logEvent(
      name: 'level_end',
      parameters: filterOutNulls(<String, Object?>{
        _LEVEL_NAME: levelName,
        _SUCCESS: success,
      }),
    );
  }

  /// Logs the standard `login` event.
  ///
  /// Apps with a login feature can report this event to signify that a user
  /// has logged in.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#LOGIN
  Future<void> logLogin({String? loginMethod}) {
    return logEvent(
      name: 'login',
      parameters: filterOutNulls(<String, Object?>{
        _METHOD: loginMethod,
      }),
    );
  }

  /// Logs the standard `post_score` event.
  ///
  /// Log this event when the user posts a score in your gaming app. This event
  /// can help you understand how users are actually performing in your game
  /// and it can help you correlate high scores with certain audiences or
  /// behaviors.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#POST_SCORE
  Future<void> logPostScore({
    required int score,
    int? level,
    String? character,
  }) {
    return logEvent(
      name: 'post_score',
      parameters: filterOutNulls(<String, Object?>{
        _SCORE: score,
        _LEVEL: level,
        _CHARACTER: character,
      }),
    );
  }

  /// Logs the standard `purchase` event.
  ///
  /// This event signifies that an item(s) was purchased by a user.
  /// Note: This is different from the in-app purchase event,
  /// which is reported automatically for Google Play-based apps.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#PURCHASE
  Future<void> logPurchase({
    String? currency,
    String? coupon,
    double? value,
    List<Item>? items,
    double? tax,
    double? shipping,
    String? transactionId,
    String? affiliation,
  }) {
    _requireValueAndCurrencyTogether(value, currency);

    return logEvent(
      name: 'purchase',
      parameters: filterOutNulls(<String, Object?>{
        _CURRENCY: currency,
        _COUPON: coupon,
        _VALUE: value,
        _ITEMS: items,
        _TAX: tax,
        _SHIPPING: shipping,
        _TRANSACTION_ID: transactionId,
        _AFFILIATION: affiliation,
      }),
    );
  }

  /// Logs the standard `remove_from_cart` event.
  ///
  /// This event signifies that an item(s) was removed from a cart.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#REMOVE_FROM_CART
  Future<void> logRemoveFromCart({
    String? currency,
    double? value,
    List<Item>? items,
  }) {
    _requireValueAndCurrencyTogether(value, currency);

    return logEvent(
      name: 'remove_from_cart',
      parameters: filterOutNulls(<String, Object?>{
        _CURRENCY: currency,
        _VALUE: value,
        _ITEMS: items,
      }),
    );
  }

  /// Logs the standard `screen_view` event.
  ///
  /// This event signifies a screen view. Use this when a screen transition occurs.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#SCREEN_VIEW
  Future<void> logScreenView({
    String? screenClass,
    String? screenName,
  }) {
    return logEvent(
      name: 'screen_view',
      parameters: filterOutNulls(<String, Object?>{
        _SCREEN_CLASS: screenClass,
        _SCREEN_NAME: screenName,
      }),
    );
  }

  /// Logs the standard `select_item` event.
  ///
  /// This event signifies that an item was selected by a user from a list.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#SELECT_ITEM
  Future<void> logSelectItem({
    String? itemListId,
    String? itemListName,
    List<Item>? items,
  }) {
    return logEvent(
      name: 'select_item',
      parameters: filterOutNulls(<String, Object?>{
        _ITEM_LIST_ID: itemListId,
        _ITEM_LIST_NAME: itemListName,
        _ITEMS: items,
      }),
    );
  }

  /// Logs the standard `select_promotion` event.
  ///
  /// This event signifies that a user has selected a promotion offer.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#SELECT_PROMOTION
  Future<void> logSelectPromotion({
    String? creativeName,
    String? creativeSlot,
    List<Item>? items,
    String? locationId,
    String? promotionId,
    String? promotionName,
  }) {
    return logEvent(
      name: 'select_promotion',
      parameters: filterOutNulls(<String, Object?>{
        _CREATIVE_NAME: creativeName,
        _CREATIVE_SLOT: creativeSlot,
        _ITEMS: items,
        _LOCATION_ID: locationId,
        _PROMOTION_ID: promotionId,
        _PROMOTION_NAME: promotionName,
      }),
    );
  }

  /// Logs the standard `view_cart` event.
  ///
  /// This event signifies that a user has viewed their cart. Use this to analyze your purchase funnel.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#VIEW_CART
  Future<void> logViewCart({
    String? currency,
    double? value,
    List<Item>? items,
  }) {
    return logEvent(
      name: 'view_cart',
      parameters: filterOutNulls(<String, Object?>{
        _CURRENCY: currency,
        _VALUE: value,
        _ITEMS: items,
      }),
    );
  }

  /// Logs the standard `search` event.
  ///
  /// Apps that support search features can use this event to contextualize
  /// search operations by supplying the appropriate, corresponding parameters.
  /// This event can help you identify the most popular content in your app.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#SEARCH
  Future<void> logSearch({
    required String searchTerm,
    int? numberOfNights,
    int? numberOfRooms,
    int? numberOfPassengers,
    String? origin,
    String? destination,
    String? startDate,
    String? endDate,
    String? travelClass,
  }) {
    return logEvent(
      name: 'search',
      parameters: filterOutNulls(<String, Object?>{
        _SEARCH_TERM: searchTerm,
        _NUMBER_OF_NIGHTS: numberOfNights,
        _NUMBER_OF_ROOMS: numberOfRooms,
        _NUMBER_OF_PASSENGERS: numberOfPassengers,
        _ORIGIN: origin,
        _DESTINATION: destination,
        _START_DATE: startDate,
        _END_DATE: endDate,
        _TRAVEL_CLASS: travelClass,
      }),
    );
  }

  /// Logs the standard `select_content` event.
  ///
  /// This general purpose event signifies that a user has selected some
  /// content of a certain type in an app. The content can be any object in
  /// your app. This event can help you identify popular content and categories
  /// of content in your app.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#SELECT_CONTENT
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) {
    return logEvent(
      name: 'select_content',
      parameters: filterOutNulls(<String, Object?>{
        _CONTENT_TYPE: contentType,
        _ITEM_ID: itemId,
      }),
    );
  }

  /// Logs the standard `share` event.
  ///
  /// Apps with social features can log the Share event to identify the most
  /// viral content.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#SHARE
  Future<void> logShare({
    required String contentType,
    required String itemId,
    required String method,
  }) {
    return logEvent(
      name: 'share',
      parameters: filterOutNulls(<String, Object?>{
        _CONTENT_TYPE: contentType,
        _ITEM_ID: itemId,
        _METHOD: method,
      }),
    );
  }

  /// Logs the standard `sign_up` event.
  ///
  /// This event indicates that a user has signed up for an account in your
  /// app. The parameter signifies the method by which the user signed up. Use
  /// this event to understand the different behaviors between logged in and
  /// logged out users.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#SIGN_UP
  Future<void> logSignUp({
    required String signUpMethod,
  }) {
    return logEvent(
      name: 'sign_up',
      parameters: filterOutNulls(<String, Object?>{
        _METHOD: signUpMethod,
      }),
    );
  }

  /// Logs the standard `spend_virtual_currency` event.
  ///
  /// This event tracks the sale of virtual goods in your app and can help you
  /// identify which virtual goods are the most popular objects of purchase.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#SPEND_VIRTUAL_CURRENCY
  Future<void> logSpendVirtualCurrency({
    required String itemName,
    required String virtualCurrencyName,
    required num value,
  }) {
    return logEvent(
      name: 'spend_virtual_currency',
      parameters: filterOutNulls(<String, Object?>{
        _ITEM_NAME: itemName,
        _VIRTUAL_CURRENCY_NAME: virtualCurrencyName,
        _VALUE: value,
      }),
    );
  }

  /// Logs the standard `tutorial_begin` event.
  ///
  /// This event signifies the start of the on-boarding process in your app.
  /// Use this in a funnel with [logTutorialComplete] to understand how many
  /// users complete this process and move on to the full app experience.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#TUTORIAL_BEGIN
  Future<void> logTutorialBegin() {
    return logEvent(name: 'tutorial_begin');
  }

  /// Logs the standard `tutorial_complete` event.
  ///
  /// Use this event to signify the user's completion of your app's on-boarding
  /// process. Add this to a funnel with [logTutorialBegin] to gauge the
  /// completion rate of your on-boarding process.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#TUTORIAL_COMPLETE
  Future<void> logTutorialComplete() {
    return logEvent(name: 'tutorial_complete');
  }

  /// Logs the standard `unlock_achievement` event with a given achievement
  /// [id].
  ///
  /// Log this event when the user has unlocked an achievement in your game.
  /// Since achievements generally represent the breadth of a gaming
  /// experience, this event can help you understand how many users are
  /// experiencing all that your game has to offer.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#UNLOCK_ACHIEVEMENT
  Future<void> logUnlockAchievement({
    required String id,
  }) {
    return logEvent(
      name: 'unlock_achievement',
      parameters: filterOutNulls(<String, Object?>{
        _ACHIEVEMENT_ID: id,
      }),
    );
  }

  /// Logs the standard `view_item` event.
  ///
  /// This event signifies that some content was shown to the user. This
  /// content may be a product, a webpage or just a simple image or text. Use
  /// the appropriate parameters to contextualize the event. Use this event to
  /// discover the most popular items viewed in your app. Note: If you supply
  /// the [value] parameter, you must also supply the [currency] parameter so
  /// that revenue metrics can be computed accurately.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#VIEW_ITEM
  Future<void> logViewItem({
    String? currency,
    double? value,
    List<Item>? items,
  }) {
    _requireValueAndCurrencyTogether(value, currency);

    return logEvent(
      name: 'view_item',
      parameters: filterOutNulls(<String, Object?>{
        _CURRENCY: currency,
        _VALUE: value,
        _ITEMS: items,
      }),
    );
  }

  /// Logs the standard `view_item_list` event.
  ///
  /// Log this event when the user has been presented with a list of items of a
  /// certain category.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#VIEW_ITEM_LIST
  Future<void> logViewItemList({
    List<Item>? items,
    String? itemListId,
    String? itemListName,
  }) {
    return logEvent(
      name: 'view_item_list',
      parameters: filterOutNulls(<String, Object?>{
        _ITEMS: items,
        _ITEM_LIST_ID: itemListId,
        _ITEM_LIST_NAME: itemListName,
      }),
    );
  }

  /// Logs the standard `view_promotion` event.
  ///
  /// This event signifies that a promotion was shown to a user.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#VIEW_PROMOTION
  Future<void> logViewPromotion({
    String? creativeName,
    String? creativeSlot,
    List<Item>? items,
    String? locationId,
    String? promotionId,
    String? promotionName,
  }) {
    return logEvent(
      name: 'view_promotion',
      parameters: filterOutNulls(<String, Object?>{
        _CREATIVE_NAME: creativeName,
        _CREATIVE_SLOT: creativeSlot,
        _ITEMS: items,
        _LOCATION_ID: locationId,
        _PROMOTION_ID: promotionId,
        _PROMOTION_NAME: promotionName,
      }),
    );
  }

  /// Logs the standard `view_search_results` event.
  ///
  /// Log this event when the user has been presented with the results of a
  /// search.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#VIEW_SEARCH_RESULTS
  Future<void> logViewSearchResults({
    required String searchTerm,
  }) {
    return logEvent(
      name: 'view_search_results',
      parameters: filterOutNulls(<String, Object?>{
        _SEARCH_TERM: searchTerm,
      }),
    );
  }

  /// Logs the standard `refund` event.
  ///
  /// This event signifies that a refund was issued.
  ///
  /// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html#REFUND
  Future<void> logRefund({
    String? currency,
    String? coupon,
    double? value,
    double? tax,
    double? shipping,
    String? transactionId,
    String? affiliation,
    List<Item>? items,
  }) {
    return logEvent(
      name: 'refund',
      parameters: filterOutNulls(<String, Object?>{
        _CURRENCY: currency,
        _COUPON: coupon,
        _VALUE: value,
        _TAX: tax,
        _SHIPPING: shipping,
        _TRANSACTION_ID: transactionId,
        _AFFILIATION: affiliation,
        _ITEMS: items,
      }),
    );
  }
}

/// Android-specific analytics API.
class FirebaseAnalyticsAndroid {
  final _delegate = FirebaseAnalyticsPlatform.instance;

  /// Sets the duration of inactivity that terminates the current session.
  ///
  /// The default value is 1800000 (30 minutes).
  Future<void> setSessionTimeoutDuration(int milliseconds) async {
    await _delegate.setSessionTimeoutDuration(milliseconds);
  }
}

/// Creates a new map containing all of the key/value pairs from [parameters]
/// except those whose value is `null`.
@visibleForTesting
Map<String, Object> filterOutNulls(Map<String, Object?> parameters) {
  final Map<String, Object> filtered = <String, Object>{};
  parameters.forEach((String key, Object? value) {
    if (value != null) {
      filtered[key] = value;
    }
  });
  return filtered;
}

@visibleForTesting
const String valueAndCurrencyMustBeTogetherError = 'If you supply the "value" '
    'parameter, you must also supply the "currency" parameter.';

void _requireValueAndCurrencyTogether(double? value, String? currency) {
  if (value != null && currency == null) {
    throw ArgumentError(valueAndCurrencyMustBeTogetherError);
  }
}

/// Reserved event names that cannot be used.
///
/// See: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event.html
const List<String> _reservedEventNames = <String>[
  'ad_activeview',
  'ad_click',
  'ad_exposure',
  'ad_query',
  'ad_reward',
  'adunit_exposure',
  'app_background',
  'app_clear_data',
  'app_exception',
  'app_remove',
  'app_store_refund',
  'app_store_subscription_cancel',
  'app_store_subscription_convert',
  'app_store_subscription_renew',
  'app_uninstall',
  'app_update',
  'app_upgrade',
  'dynamic_link_app_open',
  'dynamic_link_app_update',
  'dynamic_link_first_open',
  'error',
  'first_open',
  'first_visit',
  'in_app_purchase',
  'notification_dismiss',
  'notification_foreground',
  'notification_open',
  'notification_receive',
  'os_update',
  'session_start',
  'session_start_with_rollout',
  'user_engagement',
];

// The following constants are defined in:
//
// https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Param.html

/// Game achievement ID.
const String _ACHIEVEMENT_ID = 'achievement_id';

/// `CAMPAIGN_DETAILS` click ID.
const String _ACLID = 'aclid';

/// `CAMPAIGN_DETAILS` name; used for keyword analysis to identify a specific
/// product promotion or strategic campaign.
const String _CAMPAIGN = 'campaign';

/// Character used in game.
const String _CHARACTER = 'character';

/// `CAMPAIGN_DETAILS` content; used for A/B testing and content-targeted ads to
/// differentiate ads or links that point to the same URL.
const String _CONTENT = 'content';

/// Type of content selected.
const String _CONTENT_TYPE = 'content_type';

/// Coupon code for a purchasable item.
const String _COUPON = 'coupon';

/// `CAMPAIGN_DETAILS` custom parameter.
const String _CP1 = 'cp1';

/// Purchase currency in 3 letter ISO_4217 format.
const String _CURRENCY = 'currency';

/// Flight or Travel destination.
const String _DESTINATION = 'destination';

/// The arrival date, check-out date, or rental end date for the item.
const String _END_DATE = 'end_date';

/// Indicates that the associated event should either
/// extend the current session or start a new session
/// if no session was active when the event was logged.
// const String _EXTENDED_SESSION = 'extend_session';

/// Flight number for travel events.
const String _FLIGHT_NUMBER = 'flight_number';

/// Group/clan/guild id.
const String _GROUP_ID = 'group_id';

/// Item category.
const String _ITEM_CATEGORY = 'item_category';

const String _ITEMS = 'items';

/// Item ID.
const String _ITEM_ID = 'item_id';

/// The Google Place ID that corresponds to the associated item.
const String _ITEM_LOCATION_ID = 'item_location_id';

/// The location associated with the event.
const String _LOCATION_ID = 'location_id';

/// The ID of the list in which the item was presented to the user
const String _ITEM_LIST_ID = 'item_list_id';

/// The ID of the list in which the item was presented to the user
const String _ITEM_LIST_NAME = 'item_list_name';

/// Item Brand.
// const String _ITEM_BRAND = 'item_brand';

/// Item Variant.
// const String _ITEM_VARIANT = 'item_variant';

/// The list in which the item was presented to the user.
// const String _ITEM_LIST = 'item_list';

/// The checkout step (1..N).
const String _CHECKOUT_STEP = 'checkout_step';

/// Some option on a step in an ecommerce flow.
const String _CHECKOUT_OPTION = 'checkout_option';

/// The name of a creative used in a promotional spot.
const String _CREATIVE_NAME = 'creative_name';

/// The name of a creative slot.
const String _CREATIVE_SLOT = 'creative_slot';

/// The store or affiliation from which this transaction occurred.
const String _AFFILIATION = 'affiliation';

/// The index of an item in a list.
// const String _INDEX = 'index';

/// Item name (String).
const String _ITEM_NAME = 'item_name';

/// Level in game (long).
const String _LEVEL = 'level';

/// The name of a level in a game (String).
const String _LEVEL_NAME = 'level_name';

/// The result of an operation (long).
const String _SUCCESS = 'success';

/// Location.
const String _LOCATION = 'location';

/// `CAMPAIGN_DETAILS` medium; used to identify a medium such as email or
/// cost-per-click (cpc).
const String _MEDIUM = 'medium';

/// Number of nights staying at hotel (long).
const String _NUMBER_OF_NIGHTS = 'number_of_nights';

/// Number of passengers traveling (long).
const String _NUMBER_OF_PASSENGERS = 'number_of_passengers';

const String _PAYMENT_TYPE = 'payment_type';

/// Number of rooms for travel events (long).
const String _NUMBER_OF_ROOMS = 'number_of_rooms';

/// Flight or Travel origin.
const String _ORIGIN = 'origin';

/// Purchase price (double).
const String _PRICE = 'price';

/// Purchase quantity (long).
const String _QUANTITY = 'quantity';

/// Score in game (long).
const String _SCORE = 'score';

/// The search string/keywords used.
const String _SEARCH_TERM = 'search_term';

/// Shipping cost (double).
const String _SHIPPING = 'shipping';

/// Shipping tier (string).
const String _SHIPPING_TIER = 'shipping_tier';

/// A particular approach used in an operation; for example, "facebook" or
/// "email" in the context of a sign_up or login event.
const String _METHOD = 'method';

/// `CAMPAIGN_DETAILS` source; used to identify a search engine, newsletter, or
/// other source.
const String _SOURCE = 'source';

/// The departure date, check-in date, or rental start date for the item.
const String _START_DATE = 'start_date';

/// Tax amount (double).
const String _TAX = 'tax';

/// `CAMPAIGN_DETAILS` term; used with paid search to supply the keywords for
/// ads.
const String _TERM = 'term';

/// A single ID for a ecommerce group transaction.
const String _TRANSACTION_ID = 'transaction_id';

/// Travel class.
const String _TRAVEL_CLASS = 'travel_class';

/// A context-specific numeric value which is accumulated automatically for
/// each event type.
const String _VALUE = 'value';

/// Name of virtual currency type.
const String _VIRTUAL_CURRENCY_NAME = 'virtual_currency_name';

/// Name of ad platform.
const String _AD_PLATFORM = 'ad_platform';

/// Name of ad source.
const String _AD_SOURCE = 'ad_source';

/// Name of ad format.
const String _AD_FORMAT = 'ad_format';

/// Name of ad unit name.
const String _AD_UNIT_NAME = 'ad_unit_name';

/// Name of screen class
const String _SCREEN_CLASS = 'screen_class';

/// Name of screen name
const String _SCREEN_NAME = 'screen_name';

/// The ID of a product promotion
const String _PROMOTION_ID = 'promotion_id';

/// The name of a product promotion
const String _PROMOTION_NAME = 'promotion_name';
