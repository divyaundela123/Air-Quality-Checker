// ============================================================
// AeroSense — Multi-language string constants
// Supported: English, Telugu, Hindi, Tamil
// ============================================================

enum AppLanguage { english, telugu, hindi, tamil }

extension AppLanguageExt on AppLanguage {
  String get displayName {
    switch (this) {
      case AppLanguage.english: return 'English';
      case AppLanguage.telugu:  return 'తెలుగు (Telugu)';
      case AppLanguage.hindi:   return 'हिन्दी (Hindi)';
      case AppLanguage.tamil:   return 'தமிழ் (Tamil)';
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.english: return 'en';
      case AppLanguage.telugu:  return 'te';
      case AppLanguage.hindi:   return 'hi';
      case AppLanguage.tamil:   return 'ta';
    }
  }

  String get flagEmoji {
    switch (this) {
      case AppLanguage.english: return '🇬🇧';
      case AppLanguage.telugu:
      case AppLanguage.hindi:
      case AppLanguage.tamil:   return '🇮🇳';
    }
  }
}

/// All translatable strings for the app.
class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  // ── All 4 languages ──────────────────────────────────────────
  static const List<AppLanguage> all = [
    AppLanguage.english,
    AppLanguage.telugu,
    AppLanguage.hindi,
    AppLanguage.tamil,
  ];

  // ── App ──────────────────────────────────────────────────────
  String get appName => 'AeroSense';

  String get tagline {
    switch (language) {
      case AppLanguage.english: return 'Breathe smarter.';
      case AppLanguage.telugu:  return 'తెలివిగా శ్వాసించండి.';
      case AppLanguage.hindi:   return 'स्मार्ट तरीके से सांस लें।';
      case AppLanguage.tamil:   return 'புத்திசாலியாக சுவாசிக்கவும்.';
    }
  }

  // ── Auth ─────────────────────────────────────────────────────
  String get welcomeBack {
    switch (language) {
      case AppLanguage.english: return 'Welcome back';
      case AppLanguage.telugu:  return 'తిరిగి స్వాగతం';
      case AppLanguage.hindi:   return 'वापसी पर स्वागत है';
      case AppLanguage.tamil:   return 'மீண்டும் வரவேற்கிறோம்';
    }
  }

  String get loginSubtitle {
    switch (language) {
      case AppLanguage.english: return 'Enter your details to access your dashboard.';
      case AppLanguage.telugu:  return 'మీ డాష్‌బోర్డ్‌ని యాక్సెస్ చేయడానికి వివరాలు నమోదు చేయండి.';
      case AppLanguage.hindi:   return 'अपने डैशबोर्ड तक पहुंचने के लिए विवरण दर्ज करें।';
      case AppLanguage.tamil:   return 'உங்கள் டாஷ்போர்டை அணுக விவரங்களை உள்ளிடவும்.';
    }
  }

  String get email {
    switch (language) {
      case AppLanguage.english: return 'Email';
      case AppLanguage.telugu:  return 'ఇమెయిల్';
      case AppLanguage.hindi:   return 'ईमेल';
      case AppLanguage.tamil:   return 'மின்னஞ்சல்';
    }
  }

  String get password {
    switch (language) {
      case AppLanguage.english: return 'Password';
      case AppLanguage.telugu:  return 'పాస్‌వర్డ్';
      case AppLanguage.hindi:   return 'पासवर्ड';
      case AppLanguage.tamil:   return 'கடவுச்சொல்';
    }
  }

  String get forgotPassword {
    switch (language) {
      case AppLanguage.english: return 'Forgot password?';
      case AppLanguage.telugu:  return 'పాస్‌వర్డ్ మర్చిపోయారా?';
      case AppLanguage.hindi:   return 'पासवर्ड भूल गए?';
      case AppLanguage.tamil:   return 'கடவுச்சொல் மறந்துவிட்டதா?';
    }
  }

  String get logIn {
    switch (language) {
      case AppLanguage.english: return 'Log In';
      case AppLanguage.telugu:  return 'లాగిన్';
      case AppLanguage.hindi:   return 'लॉग इन';
      case AppLanguage.tamil:   return 'உள்நுழை';
    }
  }

  String get noAccount {
    switch (language) {
      case AppLanguage.english: return "Don't have an account? ";
      case AppLanguage.telugu:  return 'ఖాతా లేదా? ';
      case AppLanguage.hindi:   return 'खाता नहीं है? ';
      case AppLanguage.tamil:   return 'கணக்கு இல்லையா? ';
    }
  }

  String get signUp {
    switch (language) {
      case AppLanguage.english: return 'Sign up';
      case AppLanguage.telugu:  return 'సైన్ అప్';
      case AppLanguage.hindi:   return 'साइन अप';
      case AppLanguage.tamil:   return 'பதிவு செய்';
    }
  }

  String get createAccount {
    switch (language) {
      case AppLanguage.english: return 'Create account';
      case AppLanguage.telugu:  return 'ఖాతా తయారు చేయండి';
      case AppLanguage.hindi:   return 'खाता बनाएं';
      case AppLanguage.tamil:   return 'கணக்கு உருவாக்கு';
    }
  }

  String get registerSubtitle {
    switch (language) {
      case AppLanguage.english: return 'Start monitoring your air quality today.';
      case AppLanguage.telugu:  return 'ఈరోజు మీ గాలి నాణ్యతను పర్యవేక్షించడం ప్రారంభించండి.';
      case AppLanguage.hindi:   return 'आज ही अपनी वायु गुणवत्ता की निगरानी शुरू करें।';
      case AppLanguage.tamil:   return 'இன்றே உங்கள் காற்று தரத்தை கண்காணிக்கத் தொடங்குங்கள்.';
    }
  }

  String get fullName {
    switch (language) {
      case AppLanguage.english: return 'Full Name';
      case AppLanguage.telugu:  return 'పూర్తి పేరు';
      case AppLanguage.hindi:   return 'पूरा नाम';
      case AppLanguage.tamil:   return 'முழு பெயர்';
    }
  }

  // ── Dashboard ─────────────────────────────────────────────────
  String get hello {
    switch (language) {
      case AppLanguage.english: return 'Hello';
      case AppLanguage.telugu:  return 'నమస్కారం';
      case AppLanguage.hindi:   return 'नमस्ते';
      case AppLanguage.tamil:   return 'வணக்கம்';
    }
  }

  String get airQualityReport {
    switch (language) {
      case AppLanguage.english: return "Here's your current air quality report";
      case AppLanguage.telugu:  return 'ఇది మీ ప్రస్తుత గాలి నాణ్యత నివేదిక';
      case AppLanguage.hindi:   return 'यहाँ आपकी वर्तमान वायु गुणवत्ता रिपोर्ट है';
      case AppLanguage.tamil:   return 'உங்கள் தற்போதைய காற்று தர அறிக்கை இதோ';
    }
  }

  String get aqiScore {
    switch (language) {
      case AppLanguage.english: return 'AQI Score';
      case AppLanguage.telugu:  return 'AQI స్కోర్';
      case AppLanguage.hindi:   return 'AQI स्कोर';
      case AppLanguage.tamil:   return 'AQI மதிப்பெண்';
    }
  }

  String get temperature {
    switch (language) {
      case AppLanguage.english: return 'Temp';
      case AppLanguage.telugu:  return 'ఉష్ణోగ్రత';
      case AppLanguage.hindi:   return 'तापमान';
      case AppLanguage.tamil:   return 'வெப்பம்';
    }
  }

  String get humidity {
    switch (language) {
      case AppLanguage.english: return 'Humidity';
      case AppLanguage.telugu:  return 'తేమ';
      case AppLanguage.hindi:   return 'आर्द्रता';
      case AppLanguage.tamil:   return 'ஈரப்பதம்';
    }
  }

  String get recommendation {
    switch (language) {
      case AppLanguage.english: return 'Recommendation';
      case AppLanguage.telugu:  return 'సిఫారసు';
      case AppLanguage.hindi:   return 'सुझाव';
      case AppLanguage.tamil:   return 'பரிந்துரை';
    }
  }

  // ── Status labels ────────────────────────────────────────────
  String get safe {
    switch (language) {
      case AppLanguage.english: return 'Safe';
      case AppLanguage.telugu:  return 'సురక్షితం';
      case AppLanguage.hindi:   return 'सुरक्षित';
      case AppLanguage.tamil:   return 'பாதுகாப்பானது';
    }
  }

  String get moderate {
    switch (language) {
      case AppLanguage.english: return 'Moderate';
      case AppLanguage.telugu:  return 'మధ్యస్థం';
      case AppLanguage.hindi:   return 'मध्यम';
      case AppLanguage.tamil:   return 'மிதமான';
    }
  }

  String get warning {
    switch (language) {
      case AppLanguage.english: return 'Warning';
      case AppLanguage.telugu:  return 'హెచ్చరిక';
      case AppLanguage.hindi:   return 'चेतावनी';
      case AppLanguage.tamil:   return 'எச்சரிக்கை';
    }
  }

  String get hazardous {
    switch (language) {
      case AppLanguage.english: return 'Hazardous';
      case AppLanguage.telugu:  return 'ప్రమాదకరం';
      case AppLanguage.hindi:   return 'खतरनाक';
      case AppLanguage.tamil:   return 'அபாயகரமான';
    }
  }

  // ── Navigation ───────────────────────────────────────────────
  String get dashboard {
    switch (language) {
      case AppLanguage.english: return 'Dashboard';
      case AppLanguage.telugu:  return 'డాష్‌బోర్డ్';
      case AppLanguage.hindi:   return 'डैशबोर्ड';
      case AppLanguage.tamil:   return 'டாஷ்போர்ட்';
    }
  }

  String get analyze {
    switch (language) {
      case AppLanguage.english: return 'Analyze';
      case AppLanguage.telugu:  return 'విశ్లేషించు';
      case AppLanguage.hindi:   return 'विश्लेषण';
      case AppLanguage.tamil:   return 'பகுப்பாய்வு';
    }
  }

  String get history {
    switch (language) {
      case AppLanguage.english: return 'History';
      case AppLanguage.telugu:  return 'చరిత్ర';
      case AppLanguage.hindi:   return 'इतिहास';
      case AppLanguage.tamil:   return 'வரலாறு';
    }
  }

  String get profile {
    switch (language) {
      case AppLanguage.english: return 'Profile';
      case AppLanguage.telugu:  return 'ప్రొఫైల్';
      case AppLanguage.hindi:   return 'प्रोफ़ाइल';
      case AppLanguage.tamil:   return 'சுயவிவரம்';
    }
  }

  // ── Analyze screen ────────────────────────────────────────────
  String get analyzeTitle {
    switch (language) {
      case AppLanguage.english: return 'Analyze Air Quality';
      case AppLanguage.telugu:  return 'గాలి నాణ్యతను విశ్లేషించు';
      case AppLanguage.hindi:   return 'वायु गुणवत्ता का विश्लेषण करें';
      case AppLanguage.tamil:   return 'காற்று தரத்தை பகுப்பாய்வு செய்';
    }
  }

  String get liveSensorReadings {
    switch (language) {
      case AppLanguage.english: return 'Live Sensor Readings';
      case AppLanguage.telugu:  return 'లైవ్ సెన్సార్ రీడింగ్‌లు';
      case AppLanguage.hindi:   return 'लाइव सेंसर रीडिंग';
      case AppLanguage.tamil:   return 'நேரடி சென்சார் அளவீடுகள்';
    }
  }

  String get saveAnalysis {
    switch (language) {
      case AppLanguage.english: return 'Save Analysis to History';
      case AppLanguage.telugu:  return 'విశ్లేషణను చరిత్రలో సేవ్ చేయండి';
      case AppLanguage.hindi:   return 'विश्लेषण को इतिहास में सहेजें';
      case AppLanguage.tamil:   return 'பகுப்பாய்வை வரலாற்றில் சேமி';
    }
  }

  String get refresh {
    switch (language) {
      case AppLanguage.english: return 'Refresh';
      case AppLanguage.telugu:  return 'రిఫ్రెష్';
      case AppLanguage.hindi:   return 'रिफ्रेश';
      case AppLanguage.tamil:   return 'புதுப்பி';
    }
  }

  // ── History screen ────────────────────────────────────────────
  String get noHistoryYet {
    switch (language) {
      case AppLanguage.english: return 'No History Yet';
      case AppLanguage.telugu:  return 'చరిత్ర లేదు';
      case AppLanguage.hindi:   return 'अभी तक कोई इतिहास नहीं';
      case AppLanguage.tamil:   return 'இதுவரை வரலாறு இல்லை';
    }
  }

  String get clearAll {
    switch (language) {
      case AppLanguage.english: return 'Clear All';
      case AppLanguage.telugu:  return 'అన్నీ తొలగించు';
      case AppLanguage.hindi:   return 'सभी साफ करें';
      case AppLanguage.tamil:   return 'அனைத்தையும் அழி';
    }
  }

  // ── Profile screen ────────────────────────────────────────────
  String get personalInfo {
    switch (language) {
      case AppLanguage.english: return 'Personal Information';
      case AppLanguage.telugu:  return 'వ్యక్తిగత సమాచారం';
      case AppLanguage.hindi:   return 'व्यक्तिगत जानकारी';
      case AppLanguage.tamil:   return 'தனிப்பட்ட தகவல்';
    }
  }

  String get notifications {
    switch (language) {
      case AppLanguage.english: return 'Notifications';
      case AppLanguage.telugu:  return 'నోటిఫికేషన్లు';
      case AppLanguage.hindi:   return 'सूचनाएं';
      case AppLanguage.tamil:   return 'அறிவிப்புகள்';
    }
  }

  String get settings {
    switch (language) {
      case AppLanguage.english: return 'Settings';
      case AppLanguage.telugu:  return 'సెట్టింగ్‌లు';
      case AppLanguage.hindi:   return 'सेटिंग्स';
      case AppLanguage.tamil:   return 'அமைப்புகள்';
    }
  }

  String get logOut {
    switch (language) {
      case AppLanguage.english: return 'Log Out';
      case AppLanguage.telugu:  return 'లాగ్ అవుట్';
      case AppLanguage.hindi:   return 'लॉग आउट';
      case AppLanguage.tamil:   return 'வெளியேறு';
    }
  }

  // Note: renamed to languageLabel to avoid conflict with field 'language'
  String get languageLabel {
    switch (language) {
      case AppLanguage.english: return 'Language';
      case AppLanguage.telugu:  return 'భాష';
      case AppLanguage.hindi:   return 'भाषा';
      case AppLanguage.tamil:   return 'மொழி';
    }
  }

  String get selectLanguage {
    switch (language) {
      case AppLanguage.english: return 'Select Language';
      case AppLanguage.telugu:  return 'భాషను ఎంచుకోండి';
      case AppLanguage.hindi:   return 'भाषा चुनें';
      case AppLanguage.tamil:   return 'மொழியைத் தேர்ந்தெடுக்கவும்';
    }
  }
}


