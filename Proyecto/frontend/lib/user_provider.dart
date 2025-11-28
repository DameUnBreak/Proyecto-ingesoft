import 'package:flutter/material.dart';

// Global User Notifier
// Stores the user's name. If null or empty, we use the email or default.
final ValueNotifier<String?> userNotifier = ValueNotifier(null);
