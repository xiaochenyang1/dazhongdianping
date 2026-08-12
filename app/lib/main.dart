import 'package:dazhongdianping_app/app.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = ThirdPartyConfig();
  if (config.stripeEnabled) {
    Stripe.publishableKey = config.stripePublishableKey;
    await Stripe.instance.applySettings();
  }
  runApp(const DazhongDianpingApp());
}