// Extension to add extra strings used in screens
extension AppStringsExtra on AppStrings {
  // ── Dashboard extras ──────────────────────────────────────────
  String get noReading {
    switch (language) {
      case AppLanguage.english: return 'No reading';
      case AppLanguage.telugu:  return 'రీడింగ్ లేదు';
      case AppLanguage.hindi:   return 'कोई रीडिंग नहीं';
      case AppLanguage.tamil:   return 'வாசிப்பு இல்லை';
    }
  }
  String get noDataYet {
    switch (language) {
      case AppLanguage.english: return 'No data yet. Tap Analyzer to get started!';
      case AppLanguage.telugu:  return 'డేటా లేదు. ప్రారంభించడానికి విశ్లేషకాన్ని నొక్కండి!';
      case AppLanguage.hindi:   return 'अभी कोई डेटा नहीं। शुरू करने के लिए Analyzer टैप करें!';
      case AppLanguage.tamil:   return 'தரவு இல்லை. தொடங்க பகுப்பாய்விளை தட்டவும்!';
    }
  }
  String get goToAnalyzer {
    switch (language) {
      case AppLanguage.english: return 'Go to Analyzer';
      case AppLanguage.telugu:  return 'విశ్లేషకానికి వెళ్ళు';
      case AppLanguage.hindi:   return 'Analyzer पर जाएं';
      case AppLanguage.tamil:   return 'பகுப்பாய்விக்கு செல்';
    }
  }
  String get syncing {
    switch (language) {
      case AppLanguage.english: return 'Syncing';
      case AppLanguage.telugu:  return 'సింక్ అవుతోంది';
      case AppLanguage.hindi:   return 'सिंक हो रहा है';
      case AppLanguage.tamil:   return 'ஒத்திசைக்கிறது';
    }
  }
  String get avgAqi7d {
    switch (language) {
      case AppLanguage.english: return 'Avg AQI (7d)';
      case AppLanguage.telugu:  return 'సగటు AQI (7d)';
      case AppLanguage.hindi:   return 'औसत AQI (7d)';
      case AppLanguage.tamil:   return 'சராசரி AQI (7d)';
    }
  }
  String get totalReadings {
    switch (language) {
      case AppLanguage.english: return 'Total Readings';
      case AppLanguage.telugu:  return 'మొత్తం రీడింగ్‌లు';
      case AppLanguage.hindi:   return 'कुल रीडिंग';
      case AppLanguage.tamil:   return 'மொத்த வாசிப்புகள்';
    }
  }
  String get bestReading {
    switch (language) {
      case AppLanguage.english: return 'Best Reading';
      case AppLanguage.telugu:  return 'అత్యుత్తమ రీడింగ్';
      case AppLanguage.hindi:   return 'सर्वश्रेष्ठ रीडिंग';
      case AppLanguage.tamil:   return 'சிறந்த வாசிப்பு';
    }
  }

