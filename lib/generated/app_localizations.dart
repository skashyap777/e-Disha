import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you'll need to edit this
/// file.
///
/// First, open your project's ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project's Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the supportedLocales parameter
/// of your application's MaterialApp.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'e-Disha'**
  String get appTitle;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Mobile number input label
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// Password input label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Mobile number input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get enterMobileNumber;

  /// Password input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Terms and conditions link text
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Welcome message on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// Sign in subtitle message
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to e-Disha'**
  String get signInToContinue;

  /// Mobile number validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your mobile number'**
  String get pleaseEnterMobileNumber;

  /// Mobile number length validation error
  ///
  /// In en, this message translates to:
  /// **'Mobile number must be 10 digits'**
  String get mobileNumberMustBe10Digits;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6Characters;

  /// Loading message during login
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// Login failure dialog title
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailed;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Hindi language option
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get hindi;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Appearance settings section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Push notifications setting
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// Tracking settings section
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// Location tracking setting
  ///
  /// In en, this message translates to:
  /// **'Location Tracking'**
  String get locationTracking;

  /// Auto refresh setting
  ///
  /// In en, this message translates to:
  /// **'Auto Refresh'**
  String get autoRefresh;

  /// Refresh interval setting
  ///
  /// In en, this message translates to:
  /// **'Refresh Interval'**
  String get refreshInterval;

  /// Map settings section
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// Default zoom level setting
  ///
  /// In en, this message translates to:
  /// **'Default Zoom Level'**
  String get defaultZoomLevel;

  /// App info section
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfo;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Company name label
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Footer text before terms and privacy links
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get byContinuingYouAgree;

  /// Conjunction word between terms and privacy policy
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// Validation error for mobile number minimum length
  ///
  /// In en, this message translates to:
  /// **'Mobile number must be at least 10 digits'**
  String get mobileNumberMustBeAtLeast10Digits;

  /// Validation error for mobile number maximum length
  ///
  /// In en, this message translates to:
  /// **'Mobile number must be at most 15 digits'**
  String get mobileNumberMustBeAtMost15Digits;

  /// Validation error for invalid Indian mobile number format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Indian mobile number'**
  String get pleaseEnterValidIndianMobileNumber;

  /// Title for Terms and Conditions screen
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditionsTitle;

  /// Title for Privacy Policy screen
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// Welcome message in Terms and Conditions
  ///
  /// In en, this message translates to:
  /// **'Welcome to e-Disha. These terms and conditions outline the rules and regulations for the use of our application.'**
  String get welcomeToApp;

  /// Section title for acceptance of terms
  ///
  /// In en, this message translates to:
  /// **'Acceptance of Terms'**
  String get acceptanceOfTerms;

  /// Section title for use of application
  ///
  /// In en, this message translates to:
  /// **'Use of Application'**
  String get useOfApplication;

  /// Section title for user responsibilities
  ///
  /// In en, this message translates to:
  /// **'User Responsibilities'**
  String get userResponsibilities;

  /// Section title for privacy and data protection
  ///
  /// In en, this message translates to:
  /// **'Privacy and Data Protection'**
  String get privacyAndDataProtection;

  /// Contact us section title
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// Last updated text
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// Terms introduction text
  ///
  /// In en, this message translates to:
  /// **'Please read these terms and conditions carefully before using the e-Disha application.'**
  String get pleaseReadTermsCarefully;

  /// Section 1 title
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get acceptanceOfTermsTitle;

  /// Section 1 content
  ///
  /// In en, this message translates to:
  /// **'By accessing and using the e-Disha application ("App"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.'**
  String get acceptanceOfTermsContent;

  /// Section 2 title
  ///
  /// In en, this message translates to:
  /// **'2. Use License'**
  String get useLicenseTitle;

  /// Section 2 content
  ///
  /// In en, this message translates to:
  /// **'Permission is granted to temporarily download one copy of e-Disha per device for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose or for any public display\n• Attempt to reverse engineer any software contained in the App\n• Remove any copyright or other proprietary notations'**
  String get useLicenseContent;

  /// Section 3 title
  ///
  /// In en, this message translates to:
  /// **'3. Privacy Policy'**
  String get privacyPolicyTermsTitle;

  /// Section 3 content
  ///
  /// In en, this message translates to:
  /// **'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information when you use our service. By using our service, you agree to the collection and use of information in accordance with our Privacy Policy.'**
  String get privacyPolicyTermsContent;

  /// Section 4 title
  ///
  /// In en, this message translates to:
  /// **'4. User Account'**
  String get userAccountTitle;

  /// Section 4 content
  ///
  /// In en, this message translates to:
  /// **'When you create an account with us, you must provide information that is accurate, complete, and current at all times. You are responsible for safeguarding the password and for all activities that occur under your account.'**
  String get userAccountContent;

  /// Footer thank you message
  ///
  /// In en, this message translates to:
  /// **'Thank you for using e-Disha'**
  String get thankYouForUsing;

  /// Footer acknowledgment text
  ///
  /// In en, this message translates to:
  /// **'By continuing to use our application, you acknowledge that you have read, understood, and agree to these terms and conditions.'**
  String get byContinuingYouAcknowledge;

  /// Privacy policy section 1 title
  ///
  /// In en, this message translates to:
  /// **'1. Information We Collect'**
  String get informationWeCollectTitle;

  /// Privacy policy section 1 content
  ///
  /// In en, this message translates to:
  /// **'We collect several types of information from and about users of our App:\\n\\n• Personal Information: Name, phone number, email address\\n• Vehicle Information: Vehicle details, registration number, device ID\\n• Location Data: GPS coordinates, routes, speed, and movement patterns\\n• Usage Data: App interactions, features used, session duration\\n• Device Information: Device type, operating system, unique identifiers'**
  String get informationWeCollectContent;

  /// Privacy policy section 2 title
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Your Information'**
  String get howWeUseInfoTitle;

  /// Privacy policy section 2 content
  ///
  /// In en, this message translates to:
  /// **'We use the information we collect for various purposes:\\n\\n• Provide and maintain our GPS tracking services\\n• Process transactions and send related information\\n• Send technical notices, updates, and support messages\\n• Respond to your comments, questions, and requests\\n• Monitor and analyze trends, usage, and activities\\n• Improve our services and develop new features\\n• Ensure security and prevent fraud'**
  String get howWeUseInfoContent;

  /// Privacy policy footer title
  ///
  /// In en, this message translates to:
  /// **'Your Privacy Matters'**
  String get yourPrivacyMatters;

  /// Privacy policy footer commitment text
  ///
  /// In en, this message translates to:
  /// **'We are committed to protecting your privacy and ensuring the security of your personal information while providing the best possible service.'**
  String get privacyCommitment;

  /// Vehicle tracking section title
  ///
  /// In en, this message translates to:
  /// **'5. Vehicle Tracking Services'**
  String get vehicleTrackingTitle;

  /// Vehicle tracking section content
  ///
  /// In en, this message translates to:
  /// **'e-Disha provides GPS tracking and fleet management services. You understand that:\\n\\n• Location data accuracy depends on GPS signal availability\\n• Service may be temporarily unavailable due to technical issues\\n• You are responsible for ensuring proper device installation\\n• Data transmission requires active mobile/internet connectivity'**
  String get vehicleTrackingContent;

  /// Data collection section title
  ///
  /// In en, this message translates to:
  /// **'6. Data Collection and Usage'**
  String get dataCollectionTitle;

  /// Data collection section content
  ///
  /// In en, this message translates to:
  /// **'We collect and process data to provide our services effectively:\\n\\n• Location data for real-time tracking and route optimization\\n• Vehicle performance data for maintenance alerts\\n• User interaction data to improve app functionality\\n• All data collection complies with applicable privacy laws\\n• You can control data sharing through app settings'**
  String get dataCollectionContent;

  /// Service limitations section title
  ///
  /// In en, this message translates to:
  /// **'7. Service Limitations'**
  String get serviceLimitationsTitle;

  /// Service limitations section content
  ///
  /// In en, this message translates to:
  /// **'Our services are provided \'as is\' and may have limitations:\\n\\n• GPS accuracy may vary based on environmental conditions\\n• Service availability depends on network connectivity\\n• We do not guarantee uninterrupted service\\n• Features may be updated or modified without prior notice\\n• Some features may require additional subscriptions'**
  String get serviceLimitationsContent;

  /// User responsibilities section title
  ///
  /// In en, this message translates to:
  /// **'8. User Responsibilities'**
  String get userResponsibilitiesTitle;

  /// User responsibilities section content
  ///
  /// In en, this message translates to:
  /// **'As a user of e-Disha, you agree to:\\n\\n• Provide accurate and up-to-date information\\n• Use the service only for lawful purposes\\n• Maintain the security of your account credentials\\n• Report any unauthorized use of your account\\n• Comply with all applicable laws and regulations\\n• Respect the privacy and rights of other users'**
  String get userResponsibilitiesContent;

  /// Prohibited uses section title
  ///
  /// In en, this message translates to:
  /// **'9. Prohibited Uses'**
  String get prohibitedUsesTitle;

  /// Prohibited uses section content
  ///
  /// In en, this message translates to:
  /// **'You may not use our service for:\\n\\n• Any unlawful purpose or to solicit others to unlawful acts\\n• Violating any international, federal, provincial, or state regulations, rules, laws, or local ordinances\\n• Infringing upon or violating our intellectual property rights or the intellectual property rights of others\\n• Harassing, abusing, insulting, harming, defaming, slandering, disparaging, intimidating, or discriminating\\n• Submitting false or misleading information'**
  String get prohibitedUsesContent;

  /// Termination section title
  ///
  /// In en, this message translates to:
  /// **'10. Termination'**
  String get terminationTitle;

  /// Termination section content
  ///
  /// In en, this message translates to:
  /// **'We may terminate or suspend your account and bar access to the service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms.'**
  String get terminationContent;

  /// Limitation of liability section title
  ///
  /// In en, this message translates to:
  /// **'11. Limitation of Liability'**
  String get limitationOfLiabilityTitle;

  /// Limitation of liability section content
  ///
  /// In en, this message translates to:
  /// **'In no event shall e-Disha, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your use of the service.'**
  String get limitationOfLiabilityContent;

  /// Updates to terms section title
  ///
  /// In en, this message translates to:
  /// **'12. Updates to Terms'**
  String get updatesToTermsTitle;

  /// Updates to terms section content
  ///
  /// In en, this message translates to:
  /// **'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.'**
  String get updatesToTermsContent;

  /// Contact information section title
  ///
  /// In en, this message translates to:
  /// **'13. Contact Information'**
  String get contactInformationTitle;

  /// Contact information section content
  ///
  /// In en, this message translates to:
  /// **'If you have any questions about these Terms and Conditions, please contact us at:\\n\\nEmail: support@edisha.com\\nPhone: +91-XXXXX-XXXXX\\nAddress: [Company Address]'**
  String get contactInformationContent;

  /// Privacy policy information sharing section title
  ///
  /// In en, this message translates to:
  /// **'3. Information Sharing'**
  String get informationSharingTitle;

  /// Privacy policy information sharing section content
  ///
  /// In en, this message translates to:
  /// **'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy:\\n\\n• Service Providers: We may share information with trusted third parties who assist us in operating our app\\n• Legal Requirements: We may disclose information when required by law or to protect our rights\\n• Business Transfers: Information may be transferred in connection with a merger or acquisition'**
  String get informationSharingContent;

  /// Privacy policy data security section title
  ///
  /// In en, this message translates to:
  /// **'4. Data Security'**
  String get dataSecurityTitle;

  /// Privacy policy data security section content
  ///
  /// In en, this message translates to:
  /// **'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction:\\n\\n• Encryption of sensitive data during transmission\\n• Regular security assessments and updates\\n• Limited access to personal information\\n• Secure data storage practices'**
  String get dataSecurityContent;

  /// Privacy policy location data section title
  ///
  /// In en, this message translates to:
  /// **'5. Location Data'**
  String get locationDataTitle;

  /// Privacy policy location data section content
  ///
  /// In en, this message translates to:
  /// **'Our app collects and uses location data to provide GPS tracking services:\\n\\n• Real-time location tracking for fleet management\\n• Route optimization and navigation assistance\\n• Geofencing and alert notifications\\n• Historical route and location analysis\\n\\nYou can disable location services through your device settings, but this may limit app functionality.'**
  String get locationDataContent;

  /// Privacy policy data retention section title
  ///
  /// In en, this message translates to:
  /// **'6. Data Retention'**
  String get dataRetentionTitle;

  /// Privacy policy data retention section content
  ///
  /// In en, this message translates to:
  /// **'We retain your personal information for as long as necessary to provide our services and comply with legal obligations:\\n\\n• Account information: Retained while your account is active\\n• Location data: Stored for up to 2 years for historical analysis\\n• Usage data: Retained for up to 1 year for service improvement\\n• Legal compliance: Some data may be retained longer as required by law'**
  String get dataRetentionContent;

  /// Privacy policy your rights section title
  ///
  /// In en, this message translates to:
  /// **'7. Your Rights'**
  String get yourRightsTitle;

  /// Privacy policy your rights section content
  ///
  /// In en, this message translates to:
  /// **'You have certain rights regarding your personal information:\\n\\n• Access: Request access to your personal data\\n• Correction: Request correction of inaccurate information\\n• Deletion: Request deletion of your personal data\\n• Portability: Request transfer of your data to another service\\n• Objection: Object to certain processing of your data\\n\\nTo exercise these rights, please contact us using the information provided below.'**
  String get yourRightsContent;

  /// Success message when user logs out
  ///
  /// In en, this message translates to:
  /// **'Successfully logged out'**
  String get successfullyLoggedOut;

  /// Error message when logout fails
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Coming soon message for route management
  ///
  /// In en, this message translates to:
  /// **'Route Management coming soon!'**
  String get routeManagementComingSoon;

  /// Coming soon message for device management
  ///
  /// In en, this message translates to:
  /// **'Device Management coming soon!'**
  String get deviceManagementComingSoon;

  /// Coming soon message for notification center
  ///
  /// In en, this message translates to:
  /// **'Notification Center coming soon!'**
  String get notificationCenterComingSoon;

  /// Total drivers label
  ///
  /// In en, this message translates to:
  /// **'Total Drivers'**
  String get totalDrivers;

  /// Active status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// On duty status label
  ///
  /// In en, this message translates to:
  /// **'On Duty'**
  String get onDuty;

  /// Harsh braking alert label
  ///
  /// In en, this message translates to:
  /// **'Harsh Braking'**
  String get harshBraking;

  /// Overspeeding alert label
  ///
  /// In en, this message translates to:
  /// **'Overspeeding'**
  String get overspeeding;

  /// Sudden turn alert label
  ///
  /// In en, this message translates to:
  /// **'Sudden Turn'**
  String get suddenTurn;

  /// Service management section title
  ///
  /// In en, this message translates to:
  /// **'Service Management'**
  String get serviceManagement;

  /// Routes navigation label
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routes;

  /// Devices management label
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// Manage routes subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage Routes'**
  String get manageRoutes;

  /// Live tracking navigation label
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// App settings subtitle
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// Active count suffix
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeCount;

  /// Notifications count suffix
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsCount;

  /// Total trips label
  ///
  /// In en, this message translates to:
  /// **'Total Trips'**
  String get totalTrips;

  /// Total vehicles label
  ///
  /// In en, this message translates to:
  /// **'Total Vehicles'**
  String get totalVehicles;

  /// Coming soon message for settings management
  ///
  /// In en, this message translates to:
  /// **'Settings Management coming soon!'**
  String get settingsManagementComingSoon;

  /// History playback navigation label
  ///
  /// In en, this message translates to:
  /// **'History Playback'**
  String get historyPlayback;

  /// Driver behaviour section title
  ///
  /// In en, this message translates to:
  /// **'Driver Behaviour'**
  String get driverBehaviour;

  /// Vehicle status section title
  ///
  /// In en, this message translates to:
  /// **'Vehicle Status'**
  String get vehicleStatus;

  /// Alert overview section title
  ///
  /// In en, this message translates to:
  /// **'Alert Overview'**
  String get alertOverview;

  /// Moving vehicles status
  ///
  /// In en, this message translates to:
  /// **'Moving'**
  String get moving;

  /// Idle vehicles status
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get idle;

  /// Offline vehicles status
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// Critical alerts status
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// Warning alerts status
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Route fixing menu item
  ///
  /// In en, this message translates to:
  /// **'Route Fixing'**
  String get routeFixing;

  /// Live tracking menu item
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTracking;

  /// Vehicle history menu item
  ///
  /// In en, this message translates to:
  /// **'Vehicle History'**
  String get vehicleHistory;

  /// Add driver menu item
  ///
  /// In en, this message translates to:
  /// **'Add Driver'**
  String get addDriver;

  /// Reports menu item
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Today label for alerts
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Alerts menu item
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// Total count label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Live tracking screen title
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTrackingTitle;

  /// History playback screen title
  ///
  /// In en, this message translates to:
  /// **'History Playback'**
  String get historyPlaybackTitle;

  /// Route fixing screen title
  ///
  /// In en, this message translates to:
  /// **'Route Fixing'**
  String get routeFixingTitle;

  /// Select vehicle type label
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle Type'**
  String get selectVehicleType;

  /// Update interval setting label
  ///
  /// In en, this message translates to:
  /// **'Update Interval'**
  String get updateInterval;

  /// Yellow car vehicle type
  ///
  /// In en, this message translates to:
  /// **'Yellow Car'**
  String get yellowCar;

  /// Blue car vehicle type
  ///
  /// In en, this message translates to:
  /// **'Blue Car'**
  String get blueCar;

  /// Brown truck vehicle type
  ///
  /// In en, this message translates to:
  /// **'Brown Truck'**
  String get brownTruck;

  /// Bike vehicle type
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get bike;

  /// Bus vehicle type
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get bus;

  /// Vehicle type tooltip
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// Update settings tooltip
  ///
  /// In en, this message translates to:
  /// **'Update Settings'**
  String get updateSettings;

  /// Show all vehicles tooltip
  ///
  /// In en, this message translates to:
  /// **'Show All Vehicles'**
  String get showAllVehicles;

  /// Error loading map message
  ///
  /// In en, this message translates to:
  /// **'Error Loading Map'**
  String get errorLoadingMap;

  /// Unknown error message
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

  /// Start point marker title
  ///
  /// In en, this message translates to:
  /// **'Start Point'**
  String get startPoint;

  /// End point marker title
  ///
  /// In en, this message translates to:
  /// **'End Point'**
  String get endPoint;

  /// Waypoint marker title
  ///
  /// In en, this message translates to:
  /// **'Waypoint {number}'**
  String get waypoint;

  /// Tap to remove marker snippet
  ///
  /// In en, this message translates to:
  /// **'Tap to remove'**
  String get tapToRemove;

  /// Add route points message
  ///
  /// In en, this message translates to:
  /// **'Please add route points and select a vehicle'**
  String get addRoutePoints;

  /// Edit route title
  ///
  /// In en, this message translates to:
  /// **'Edit Route'**
  String get editRoute;

  /// Create new route title
  ///
  /// In en, this message translates to:
  /// **'Create New Route'**
  String get createNewRoute;

  /// No history data found message
  ///
  /// In en, this message translates to:
  /// **'No history data found for the selected period'**
  String get noHistoryDataFound;

  /// Playback completed message
  ///
  /// In en, this message translates to:
  /// **'Playback completed'**
  String get playbackCompleted;

  /// Failed to load history title
  ///
  /// In en, this message translates to:
  /// **'Failed to Load History'**
  String get failedToLoadHistory;

  /// Unexpected error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// Go back button text
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// Try again button text
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Vehicle history screen title
  ///
  /// In en, this message translates to:
  /// **'Vehicle History'**
  String get vehicleHistoryTitle;

  /// Vehicle history subtitle
  ///
  /// In en, this message translates to:
  /// **'Track your fleet movements'**
  String get trackYourFleet;

  /// All filter option
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Inactive filter option
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Refresh button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No vehicles available message
  ///
  /// In en, this message translates to:
  /// **'No vehicles available for history playback'**
  String get noVehiclesAvailable;

  /// Select vehicle label
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle'**
  String get selectVehicle;

  /// Load history button text
  ///
  /// In en, this message translates to:
  /// **'Load History'**
  String get loadHistory;

  /// Select date range label
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// Start date label
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// End date label
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// Driver management screen title
  ///
  /// In en, this message translates to:
  /// **'Driver Management'**
  String get driverManagementTitle;

  /// Search drivers placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search drivers...'**
  String get searchDrivers;

  /// Loading drivers message
  ///
  /// In en, this message translates to:
  /// **'Loading drivers...'**
  String get loadingDrivers;

  /// No drivers found message
  ///
  /// In en, this message translates to:
  /// **'No drivers found'**
  String get noDriversFound;

  /// Add new driver dialog title
  ///
  /// In en, this message translates to:
  /// **'Add New Driver'**
  String get addNewDriver;

  /// Tap to add photo instruction
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get tapToAddPhoto;

  /// Camera or gallery option text
  ///
  /// In en, this message translates to:
  /// **'Camera or Gallery'**
  String get cameraOrGallery;

  /// Driver name field label
  ///
  /// In en, this message translates to:
  /// **'Driver Name'**
  String get driverName;

  /// License number field label
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get licenseNumber;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Select vehicle/device dropdown label
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle/Device'**
  String get selectVehicleDevice;

  /// Active status badge text
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeStatus;

  /// Driver name validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter driver name'**
  String get pleaseEnterDriverName;

  /// License number validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter license number'**
  String get pleaseEnterLicenseNumber;

  /// Phone number validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhoneNumber;

  /// Valid phone number validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhoneNumber;

  /// Take photo option
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Camera option description
  ///
  /// In en, this message translates to:
  /// **'Use camera to capture photo'**
  String get useCameraToCapture;

  /// Gallery option title
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// Gallery option description
  ///
  /// In en, this message translates to:
  /// **'Select from existing photos'**
  String get selectFromExistingPhotos;

  /// Select start date dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Start Date'**
  String get selectStartDate;

  /// Select end date dialog title
  ///
  /// In en, this message translates to:
  /// **'Select End Date'**
  String get selectEndDate;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue on GitHub with a '
    'reproducible sample app and the gen-l10n configuration that was used.'
  );
}