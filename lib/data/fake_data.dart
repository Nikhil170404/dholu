import 'package:flutter/material.dart';

/// Fake data for M1. Replaced by real listener + Drift data in M2.
enum ItemAction { reply, pay, track }

class AppInfo {
  const AppInfo(this.pkg, this.name, this.icon, {this.important = false});
  final String pkg;
  final String name;
  final IconData icon;
  final bool important;
}

class UpdateItem {
  const UpdateItem({
    required this.title,
    required this.source,
    required this.action,
    this.urgent = false,
  });
  final String title;
  final String source;
  final ItemAction action;
  final bool urgent;
}

const fakeApps = <AppInfo>[
  AppInfo('com.whatsapp', 'WhatsApp', Icons.chat_bubble_outline_rounded, important: true),
  AppInfo('com.google.android.apps.messaging', 'Messages', Icons.sms_outlined, important: true),
  AppInfo('in.amazon.mShop.android.shopping', 'Amazon', Icons.local_shipping_outlined, important: true),
  AppInfo('net.one97.paytm', 'Paytm', Icons.account_balance_wallet_outlined, important: true),
  AppInfo('com.google.android.gm', 'Gmail', Icons.mail_outline_rounded),
  AppInfo('com.google.android.calendar', 'Calendar', Icons.event_outlined),
  AppInfo('com.instagram.android', 'Instagram', Icons.photo_camera_outlined),
  AppInfo('com.zomato', 'Zomato', Icons.restaurant_outlined),
  AppInfo('com.myntra', 'Myntra', Icons.shopping_bag_outlined),
  AppInfo('com.google.android.youtube', 'YouTube', Icons.play_circle_outline_rounded),
];

const fakeUrgent = UpdateItem(
  title: 'Anil Sir: report 10 baje tak bhejna',
  source: 'WhatsApp',
  action: ItemAction.reply,
  urgent: true,
);

const fakeUpdates = <UpdateItem>[
  UpdateItem(title: 'Bijli bill Rs 1840 kal due', source: 'Paytm', action: ItemAction.pay),
  UpdateItem(title: 'Mummy ke 5 messages', source: 'WhatsApp', action: ItemAction.reply),
  UpdateItem(title: 'Aapka order aaj aayega', source: 'Amazon', action: ItemAction.track),
];

const fakeHiddenCount = 47;

extension ItemActionLabel on ItemAction {
  String get label => switch (this) {
        ItemAction.reply => 'Reply karo',
        ItemAction.pay => 'Pay now',
        ItemAction.track => 'Track karo',
      };
}