  // ── Analyze screen extras ─────────────────────────────────────
  String get realTimeAqi {
    switch (language) {
      case AppLanguage.english: return 'Real-time AQI';
      case AppLanguage.telugu:  return 'రియల్-టైమ్ AQI';
      case AppLanguage.hindi:   return 'रियल-टाइम AQI';
      case AppLanguage.tamil:   return 'நிகழ்நேர AQI';
    }
  }
  String get realTimeSensorSubtitle {
    switch (language) {
      case AppLanguage.english: return 'Real-time sensor data — read-only from live feed';
      case AppLanguage.telugu:  return 'రియల్-టైమ్ సెన్సార్ డేటా — లైవ్ ఫీడ్ నుండి చదవడం మాత్రమే';
      case AppLanguage.hindi:   return 'रियल-टाइम सेंसर डेटा — लाइव फीड से केवल-पठन';
      case AppLanguage.tamil:   return 'நிகழ்நேர சென்சார் தரவு — நேரடி ஊட்டத்திலிருந்து படிக்க மட்டும்';
    }
  }
  String get valuesAutoRead {
    switch (language) {
      case AppLanguage.english: return 'Values are read automatically from live sensors';
      case AppLanguage.telugu:  return 'విలువలు లైవ్ సెన్సార్ల నుండి స్వయంచాలకంగా చదవబడతాయి';
      case AppLanguage.hindi:   return 'मूल्य लाइव सेंसर से स्वचालित रूप से पढ़े जाते हैं';
      case AppLanguage.tamil:   return 'மதிப்புகள் நேரடி சென்சார்களிலிருந்து தானாக படிக்கப்படுகின்றன';
    }
  }
  String get fetchingLiveSensor {
    switch (language) {
      case AppLanguage.english: return 'Fetching live sensor data…';
      case AppLanguage.telugu:  return 'లైవ్ సెన్సార్ డేటా తీసుకుంటోంది…';
      case AppLanguage.hindi:   return 'लाइव सेंसर डेटा प्राप्त हो रहा है…';
      case AppLanguage.tamil:   return 'நேரடி சென்சார் தரவை பெறுகிறது…';
    }
  }
  String get analyzing {
    switch (language) {
      case AppLanguage.english: return 'Analyzing…';
      case AppLanguage.telugu:  return 'విశ్లేషిస్తోంది…';
      case AppLanguage.hindi:   return 'विश्लेषण हो रहा है…';
      case AppLanguage.tamil:   return 'பகுப்பாய்வு செய்கிறது…';
    }
  }
  String get overview {
    switch (language) {
      case AppLanguage.english: return 'Overview';
      case AppLanguage.telugu:  return 'అవలోకనం';
      case AppLanguage.hindi:   return 'अवलोकन';
      case AppLanguage.tamil:   return 'கண்ணோட்டம்';
    }
  }

  // ── History extras ────────────────────────────────────────────
  String get historyTitle {
    switch (language) {
      case AppLanguage.english: return 'History';
      case AppLanguage.telugu:  return 'చరిత్ర';
      case AppLanguage.hindi:   return 'इतिहास';
      case AppLanguage.tamil:   return 'வரலாறு';
    }
  }
  String get deleteRecord {
    switch (language) {
      case AppLanguage.english: return 'Delete Record?';
      case AppLanguage.telugu:  return 'రికార్డు తొలగించాలా?';
      case AppLanguage.hindi:   return 'रिकॉर्ड हटाएं?';
      case AppLanguage.tamil:   return 'பதிவை நீக்கவா?';
    }
  }
  String get deleteRecordBody {
    switch (language) {
      case AppLanguage.english: return 'This reading will be permanently removed from your history.';
      case AppLanguage.telugu:  return 'ఈ రీడింగ్ మీ చరిత్ర నుండి శాశ్వతంగా తొలగించబడుతుంది.';
      case AppLanguage.hindi:   return 'यह रीडिंग आपके इतिहास से स्थायी रूप से हटा दी जाएगी।';
      case AppLanguage.tamil:   return 'இந்த வாசிப்பு உங்கள் வரலாற்றிலிருந்து நிரந்தரமாக அகற்றப்படும்.';
    }
  }
  String get clearAllHistory {
    switch (language) {
      case AppLanguage.english: return 'Clear All History?';
      case AppLanguage.telugu:  return 'మొత్తం చరిత్ర తొలగించాలా?';
      case AppLanguage.hindi:   return 'सारा इतिहास साफ़ करें?';
      case AppLanguage.tamil:   return 'அனைத்து வரலாற்றையும் அழிக்கவா?';
    }
  }
  String get clearAllHistoryBody {
    switch (language) {
      case AppLanguage.english: return 'All readings will be permanently deleted. This cannot be undone.';
      case AppLanguage.telugu:  return 'అన్ని రీడింగ్‌లు శాశ్వతంగా తొలగించబడతాయి. ఇది రద్దు చేయలేరు.';
      case AppLanguage.hindi:   return 'सभी रीडिंग स्थायी रूप से हटा दी जाएंगी। यह पूर्ववत नहीं किया जा सकता।';
      case AppLanguage.tamil:   return 'அனைத்து வாசிப்புகளும் நிரந்தரமாக நீக்கப்படும். இதை மாற்ற முடியாது.';
    }
  }
  String get cancel {
    switch (language) {
      case AppLanguage.english: return 'Cancel';
      case AppLanguage.telugu:  return 'రద్దు';
      case AppLanguage.hindi:   return 'रद्द करें';
      case AppLanguage.tamil:   return 'ரத்து செய்';
    }
  }
  String get delete {
    switch (language) {
      case AppLanguage.english: return 'Delete';
      case AppLanguage.telugu:  return 'తొలగించు';
      case AppLanguage.hindi:   return 'हटाएं';
      case AppLanguage.tamil:   return 'நீக்கு';
    }
  }
  String get recordDeleted {
    switch (language) {
      case AppLanguage.english: return 'Record deleted';
      case AppLanguage.telugu:  return 'రికార్డు తొలగించబడింది';
      case AppLanguage.hindi:   return 'रिकॉर्ड हटाया गया';
      case AppLanguage.tamil:   return 'பதிவு நீக்கப்பட்டது';
    }
  }

