import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';

class AppText {
  final AppLanguage _language;

  AppText(this._language);

  factory AppText.of(BuildContext context) {
    final language = context.watch<LanguageProvider>().language;
    return AppText(language);
  }

  static const Map<AppLanguage, Map<String, String>> _values = {
    AppLanguage.english: {
      'overview': 'Overview',
      'recent_policies': 'Recent policies',
      'recent_scam_alerts': 'Recent Scam Alerts',
      'ai_activity': 'AI activity',
      'ask_ai_assistant': 'Ask the AI assistant',
      'last_query': 'Last query 2 minutes ago',
      'open': 'Open',
      'home': 'Home',
      'scams': 'Scams',
      'profile': 'Profile',
      'fact_check': 'Fact Check',
      'active': 'Active',
      'draft': 'Draft',
      'conflict': 'Conflict',
      'review': 'Review',
      'total_policies': 'Total policies',
      'updated_this_month': 'Updated this month',
      'pending_review': 'Pending review',
      'conflicts_flagged': 'Conflicts flagged',
      'language': 'Language',
      'scam_page_title': 'Recent Scam Alerts',
      'retry': 'Retry',
      'no_scam_alerts': 'No scam alerts found.',
      'risk': 'Risk',
      'protect_yourself': 'HOW TO PROTECT YOURSELF',
      'tip_verify': 'Verify through official Govt. channels.',
      'tip_no_links': 'Never click on suspicious links in SMS/WhatsApp.',
      'tip_report': 'Report scams to 1930 (Cyber Crime Helpline).',
      'error_prefix': 'Error',
    },
    AppLanguage.hindi: {
      'overview': 'अवलोकन',
      'recent_policies': 'हाल की नीतियां',
      'recent_scam_alerts': 'हाल के घोटाला अलर्ट',
      'ai_activity': 'एआई गतिविधि',
      'ask_ai_assistant': 'एआई सहायक से पूछें',
      'last_query': 'पिछला प्रश्न 2 मिनट पहले',
      'open': 'खोलें',
      'home': 'होम',
      'scams': 'घोटाले',
      'profile': 'प्रोफाइल',
      'fact_check': 'फैक्ट चेक',
      'active': 'सक्रिय',
      'draft': 'मसौदा',
      'conflict': 'विरोध',
      'review': 'समीक्षा',
      'total_policies': 'कुल नीतियां',
      'updated_this_month': 'इस महीने अपडेट',
      'pending_review': 'लंबित समीक्षा',
      'conflicts_flagged': 'चिह्नित विरोध',
      'language': 'भाषा',
      'scam_page_title': 'हाल के घोटाला अलर्ट',
      'retry': 'पुनः प्रयास',
      'no_scam_alerts': 'कोई घोटाला अलर्ट नहीं मिला।',
      'risk': 'जोखिम',
      'protect_yourself': 'अपने आप को सुरक्षित रखें',
      'tip_verify': 'आधिकारिक सरकारी चैनलों से सत्यापित करें।',
      'tip_no_links': 'SMS/WhatsApp में संदिग्ध लिंक पर कभी क्लिक न करें।',
      'tip_report': 'घोटालों की रिपोर्ट 1930 (साइबर क्राइम हेल्पलाइन) पर करें।',
      'error_prefix': 'त्रुटि',
    },
    AppLanguage.marathi: {
      'overview': 'आढावा',
      'recent_policies': 'अलीकडील धोरणे',
      'recent_scam_alerts': 'अलीकडील फसवणूक इशारे',
      'ai_activity': 'एआय क्रियाकलाप',
      'ask_ai_assistant': 'एआय सहाय्यकाला विचारा',
      'last_query': 'शेवटचा प्रश्न 2 मिनिटांपूर्वी',
      'open': 'उघडा',
      'home': 'मुख्यपृष्ठ',
      'scams': 'फसवणूक',
      'profile': 'प्रोफाइल',
      'fact_check': 'तथ्य तपासणी',
      'active': 'सक्रिय',
      'draft': 'मसुदा',
      'conflict': 'विरोध',
      'review': 'पुनरावलोकन',
      'total_policies': 'एकूण धोरणे',
      'updated_this_month': 'या महिन्यात अद्यतनित',
      'pending_review': 'प्रलंबित पुनरावलोकन',
      'conflicts_flagged': 'चिन्हांकित विरोध',
      'language': 'भाषा',
      'scam_page_title': 'अलीकडील फसवणूक इशारे',
      'retry': 'पुन्हा प्रयत्न करा',
      'no_scam_alerts': 'फसवणुकीचे इशारे आढळले नाहीत.',
      'risk': 'जोखीम',
      'protect_yourself': 'स्वतःचे संरक्षण करा',
      'tip_verify': 'अधिकृत सरकारी माध्यमांद्वारे पडताळणी करा.',
      'tip_no_links': 'SMS/WhatsApp मधील संशयास्पद लिंकवर कधीही क्लिक करू नका.',
      'tip_report': 'फसवणुकीची तक्रार 1930 (सायबर क्राइम हेल्पलाइन) वर करा.',
      'error_prefix': 'त्रुटी',
    },
  };

  String get overview => _get('overview');
  String get recentPolicies => _get('recent_policies');
  String get recentScamAlerts => _get('recent_scam_alerts');
  String get aiActivity => _get('ai_activity');
  String get askAIAssistant => _get('ask_ai_assistant');
  String get lastQuery => _get('last_query');
  String get open => _get('open');
  String get home => _get('home');
  String get scams => _get('scams');
  String get profile => _get('profile');
  String get factCheck => _get('fact_check');
  String get active => _get('active');
  String get draft => _get('draft');
  String get conflict => _get('conflict');
  String get review => _get('review');
  String get totalPolicies => _get('total_policies');
  String get updatedThisMonth => _get('updated_this_month');
  String get pendingReview => _get('pending_review');
  String get conflictsFlagged => _get('conflicts_flagged');
  String get language => _get('language');
  String get scamPageTitle => _get('scam_page_title');
  String get retry => _get('retry');
  String get noScamAlerts => _get('no_scam_alerts');
  String get risk => _get('risk');
  String get protectYourself => _get('protect_yourself');
  String get tipVerify => _get('tip_verify');
  String get tipNoLinks => _get('tip_no_links');
  String get tipReport => _get('tip_report');
  String get errorPrefix => _get('error_prefix');

  String _get(String key) {
    final localized = _values[_language]?[key];
    if (localized != null && localized.isNotEmpty) {
      return localized;
    }
    return _values[AppLanguage.english]![key] ?? key;
  }
}