  // ── Auth extras ───────────────────────────────────────────────
  String get alreadyHaveAccount {
    switch (language) {
      case AppLanguage.english: return 'Already have an account? ';
      case AppLanguage.telugu:  return 'ఇప్పటికే ఖాతా ఉందా? ';
      case AppLanguage.hindi:   return 'पहले से खाता है? ';
      case AppLanguage.tamil:   return 'ஏற்கனவே கணக்கு உள்ளதா? ';
    }
  }
  String get backToLogin {
    switch (language) {
      case AppLanguage.english: return 'Back to Login';
      case AppLanguage.telugu:  return 'లాగిన్‌కు తిరిగి';
      case AppLanguage.hindi:   return 'लॉगिन पर वापस';
      case AppLanguage.tamil:   return 'உள்நுழைவுக்கு திரும்பு';
    }
  }

  // ── Sensor quality labels ─────────────────────────────────────
  String get comfortable {
    switch (language) {
      case AppLanguage.english: return 'Comfortable';
      case AppLanguage.telugu:  return 'సుఖకరం';
      case AppLanguage.hindi:   return 'आरामदायक';
      case AppLanguage.tamil:   return 'வசதியானது';
    }
  }
  String get warm {
    switch (language) {
      case AppLanguage.english: return 'Warm';
      case AppLanguage.telugu:  return 'వెచ్చగా';
      case AppLanguage.hindi:   return 'गर्म';
      case AppLanguage.tamil:   return 'வெப்பமான';
    }
  }
  String get cold {
    switch (language) {
      case AppLanguage.english: return 'Cold';
      case AppLanguage.telugu:  return 'చల్లగా';
      case AppLanguage.hindi:   return 'ठंडा';
      case AppLanguage.tamil:   return 'குளிர்ச்சியான';
    }
  }
  String get highTemp {
    switch (language) {
      case AppLanguage.english: return 'High — +30 AQI penalty';
      case AppLanguage.telugu:  return 'అధికం — +30 AQI పెనాల్టీ';
      case AppLanguage.hindi:   return 'उच्च — +30 AQI दंड';
      case AppLanguage.tamil:   return 'அதிகம் — +30 AQI அபராதம்';
    }
  }
  String get highHumidity {
    switch (language) {
      case AppLanguage.english: return 'High — +10 AQI penalty';
      case AppLanguage.telugu:  return 'అధికం — +10 AQI పెనాల్టీ';
      case AppLanguage.hindi:   return 'उच्च — +10 AQI दंड';
      case AppLanguage.tamil:   return 'அதிகம் — +10 AQI அபராதம்';
    }
  }
  String get humid {
    switch (language) {
      case AppLanguage.english: return 'Humid';
      case AppLanguage.telugu:  return 'తేమగా';
      case AppLanguage.hindi:   return 'आर्द्र';
      case AppLanguage.tamil:   return 'ஈரமான';
    }
  }
  String get dry {
    switch (language) {
      case AppLanguage.english: return 'Dry';
      case AppLanguage.telugu:  return 'పొడిగా';
      case AppLanguage.hindi:   return 'शुष्क';
      case AppLanguage.tamil:   return 'உலர்ந்த';
    }
  }
  String get comfortableRange {
    switch (language) {
      case AppLanguage.english: return 'Comfortable range';
      case AppLanguage.telugu:  return 'సుఖకరమైన పరిధి';
      case AppLanguage.hindi:   return 'आरामदायक सीमा';
      case AppLanguage.tamil:   return 'வசதியான வரம்பு';
    }
  }
  String get elevated {
    switch (language) {
      case AppLanguage.english: return 'Elevated';
      case AppLanguage.telugu:  return 'పెరిగింది';
      case AppLanguage.hindi:   return 'ऊंचा';
      case AppLanguage.tamil:   return 'உயர்ந்த';
    }
  }
  String get acceptable {
    switch (language) {
      case AppLanguage.english: return 'Moderate';
      case AppLanguage.telugu:  return 'మధ్యస్థం';
      case AppLanguage.hindi:   return 'मध्यम';
      case AppLanguage.tamil:   return 'மிதமான';
    }
  }
  String get highCo2 {
    switch (language) {
      case AppLanguage.english: return 'High CO₂ level!';
      case AppLanguage.telugu:  return 'అధిక CO₂ స్థాయి!';
      case AppLanguage.hindi:   return 'उच्च CO₂ स्तर!';
      case AppLanguage.tamil:   return 'அதிக CO₂ அளவு!';
    }
  }
  String get highVoc {
    switch (language) {
      case AppLanguage.english: return 'High VOC level!';
      case AppLanguage.telugu:  return 'అధిక VOC స్థాయి!';
      case AppLanguage.hindi:   return 'उच्च VOC स्तर!';
      case AppLanguage.tamil:   return 'அதிக VOC அளவு!';
    }
  }
  String get good {
    switch (language) {
      case AppLanguage.english: return 'Good';
      case AppLanguage.telugu:  return 'మంచిది';
      case AppLanguage.hindi:   return 'अच्छा';
      case AppLanguage.tamil:   return 'நல்லது';
    }
  }
  String get lastUpdatedAuto {
    switch (language) {
      case AppLanguage.english: return 'Auto-refreshes every 30s';
      case AppLanguage.telugu:  return 'ప్రతి 30 సెకన్లకు స్వయంచాలకంగా రిఫ్రెష్';
      case AppLanguage.hindi:   return 'हर 30 सेकंड में स्वचालित रूप से रिफ्रेश';
      case AppLanguage.tamil:   return 'ஒவ்வொரு 30 வினாடியும் தானாக புதுப்பிக்கப்படுகிறது';
    }
  }
}


// Extension for status + recommendation translations
extension AppStringsStatus on AppStrings {
  /// Translates internal status string ('Safe','Moderate','Warning','Hazardous') to display label.
  String statusLabel(String status) {
    switch (status) {
      case 'Safe':      return safe;
      case 'Moderate':  return moderate;
      case 'Warning':   return warning;
      case 'Hazardous': return hazardous;
      default:          return status;
    }
  }

  /// Translates recommendation message.
  String recommendationText(String status) {
    switch (status) {
      case 'Safe':
        switch (language) {
          case AppLanguage.english: return 'Air quality is optimal. Enjoy your environment!';
          case AppLanguage.telugu:  return 'గాలి నాణ్యత మేలైనది. మీ వాతావరణాన్ని ఆనందించండి!';
          case AppLanguage.hindi:   return 'वायु गुणवत्ता उत्तम है। अपने पर्यावरण का आनंद लें!';
          case AppLanguage.tamil:   return 'காற்று தரம் சிறந்தது. உங்கள் சூழலை அனுபவிக்கவும்!';
        }
      case 'Moderate':
        switch (language) {
          case AppLanguage.english: return 'Air quality is acceptable. Sensitive individuals should limit prolonged outdoor exertion.';
          case AppLanguage.telugu:  return 'గాలి నాణ్యత ఆమోదయోగ్యం. సున్నితమైన వ్యక్తులు దీర్ఘకాలిక వెలుపల శ్రమను పరిమితం చేయాలి.';
          case AppLanguage.hindi:   return 'वायु गुणवत्ता स्वीकार्य है। संवेदनशील व्यक्तियों को बाहरी परिश्रम सीमित करना चाहिए।';
          case AppLanguage.tamil:   return 'காற்று தரம் ஏற்கத்தக்கது. உணர்திறன் உள்ளவர்கள் நீண்ட நேர வெளிப்புற உழைப்பை கட்டுப்படுத்தவும்.';
        }
      case 'Warning':
        switch (language) {
          case AppLanguage.english: return 'Consider improving ventilation by opening windows or turning on exhaust fans.';
          case AppLanguage.telugu:  return 'కిటికీలు తెరవడం లేదా ఎగ్జాస్ట్ ఫ్యాన్లు ఆన్ చేయడం ద్వారా వెంటిలేషన్ మెరుగుపరచండి.';
          case AppLanguage.hindi:   return 'खिड़कियां खोलकर या एग्जॉस्ट फैन चलाकर वेंटिलेशन सुधारने पर विचार करें।';
          case AppLanguage.tamil:   return 'ஜன்னல்களைத் திறந்து அல்லது காற்றோட்டி ரசிகர்களை இயக்கி காற்றோட்டத்தை மேம்படுத்தவும்.';
        }
      case 'Hazardous':
        switch (language) {
          case AppLanguage.english: return 'Dangerous levels detected! Please evacuate the area immediately and open doors if safe.';
          case AppLanguage.telugu:  return 'ప్రమాదకరమైన స్థాయిలు గుర్తించబడ్డాయి! వెంటనే ప్రాంతాన్ని ఖాళీ చేయండి.';
          case AppLanguage.hindi:   return 'खतरनाक स्तर पाए गए! कृपया तुरंत क्षेत्र खाली करें।';
          case AppLanguage.tamil:   return 'ஆபத்தான அளவுகள் கண்டறியப்பட்டன! உடனடியாக பகுதியை காலி செய்யவும்.';
        }
      default:
        return '';
    }
  }
}


// Profile screen section headers and menu labels
extension AppStringsProfile on AppStrings {
  String get account {
    switch (language) {
      case AppLanguage.english: return 'Account';
      case AppLanguage.telugu:  return 'ఖాతా';
      case AppLanguage.hindi:   return 'खाता';
      case AppLanguage.tamil:   return 'கணக்கு';
    }
  }
  String get support {
    switch (language) {
      case AppLanguage.english: return 'Support';
      case AppLanguage.telugu:  return 'మద్దతు';
      case AppLanguage.hindi:   return 'सहायता';
      case AppLanguage.tamil:   return 'ஆதரவு';
    }
  }
  String get privacySecurity {
    switch (language) {
      case AppLanguage.english: return 'Privacy & Security';
      case AppLanguage.telugu:  return 'గోప్యత & భద్రత';
      case AppLanguage.hindi:   return 'गोपनीयता और सुरक्षा';
      case AppLanguage.tamil:   return 'தனியுரிமை & பாதுகாப்பு';
    }
  }
  String get helpCenter {
    switch (language) {
      case AppLanguage.english: return 'Help Center';
      case AppLanguage.telugu:  return 'సహాయ కేంద్రం';
      case AppLanguage.hindi:   return 'सहायता केंद्र';
      case AppLanguage.tamil:   return 'உதவி மையம்';
    }
  }
  String get statusLabel2 {
    switch (language) {
      case AppLanguage.english: return 'Status';
      case AppLanguage.telugu:  return 'స్థితి';
      case AppLanguage.hindi:   return 'स्थिति';
      case AppLanguage.tamil:   return 'நிலை';
    }
  }
  String get readings {
    switch (language) {
      case AppLanguage.english: return 'Readings';
      case AppLanguage.telugu:  return 'రీడింగ్‌లు';
      case AppLanguage.hindi:   return 'रीडिंग';
      case AppLanguage.tamil:   return 'வாசிப்புகள்';
    }
  }
  String get avgAqi {
    switch (language) {
      case AppLanguage.english: return 'Avg AQI';
      case AppLanguage.telugu:  return 'సగటు AQI';
      case AppLanguage.hindi:   return 'औसत AQI';
      case AppLanguage.tamil:   return 'சராசரி AQI';
    }
  }
}


// Logout dialog strings
extension AppStringsLogout on AppStrings {
  String get logOutQuestion {
    switch (language) {
      case AppLanguage.english: return 'Log Out?';
      case AppLanguage.telugu:  return 'లాగ్ అవుట్ చేయాలా?';
      case AppLanguage.hindi:   return 'लॉग आउट करें?';
      case AppLanguage.tamil:   return 'வெளியேறவா?';
    }
  }
  String get logOutConfirm {
    switch (language) {
      case AppLanguage.english: return 'Are you sure you want to log out?';
      case AppLanguage.telugu:  return 'మీరు నిజంగా లాగ్ అవుట్ అవ్వాలనుకుంటున్నారా?';
      case AppLanguage.hindi:   return 'क्या आप वाकई लॉग आउट करना चाहते हैं?';
      case AppLanguage.tamil:   return 'நீங்கள் உண்மையிலேயே வெளியேற விரும்புகிறீர்களா?';
    }
  }
}


// Settings, Edit Profile, Notifications, History filter strings
extension AppStringsExtra2 on AppStrings {
  // Settings
  String get settingsTitle {
    switch (language) {
      case AppLanguage.english: return 'Settings';
      case AppLanguage.telugu:  return 'సెట్టింగ్‌లు';
      case AppLanguage.hindi:   return 'सेटिंग्स';
      case AppLanguage.tamil:   return 'அமைப்புகள்';
    }
  }
  String get preferences {
    switch (language) {
      case AppLanguage.english: return 'Preferences';
      case AppLanguage.telugu:  return 'ప్రాధాన్యతలు';
      case AppLanguage.hindi:   return 'प्राथमिकताएं';
      case AppLanguage.tamil:   return 'விருப்பங்கள்';
    }
  }
  String get temperatureUnit {
    switch (language) {
      case AppLanguage.english: return 'Temperature Unit';
      case AppLanguage.telugu:  return 'ఉష్ణోగ్రత యూనిట్';
      case AppLanguage.hindi:   return 'तापमान इकाई';
      case AppLanguage.tamil:   return 'வெப்பநிலை அலகு';
    }
  }
  String get darkMode {
    switch (language) {
      case AppLanguage.english: return 'Dark Mode';
      case AppLanguage.telugu:  return 'డార్క్ మోడ్';
      case AppLanguage.hindi:   return 'डार्क मोड';
      case AppLanguage.tamil:   return 'இருண்ட பயன்முறை';
    }
  }
  String get data {
    switch (language) {
      case AppLanguage.english: return 'Data';
      case AppLanguage.telugu:  return 'డేటా';
      case AppLanguage.hindi:   return 'डेटा';
      case AppLanguage.tamil:   return 'தரவு';
    }
  }
  String get exportData {
    switch (language) {
      case AppLanguage.english: return 'Export Data';
      case AppLanguage.telugu:  return 'డేటా ఎగుమతి';
      case AppLanguage.hindi:   return 'डेटा निर्यात';
      case AppLanguage.tamil:   return 'தரவை ஏற்றுமதி செய்';
    }
  }

  // Edit Profile
  String get editProfile {
    switch (language) {
      case AppLanguage.english: return 'Edit Profile';
      case AppLanguage.telugu:  return 'ప్రొఫైల్ సవరించు';
      case AppLanguage.hindi:   return 'प्रोफ़ाइल संपादित करें';
      case AppLanguage.tamil:   return 'சுயவிவரத்தை திருத்து';
    }
  }
  String get phone {
    switch (language) {
      case AppLanguage.english: return 'Phone';
      case AppLanguage.telugu:  return 'ఫోన్';
      case AppLanguage.hindi:   return 'फ़ोन';
      case AppLanguage.tamil:   return 'தொலைபேசி';
    }
  }
  String get saveChanges {
    switch (language) {
      case AppLanguage.english: return 'Save Changes';
      case AppLanguage.telugu:  return 'మార్పులు సేవ్ చేయి';
      case AppLanguage.hindi:   return 'बदलाव सहेजें';
      case AppLanguage.tamil:   return 'மாற்றங்களை சேமி';
    }
  }
  String get cancelText {
    switch (language) {
      case AppLanguage.english: return 'Cancel';
      case AppLanguage.telugu:  return 'రద్దు';
      case AppLanguage.hindi:   return 'रद्द करें';
      case AppLanguage.tamil:   return 'ரத்து செய்';
    }
  }

  // Notifications screen
  String get realTimeAlerts {
    switch (language) {
      case AppLanguage.english: return 'Real-time Alerts';
      case AppLanguage.telugu:  return 'రియల్-టైమ్ హెచ్చరికలు';
      case AppLanguage.hindi:   return 'रियल-टाइम अलर्ट';
      case AppLanguage.tamil:   return 'நிகழ்நேர எச்சரிக்கைகள்';
    }
  }
  String get notifyInstantly {
    switch (language) {
      case AppLanguage.english: return 'Get notified instantly when air quality changes.';
      case AppLanguage.telugu:  return 'గాలి నాణ్యత మారినప్పుడు వెంటనే నోటిఫికేషన్ పొందండి.';
      case AppLanguage.hindi:   return 'वायु गुणवत्ता बदलने पर तुरंत सूचना पाएं।';
      case AppLanguage.tamil:   return 'காற்று தரம் மாறும்போது உடனடியாக அறிவிப்பு பெறுங்கள்.';
    }
  }
  String get alertTypes {
    switch (language) {
      case AppLanguage.english: return 'ALERT TYPES';
      case AppLanguage.telugu:  return 'హెచ్చరిక రకాలు';
      case AppLanguage.hindi:   return 'अलर्ट प्रकार';
      case AppLanguage.tamil:   return 'எச்சரிக்கை வகைகள்';
    }
  }
  String get statusChanges {
    switch (language) {
      case AppLanguage.english: return 'Status Changes';
      case AppLanguage.telugu:  return 'స్థితి మార్పులు';
      case AppLanguage.hindi:   return 'स्थिति परिवर्तन';
      case AppLanguage.tamil:   return 'நிலை மாற்றங்கள்';
    }
  }
  String get statusChangesDesc {
    switch (language) {
      case AppLanguage.english: return 'Safe → Moderate → Warning → Hazardous';
      case AppLanguage.telugu:  return 'సురక్షితం → మధ్యస్థం → హెచ్చరిక → ప్రమాదకరం';
      case AppLanguage.hindi:   return 'सुरक्षित → मध्यम → चेतावनी → खतरनाक';
      case AppLanguage.tamil:   return 'பாதுகாப்பு → மிதமான → எச்சரிக்கை → அபாயகரம்';
    }
  }
  String get dangerAlerts {
    switch (language) {
      case AppLanguage.english: return 'Danger Alerts';
      case AppLanguage.telugu:  return 'ప్రమాద హెచ్చరికలు';
      case AppLanguage.hindi:   return 'खतरे की अलर्ट';
      case AppLanguage.tamil:   return 'ஆபத்து எச்சரிக்கைகள்';
    }
  }
  String get dangerAlertsDesc {
    switch (language) {
      case AppLanguage.english: return 'Immediate alert for Warning & Hazardous levels';
      case AppLanguage.telugu:  return 'హెచ్చరిక & ప్రమాద స్థాయిలకు తక్షణ హెచ్చరిక';
      case AppLanguage.hindi:   return 'चेतावनी और खतरनाक स्तरों के लिए तत्काल अलर्ट';
      case AppLanguage.tamil:   return 'எச்சரிக்கை மற்றும் ஆபத்தான நிலைகளுக்கு உடனடி எச்சரிக்கை';
    }
  }
  String get analysisSaved {
    switch (language) {
      case AppLanguage.english: return 'Analysis Saved';
      case AppLanguage.telugu:  return 'విశ్లేషణ సేవ్ చేయబడింది';
      case AppLanguage.hindi:   return 'विश्लेषण सहेजा गया';
      case AppLanguage.tamil:   return 'பகுப்பாய்வு சேமிக்கப்பட்டது';
    }
  }
  String get analysisSavedDesc {
    switch (language) {
      case AppLanguage.english: return 'Confirmation when you save a reading to history';
      case AppLanguage.telugu:  return 'చరిత్రలో రీడింగ్ సేవ్ చేసినప్పుడు నిర్ధారణ';
      case AppLanguage.hindi:   return 'इतिहास में रीडिंग सहेजने पर पुष्टि';
      case AppLanguage.tamil:   return 'வரலாற்றில் வாசிப்பை சேமிக்கும்போது உறுதிப்படுத்தல்';
    }
  }
  String get liveSensorUpdates {
    switch (language) {
      case AppLanguage.english: return 'Live Sensor Updates';
      case AppLanguage.telugu:  return 'లైవ్ సెన్సార్ అప్‌డేట్‌లు';
      case AppLanguage.hindi:   return 'लाइव सेंसर अपडेट';
      case AppLanguage.tamil:   return 'நேரடி சென்சார் புதுப்பிப்புகள்';
    }
  }
  String get liveSensorUpdatesDesc {
    switch (language) {
      case AppLanguage.english: return 'Notify every 30s when sensor data refreshes';
      case AppLanguage.telugu:  return 'సెన్సార్ డేటా రిఫ్రెష్ అయినప్పుడు ప్రతి 30s నోటిఫై చేయి';
      case AppLanguage.hindi:   return 'सेंसर डेटा रिफ्रेश होने पर हर 30 सेकंड में सूचित करें';
      case AppLanguage.tamil:   return 'சென்சார் தரவு புதுப்பிக்கும்போது ஒவ்வொரு 30 வினாடியும் அறிவி';
    }
  }
  String get sendTestNotification {
    switch (language) {
      case AppLanguage.english: return 'Send Test Notification';
      case AppLanguage.telugu:  return 'పరీక్ష నోటిఫికేషన్ పంపు';
      case AppLanguage.hindi:   return 'परीक्षण अधिसूचना भेजें';
      case AppLanguage.tamil:   return 'சோதனை அறிவிப்பு அனுப்பு';
    }
  }
  String get notifFooter {
    switch (language) {
      case AppLanguage.english: return 'Notifications work even when the app is running in the background. Make sure battery optimisation is disabled for AeroSense for best results.';
      case AppLanguage.telugu:  return 'యాప్ బ్యాక్‌గ్రౌండ్‌లో రన్ అవుతున్నప్పుడు కూడా నోటిఫికేషన్‌లు పని చేస్తాయి. బెస్ట్ రిజల్ట్స్ కోసం AeroSense కి బ్యాటరీ ఆప్టిమైజేషన్ డిసేబుల్ చేయండి.';
      case AppLanguage.hindi:   return 'ऐप बैकग्राउंड में चलने पर भी नोटिफिकेशन काम करती है। सर्वोत्तम परिणामों के लिए AeroSense की बैटरी ऑप्टिमाइज़ेशन बंद करें।';
      case AppLanguage.tamil:   return 'ஆப்ஸ் பின்னணியில் இயங்கும்போதும் அறிவிப்புகள் வேலை செய்யும். சிறந்த முடிவுகளுக்கு AeroSense-ன் பேட்டரி மேம்படுத்தலை முடக்கவும்.';
    }
  }

  // History filter chips
  String get all {
    switch (language) {
      case AppLanguage.english: return 'All';
      case AppLanguage.telugu:  return 'అన్నీ';
      case AppLanguage.hindi:   return 'सभी';
      case AppLanguage.tamil:   return 'அனைத்து';
    }
  }
  String get recordsCount {
    switch (language) {
      case AppLanguage.english: return 'records';
      case AppLanguage.telugu:  return 'రికార్డులు';
      case AppLanguage.hindi:   return 'रिकॉर्ड';
      case AppLanguage.tamil:   return 'பதிவுகள்';
    }
  }
}


// Privacy & Security + Help Center + misc strings
extension AppStringsPrivacyHelp on AppStrings {
  // ── Privacy & Security screen ─────────────────────────────────
  String get privacyTitle {
    switch (language) {
      case AppLanguage.english: return 'Privacy & Security';
      case AppLanguage.telugu:  return 'గోప్యత & భద్రత';
      case AppLanguage.hindi:   return 'गोपनीयता और सुरक्षा';
      case AppLanguage.tamil:   return 'தனியுரிமை & பாதுகாப்பு';
    }
  }
  String get yourPrivacyMatters {
    switch (language) {
      case AppLanguage.english: return 'Your Privacy Matters';
      case AppLanguage.telugu:  return 'మీ గోప్యత ముఖ్యం';
      case AppLanguage.hindi:   return 'आपकी गोपनीयता महत्वपूर्ण है';
      case AppLanguage.tamil:   return 'உங்கள் தனியுரிமை முக்கியம்';
    }
  }
  String get privacyBody {
    switch (language) {
      case AppLanguage.english: return 'AeroSense is designed to run 100% locally on your device. We do not transmit your air quality data, location, or personal information to any external servers.';
      case AppLanguage.telugu:  return 'AeroSense మీ పరికరంలో 100% స్థానికంగా నడుస్తుంది. మేము మీ గాలి నాణ్యత డేటా, స్థానం లేదా వ్యక్తిగత సమాచారాన్ని ఏ బాహ్య సర్వర్‌లకు పంపించము.';
      case AppLanguage.hindi:   return 'AeroSense आपके डिवाइस पर 100% स्थानीय रूप से चलने के लिए डिज़ाइन किया गया है। हम आपकी वायु गुणवत्ता डेटा, स्थान या व्यक्तिगत जानकारी किसी भी बाहरी सर्वर पर नहीं भेजते।';
      case AppLanguage.tamil:   return 'AeroSense உங்கள் சாதனத்தில் 100% உள்ளூரில் இயங்குமாறு வடிவமைக்கப்பட்டுள்ளது. நாங்கள் உங்கள் காற்று தர தரவு, இடம் அல்லது தனிப்பட்ட தகவலை எந்த வெளிப்புற சர்வர்களுக்கும் அனுப்பமாட்டோம்.';
    }
  }
  String get localStorageTitle {
    switch (language) {
      case AppLanguage.english: return 'Local Storage';
      case AppLanguage.telugu:  return 'స్థానిక నిల్వ';
      case AppLanguage.hindi:   return 'स्थानीय संग्रहण';
      case AppLanguage.tamil:   return 'உள்ளூர் சேமிப்பகம்';
    }
  }
  String get localStorageBody {
    switch (language) {
      case AppLanguage.english: return 'All your AQI history and settings are stored locally on your device using encrypted storage algorithms. If you uninstall the app, your data will be permanently deleted.';
      case AppLanguage.telugu:  return 'మీ AQI చరిత్ర మరియు సెట్టింగ్‌లు అన్నీ ఎన్క్రిప్టెడ్ స్టోరేజ్ అల్గోరిథమ్‌లను ఉపయోగించి మీ పరికరంలో స్థానికంగా నిల్వ చేయబడతాయి. యాప్ అన్‌ఇన్‌స్టాల్ చేస్తే, మీ డేటా శాశ్వతంగా తొలగించబడుతుంది.';
      case AppLanguage.hindi:   return 'आपकी सभी AQI हिस्ट्री और सेटिंग्स एन्क्रिप्टेड स्टोरेज एल्गोरिदम का उपयोग करके आपके डिवाइस पर स्थानीय रूप से संग्रहीत हैं। यदि आप ऐप अनइंस्टॉल करते हैं, तो आपका डेटा स्थायी रूप से हटा दिया जाएगा।';
      case AppLanguage.tamil:   return 'உங்கள் AQI வரலாறு மற்றும் அமைப்புகள் அனைத்தும் குறியாக்கப்பட்ட சேமிப்பக வழிமுறைகளைப் பயன்படுத்தி உங்கள் சாதனத்தில் உள்ளூரில் சேமிக்கப்படுகின்றன. ஆப்ஸை நீக்கினால், உங்கள் தரவு நிரந்தரமாக நீக்கப்படும்.';
    }
  }
  String get authenticationTitle {
    switch (language) {
      case AppLanguage.english: return 'Authentication';
      case AppLanguage.telugu:  return 'ప్రమాణీకరణ';
      case AppLanguage.hindi:   return 'प्रमाणीकरण';
      case AppLanguage.tamil:   return 'அங்கீகாரம்';
    }
  }
  String get authenticationBody {
    switch (language) {
      case AppLanguage.english: return 'The login system is currently a mock authentication for MVP demonstration purposes. No real passwords are saved on the internet.';
      case AppLanguage.telugu:  return 'లాగిన్ సిస్టమ్ ప్రస్తుతం MVP డెమో ప్రయోజనాల కోసం నకిలీ ప్రమాణీకరణ. ఇంటర్నెట్‌లో నిజమైన పాస్‌వర్డ్‌లు సేవ్ కాలేదు.';
      case AppLanguage.hindi:   return 'लॉगिन सिस्टम वर्तमान में MVP प्रदर्शन उद्देश्यों के लिए एक नकली प्रमाणीकरण है। इंटरनेट पर कोई वास्तविक पासवर्ड सहेजे नहीं गए हैं।';
      case AppLanguage.tamil:   return 'உள்நுழைவு அமைப்பு தற்போது MVP ஆர்ப்பாட்ட நோக்கங்களுக்காக ஒரு போலி அங்கீகாரம். இணையத்தில் உண்மையான கடவுச்சொற்கள் சேமிக்கப்படவில்லை.';
    }
  }
  String get sensorPermissionsTitle {
    switch (language) {
      case AppLanguage.english: return 'Sensor Permissions';
      case AppLanguage.telugu:  return 'సెన్సార్ అనుమతులు';
      case AppLanguage.hindi:   return 'सेंसर अनुमतियां';
      case AppLanguage.tamil:   return 'சென்சார் அனுமதிகள்';
    }
  }
  String get sensorPermissionsBody {
    switch (language) {
      case AppLanguage.english: return 'If we add bluetooth or location based sensors in the future, the app will explicitly ask for your permission before accessing any hardware features.';
      case AppLanguage.telugu:  return 'భవిష్యత్తులో బ్లూటూత్ లేదా లొకేషన్ ఆధారిత సెన్సార్లు జోడిస్తే, హార్డ్‌వేర్ ఫీచర్లను యాక్సెస్ చేయడానికి ముందు యాప్ మీ అనుమతి అడుగుతుంది.';
      case AppLanguage.hindi:   return 'यदि हम भविष्य में ब्लूटूथ या स्थान आधारित सेंसर जोड़ते हैं, तो ऐप किसी भी हार्डवेयर सुविधाओं तक पहुंचने से पहले स्पष्ट रूप से आपकी अनुमति मांगेगा।';
      case AppLanguage.tamil:   return 'எதிர்காலத்தில் புளூடூத் அல்லது இருப்பிடம் அடிப்படையிலான சென்சார்களை சேர்த்தால், எந்த வன்பொருள் அம்சங்களையும் அணுகுவதற்கு முன் ஆப்ஸ் உங்கள் அனுமதியை கோரும்.';
    }
  }

  // ── Help Center screen ────────────────────────────────────────
  String get helpCenterTitle {
    switch (language) {
      case AppLanguage.english: return 'Help Center';
      case AppLanguage.telugu:  return 'సహాయ కేంద్రం';
      case AppLanguage.hindi:   return 'सहायता केंद्र';
      case AppLanguage.tamil:   return 'உதவி மையம்';
    }
  }
  String get howCanWeHelp {
    switch (language) {
      case AppLanguage.english: return 'How can we help?';
      case AppLanguage.telugu:  return 'మేము ఎలా సహాయం చేయగలం?';
      case AppLanguage.hindi:   return 'हम कैसे मदद कर सकते हैं?';
      case AppLanguage.tamil:   return 'நாங்கள் எவ்வாறு உதவலாம்?';
    }
  }
  String get faqWhatIsAqi {
    switch (language) {
      case AppLanguage.english: return 'What is AQI?';
      case AppLanguage.telugu:  return 'AQI అంటే ఏమిటి?';
      case AppLanguage.hindi:   return 'AQI क्या है?';
      case AppLanguage.tamil:   return 'AQI என்றால் என்ன?';
    }
  }
  String get faqWhatIsAqiAnswer {
    switch (language) {
      case AppLanguage.english: return 'AQI stands for Air Quality Index. It is a scale used to communicate how polluted the air currently is or how polluted it is forecast to become. Our scale ranges from 0 to 300.';
      case AppLanguage.telugu:  return 'AQI అంటే వాయు నాణ్యత సూచిక. గాలి ప్రస్తుతం ఎంత కలుషితంగా ఉందో లేదా ఎంత కలుషితం అవుతుందో తెలియజేయడానికి ఉపయోగించే స్కేల్. మా స్కేల్ 0 నుండి 300 వరకు ఉంటుంది.';
      case AppLanguage.hindi:   return 'AQI का मतलब वायु गुणवत्ता सूचकांक है। यह एक पैमाना है जो बताता है कि हवा कितनी प्रदूषित है। हमारा पैमाना 0 से 300 तक है।';
      case AppLanguage.tamil:   return 'AQI என்பது காற்று தர குறியீடு. காற்று எவ்வளவு மாசுபட்டுள்ளது என்பதை தெரிவிக்கும் அளவீடு. எங்கள் அளவீடு 0 முதல் 300 வரை உள்ளது.';
    }
  }
  String get faqHowCalculated {
    switch (language) {
      case AppLanguage.english: return 'How are my scores calculated?';
      case AppLanguage.telugu:  return 'నా స్కోర్లు ఎలా లెక్కించబడతాయి?';
      case AppLanguage.hindi:   return 'मेरे स्कोर कैसे गणना किए जाते हैं?';
      case AppLanguage.tamil:   return 'என் மதிப்பெண்கள் எவ்வாறு கணக்கிடப்படுகின்றன?';
    }
  }
  String get faqHowCalculatedAnswer {
    switch (language) {
      case AppLanguage.english: return 'Your AQI score is a combined reading of Temperature, Humidity, CO₂, and VOC. Elevated levels of CO₂ and VOC heavily impact the air quality score, while extreme temperatures and humidity act as modifiers.';
      case AppLanguage.telugu:  return 'మీ AQI స్కోర్ ఉష్ణోగ్రత, తేమ, CO₂ మరియు VOC కలిపిన రీడింగ్. CO₂ మరియు VOC అధిక స్థాయిలు గాలి నాణ్యత స్కోర్‌పై భారీ ప్రభావం చూపుతాయి.';
      case AppLanguage.hindi:   return 'आपका AQI स्कोर तापमान, आर्द्रता, CO₂ और VOC का संयुक्त पठन है। CO₂ और VOC के उच्च स्तर वायु गुणवत्ता स्कोर को भारी रूप से प्रभावित करते हैं।';
      case AppLanguage.tamil:   return 'உங்கள் AQI மதிப்பெண் வெப்பநிலை, ஈரப்பதம், CO₂ மற்றும் VOC ஆகியவற்றின் ஒருங்கிணைந்த வாசிப்பு. CO₂ மற்றும் VOC அதிக அளவுகள் காற்று தர மதிப்பெண்ணை கணிசமாக பாதிக்கின்றன.';
    }
  }
  String get faqWhatStatusMean {
    switch (language) {
      case AppLanguage.english: return 'What do the statuses mean?';
      case AppLanguage.telugu:  return 'స్థితులు ఏమిటి?';
      case AppLanguage.hindi:   return 'स्थितियों का क्या अर्थ है?';
      case AppLanguage.tamil:   return 'நிலைகள் என்ன அர்த்தம்?';
    }
  }
  String get faqWhatStatusMeanAnswer {
    switch (language) {
      case AppLanguage.english: return '• Safe (0-50): Air quality is ideal.\n• Moderate (50-100): Acceptable air quality.\n• Warning (100-150): Sensitive groups may experience effects.\n• Hazardous (150+): Health alert for everyone.';
      case AppLanguage.telugu:  return '• సురక్షితం (0-50): గాలి నాణ్యత అద్భుతం.\n• మధ్యస్థం (50-100): ఆమోదయోగ్యమైన గాలి నాణ్యత.\n• హెచ్చరిక (100-150): సున్నితమైన వ్యక్తులు ప్రభావాలను అనుభవించవచ్చు.\n• ప్రమాదకరం (150+): అందరికీ ఆరోగ్య హెచ్చరిక.';
      case AppLanguage.hindi:   return '• सुरक्षित (0-50): वायु गुणवत्ता आदर्श है।\n• मध्यम (50-100): स्वीकार्य वायु गुणवत्ता।\n• चेतावनी (100-150): संवेदनशील समूहों को प्रभाव हो सकता है।\n• खतरनाक (150+): सभी के लिए स्वास्थ्य चेतावनी।';
      case AppLanguage.tamil:   return '• பாதுகாப்பு (0-50): காற்று தரம் சிறந்தது.\n• மிதமான (50-100): ஏற்கத்தக்க காற்று தரம்.\n• எச்சரிக்கை (100-150): உணர்திறன் குழுக்கள் பாதிக்கப்படலாம்.\n• ஆபத்தான (150+): அனைவருக்கும் சுகாதார எச்சரிக்கை.';
    }
  }
  String get faqConnectSensor {
    switch (language) {
      case AppLanguage.english: return 'How do I connect a real sensor?';
      case AppLanguage.telugu:  return 'నిజమైన సెన్సార్‌ను ఎలా కనెక్ట్ చేయాలి?';
      case AppLanguage.hindi:   return 'मैं एक वास्तविक सेंसर कैसे जोड़ूं?';
      case AppLanguage.tamil:   return 'நான் உண்மையான சென்சாரை எவ்வாறு இணைப்பது?';
    }
  }
  String get faqConnectSensorAnswer {
    switch (language) {
      case AppLanguage.english: return 'This is currently an MVP demonstration using manual slider inputs for simulation. Hardware integration will be available in future releases.';
      case AppLanguage.telugu:  return 'ఇది ప్రస్తుతం సిమ్యులేషన్ కోసం మాన్యువల్ స్లయిడర్ ఇన్‌పుట్‌లను ఉపయోగించే MVP డెమో. హార్డ్‌వేర్ ఇంటిగ్రేషన్ భవిష్యత్తు విడుదలలలో అందుబాటులో ఉంటుంది.';
      case AppLanguage.hindi:   return 'यह वर्तमान में सिमुलेशन के लिए मैन्युअल स्लाइडर इनपुट का उपयोग करने वाला MVP डेमो है। हार्डवेयर एकीकरण भविष्य के रिलीज में उपलब्ध होगा।';
      case AppLanguage.tamil:   return 'இது தற்போது உருவகப்படுத்துதலுக்கு கை இழுப்பான உள்ளீடுகளை பயன்படுத்தும் MVP ஆர்ப்பாட்டம். வன்பொருள் ஒருங்கிணைப்பு எதிர்கால வெளியீடுகளில் கிடைக்கும்.';
    }
  }

  // ── Profile header ────────────────────────────────────────────
  String get addPhoneNumber {
    switch (language) {
      case AppLanguage.english: return 'Add phone number';
      case AppLanguage.telugu:  return 'ఫోన్ నంబర్ జోడించు';
      case AppLanguage.hindi:   return 'फ़ोन नंबर जोड़ें';
      case AppLanguage.tamil:   return 'தொலைபேசி எண் சேர்க்கவும்';
    }
  }

  // ── Overview panel ────────────────────────────────────────────
  String updatedAt(String time) {
    switch (language) {
      case AppLanguage.english: return 'Updated $time  •  auto 30s';
      case AppLanguage.telugu:  return 'అప్‌డేట్ అయింది $time  •  స్వయంచాలక 30s';
      case AppLanguage.hindi:   return 'अपडेट $time  •  ऑटो 30s';
      case AppLanguage.tamil:   return 'புதுப்பிக்கப்பட்டது $time  •  தானியங்கி 30s';
    }
  }
}


// Dashboard summary + live indicator strings
extension AppStringsDashboard2 on AppStrings {
  String get summary {
    switch (language) {
      case AppLanguage.english: return 'Summary';
      case AppLanguage.telugu:  return 'సారాంశం';
      case AppLanguage.hindi:   return 'सारांश';
      case AppLanguage.tamil:   return 'சுருக்கம்';
    }
  }

  String get live {
    switch (language) {
      case AppLanguage.english: return 'LIVE';
      case AppLanguage.telugu:  return 'లైవ్';
      case AppLanguage.hindi:   return 'लाइव';
      case AppLanguage.tamil:   return 'நேரடி';
    }
  }

  String get offline {
    switch (language) {
      case AppLanguage.english: return 'OFFLINE';
      case AppLanguage.telugu:  return 'ఆఫ్‌లైన్';
      case AppLanguage.hindi:   return 'ऑफलाइन';
      case AppLanguage.tamil:   return 'ஆஃப்லைன்';
    }
  }

  /// Returns the intl locale string for use with DateFormat
  String get dateLocale {
    switch (language) {
      case AppLanguage.english: return 'en';
      case AppLanguage.telugu:  return 'te';
      case AppLanguage.hindi:   return 'hi';
      case AppLanguage.tamil:   return 'ta';
    }
  }
}
