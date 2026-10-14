import '../core/types.dart';

/// Hinglish (default) and English strings. `{name}` placeholders are filled by [Tr.call].
/// A missing English string falls back to Hinglish so a UI never shows a raw key twice wrong.
class Tr {
  const Tr(this.lang);
  final Lang lang;

  String call(String key, [Map<String, Object> args = const {}]) {
    final e = _t[key];
    var s = e == null
        ? key
        : (lang == Lang.english ? (e.length > 1 ? e[1] : e[0]) : e[0]);
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  static const _t = <String, List<String>>{
    'tagline': [
      'Zaroori notifications, sabse upar.',
      'Only what matters, at the top.',
    ],
    // splash
    'splash_sub': [
      'Aapka summary tayyar ho raha hai',
      'Getting your summary ready',
    ],
    'step1': ['Apps jaanch rahe hain', 'Checking your apps'],
    'step2': ['Zaroori chun rahe hain', 'Picking what matters'],
    'step3': ['Summary ban raha hai', 'Building your summary'],
    // tips
    'tips_title': ['3 tips, phir shuru', '3 tips, then start'],
    'tip1_t': ['Zaroori apps chuno', 'Choose important apps'],
    'tip1_d': [
      'Sirf wahi apps upar dikhenge jo aap chunoge.',
      'Only the apps you pick show at the top.',
    ],
    'tip2_t': ['Lock screen par summary', 'Summary on your lock screen'],
    'tip2_d': [
      'Subah ek chhota summary, bina phone khole.',
      'A short summary each morning, no unlocking.',
    ],
    'tip3_t': ['Tap karo, kaam karo', 'Tap and act'],
    'tip3_d': [
      'Reply, Pay, Track: ek tap mein sahi app khulega.',
      'Reply, Pay, Track: one tap opens the right app.',
    ],
    'privacy_line': [
      'Sab kuch aapke phone par rehta hai. Kuch bhi upload nahi hota.',
      'Everything stays on your phone. Nothing is uploaded.',
    ],
    'btn_access': ['Notification access do', 'Give notification access'],
    'later': ['Baad mein', 'Later'],
    'access_why': [
      'Dholu aapke notifications sirf phone par padhta hai taaki zaroori wale upar la sake. Agle page par Dholu ko chalu karo.',
      'Dholu reads your notifications only on this phone to bring the important ones up. Turn Dholu on in the next page.',
    ],
    // home
    'home_title': ['Aaj ke zaroori updates', "Today's important updates"],
    'home_count': ['{n} zaroori, {m} chhupe', '{n} important, {m} hidden'],
    'hidden_title': ['Baaki {n} chhupe hain', '{n} more are hidden'],
    'hidden_sub': ['Kuch miss nahi hoga.', "You won't miss anything."],
    'see_all': ['Sab dekho', 'See all'],
    'empty_title': ['Abhi sab shaant hai', 'All quiet right now'],
    'empty_sub': [
      'Zaroori kuch aayega to Dholu bata dega.',
      'Dholu will tell you when something important arrives.',
    ],
    'access_banner': [
      'Notification access band hai. Chalu karo taaki summary ban sake.',
      'Notification access is off. Turn it on to build your summary.',
    ],
    'turn_on': ['Chalu karo', 'Turn on'],
    'opens_in': ['{app} mein khulega', 'Opens in {app}'],
    'urgent_tag': ['ZAROORI', 'URGENT'],
    'a_reply': ['Reply karo', 'Reply'],
    'a_pay': ['Pay now', 'Pay now'],
    'a_track': ['Track karo', 'Track'],
    'a_open': ['Kholo', 'Open'],
    // notifications
    'digest_title': ['{n} zaroori updates', '{n} important updates'],
    'digest_title_1': ['1 zaroori update', '1 important update'],
    'digest_hidden': ['+{n} chhupe hue', '+{n} hidden'],
    'digest_tap': ['Dekhne ke liye tap karo', 'Tap to view'],
    'digest_none': [
      'Aaj koi zaroori update nahi',
      'No important updates today',
    ],
    'urgent_title': ['Zaroori update', 'Urgent update'],
    'urgent_hidden_body': ['Dekhne ke liye Dholu kholo', 'Open Dholu to view'],
    'notif_later': ['Baad mein', 'Later'],
    'remind_title': ['Yaad dilana tha', 'Reminder'],
    'ch_digest': ['Subah ka summary', 'Morning summary'],
    'ch_urgent': ['Zaroori alerts', 'Urgent alerts'],
    'ch_urgent_quiet': [
      'Zaroori alerts (bina awaaz)',
      'Urgent alerts (silent)',
    ],
    'ch_reminder': ['Reminders', 'Reminders'],
    // apps
    'apps_title': ['Kaun se apps zaroori hain?', 'Which apps matter?'],
    'apps_selected': ['{n} apps chune gaye', '{n} apps selected'],
    'apps_footer': ['Baaki apps chhupe rahenge', 'Other apps stay hidden'],
    'done': ['Ho gaya', 'Done'],
    'search_apps': ['App dhundo', 'Search apps'],
    'no_apps': ['Koi app nahi mila', 'No apps found'],
    // drum alert
    'choose_right': ['Sahi kaam chuno', 'Pick the right action'],
    'dholu_pick': ['Dholu ki pasand', "Dholu's pick"],
    'remind10': ['10 min baad yaad dilao', 'Remind me in 10 min'],
    'skip': ['Chhodo', 'Skip'],
    'drumroll': ['Drum roll...', 'Drum roll...'],
    'right_choice': ['Sahi chuna!', 'Great choice!'],
    'see_draft': ['Draft dekho', 'See draft'],
    'go_home': ['Home par jao', 'Go home'],
    'reminder_set': [
      'Theek hai, 10 minute baad yaad dilayenge.',
      "Okay, I'll remind you in 10 minutes.",
    ],
    // draft
    'draft_title': ['Reply draft', 'Reply draft'],
    'their_msg': ['{name} ne likha', '{name} wrote'],
    'dholu_draft': ['Dholu ka draft', "Dholu's draft"],
    'tone_short': ['Chhota', 'Shorter'],
    'tone_formal': ['Formal', 'Formal'],
    'tone_english': ['English', 'English'],
    'send_note': ['Bhejna aapke haath mein hai', 'Sending is up to you'],
    'open_in_app': ['{app} mein kholo', 'Open in {app}'],
    'pasted': ['Draft copy ho gaya. Paste karo.', 'Draft copied. Paste it.'],
    'drafting': ['Draft likh raha hai', 'Writing draft'],
    'quick_replies': ['Quick replies', 'Quick replies'],
    'qr1': ['Theek hai, dekhta hoon.', 'Okay, I will check.'],
    'qr2': [
      'Abhi busy hoon, thodi der mein batata hoon.',
      "I'm busy right now, will get back soon.",
    ],
    'qr3': ['Ho jayega, chinta mat karo.', "Consider it done, don't worry."],
    'qr4': ['Dhanyavaad!', 'Thank you!'],
    'no_ai_hint': [
      'AI model chalu nahi hai. Settings mein jaake chalu karo, ya quick replies use karo.',
      'No AI model is on. Turn one on in Settings, or use quick replies.',
    ],
    'edit_draft': ['Draft badlo', 'Edit draft'],
    // assistant
    'assistant_title': ['Dholu se baat karo', 'Talk to Dholu'],
    'ask_hint': ['Kuch poochho...', 'Ask anything...'],
    'web_chip': ['Web search', 'Web search'],
    'searching': ['Web par dhundh raha hoon: {q}', 'Searching the web: {q}'],
    'sources': ['Sources', 'Sources'],
    'need_model': [
      'Pehle Settings mein AI model chalu karo.',
      'Turn on an AI model in Settings first.',
    ],
    'go_settings': ['Settings kholo', 'Open Settings'],
    'assistant_intro': [
      'Namaste! Main Dholu hoon. Email likhwao, jawab socho, ya kuch bhi poochho.',
      "Hi! I'm Dholu. Ask me to write an email, think of a reply, or ask anything.",
    ],
    'write_email': ['Email banao', 'Write an email'],
    'thinking': ['Soch raha hai...', 'Thinking...'],
    'model_loading': ['Model load ho raha hai...', 'Loading model...'],
    'stop': ['Roko', 'Stop'],
    'new_chat': ['Nayi baat', 'New chat'],
    // email
    'email_title': ['Email banao', 'Write an email'],
    'email_to': ['Kisko (naam ya email)', 'To (name or email)'],
    'email_say': ['Kya likhna hai?', 'What should it say?'],
    'email_say_hint': [
      'Jaise: Anil sir ko bolo report kal tak bhej dunga',
      'e.g. Tell Anil sir I will send the report by tomorrow',
    ],
    'use_context': ['Messages ka context lo', 'Use message context'],
    'context_from': ['Is sender ke messages', "Messages from this sender"],
    'generate': ['Draft banao', 'Draft it'],
    'subject': ['Subject', 'Subject'],
    'body': ['Email', 'Email'],
    'open_mail': ['Email app mein kholo', 'Open in email app'],
    'copy': ['Copy karo', 'Copy'],
    'copied': ['Copy ho gaya', 'Copied'],
    'consent_title': [
      'Cloud model ko messages bhejne hain?',
      'Send messages to the cloud model?',
    ],
    'consent_body': [
      'Ye draft cloud model se banega, isliye chune hue messages aapke diye hue cloud provider ko jayenge. Phone ke AI model se banane ke liye Settings mein usse chalu karo.',
      'This draft is made by a cloud model, so the selected messages go to your cloud provider. To keep it on the phone, turn on an on-device model in Settings.',
    ],
    'send_anyway': ['Bhejo', 'Send'],
    'mail_note': [
      'Email aapke email app mein khulegi. Bhejna aapke haath mein hai.',
      'The email opens in your email app. Sending is up to you.',
    ],
    // settings
    'settings_title': ['Settings', 'Settings'],
    'language': ['Bhasha', 'Language'],
    'lang_hi': ['Hinglish', 'Hinglish'],
    'lang_en': ['English', 'English'],
    'sec_notif': ['Notifications', 'Notifications'],
    'summary_on': ['Subah ka summary', 'Morning summary'],
    'summary_time': ['Summary ka time', 'Summary time'],
    'drum_sound': ['Dhol ki awaaz', 'Drum sound'],
    'drum_sound_sub': [
      'Sirf zaroori items par, silent mode mein nahi',
      'Only for urgent items, never in silent mode',
    ],
    'lock_detail': [
      'Lock screen par detail dikhao',
      'Show detail on lock screen',
    ],
    'lock_detail_sub': [
      'Band rahe to sirf ginti dikhegi',
      'When off, only a count shows',
    ],
    'sec_apps': ['Apps', 'Apps'],
    'choose_apps': ['Zaroori apps chuno', 'Choose important apps'],
    'sec_ai': ['AI model (phone par)', 'AI model (on your phone)'],
    'ai_intro': [
      'Model aapke phone par chalta hai. Download ke baad internet nahi chahiye.',
      'The model runs on your phone. No internet needed after the download.',
    ],
    'ai_classify': ['AI se classify karo', 'Use AI to sort notifications'],
    'ai_classify_sub': [
      'Sirf unke liye jo rules se pakke nahi hote',
      'Only for the ones the rules are unsure about',
    ],
    'wifi_only': ['Sirf Wi-Fi par download', 'Download on Wi-Fi only'],
    'for_phone': ['Aapke phone ke liye', 'For your phone'],
    'rules_only': ['Sirf rules (bina AI)', 'Rules only (no AI)'],
    'rules_only_sub': [
      'Sabse halka. Kisi phone par chalega.',
      'Lightest. Works on any phone.',
    ],
    'download': ['Download', 'Download'],
    'pause': ['Rok do', 'Pause'],
    'resume': ['Jaari rakho', 'Resume'],
    'delete': ['Delete', 'Delete'],
    'cancel': ['Cancel', 'Cancel'],
    'retry': ['Dobara koshish', 'Retry'],
    'use_this': ['Ye use karo', 'Use this'],
    'in_use': ['Use mein', 'In use'],
    'ready': ['Taiyaar', 'Ready'],
    'verifying': ['Jaanch ho rahi hai...', 'Verifying...'],
    'checking_size': ['Size check ho raha hai...', 'Checking size...'],
    'custom_model': ['Apna GGUF model (URL)', 'Your own GGUF model (URL)'],
    'phone_specs': [
      '{ram} GB RAM, {storage} GB khaali',
      '{ram} GB RAM, {storage} GB free',
    ],
    'sec_web': ['Web search', 'Web search'],
    'web_enable': ['Web search chalu karo', 'Enable web search'],
    'web_enable_sub': [
      'Sirf aapke sawaal bheje jaate hain, notifications nahi',
      'Only your own questions are sent, never notifications',
    ],
    'provider': ['Search provider', 'Search provider'],
    'searx_url': [
      'SearXNG address (https://...)',
      'SearXNG address (https://...)',
    ],
    'brave_key': ['Brave API key', 'Brave API key'],
    'sec_cloud': ['Cloud model (optional)', 'Cloud model (optional)'],
    'cloud_enable': [
      'Apni API key se cloud model',
      'Cloud model with your API key',
    ],
    'cloud_note': [
      'Notifications kabhi cloud nahi jaate. Sirf aapke chat/email mein diye messages (aapki ijazat ke baad). Free tier data training ke liye use kar sakte hain.',
      'Notifications never go to the cloud. Only what you write in chat/email (with your OK). Free tiers may use data for training.',
    ],
    'base_url': ['Base URL', 'Base URL'],
    'model_name': ['Model', 'Model'],
    'api_key': ['API key', 'API key'],
    'saved': ['Save ho gaya', 'Saved'],
    'sec_privacy': ['Privacy', 'Privacy'],
    'what_knows': ['Dholu kya jaanta hai', 'What Dholu knows'],
    'sec_perms': ['Permissions', 'Permissions'],
    'access_status': ['Notification access', 'Notification access'],
    'on': ['Chalu', 'On'],
    'off': ['Band', 'Off'],
    'battery': ['Battery limit hatao', 'Remove battery limit'],
    'battery_sub': [
      'Kuch phones Dholu ko band kar dete hain. Isse notifications miss nahi honge.',
      'Some phones stop Dholu in the background. This keeps notifications flowing.',
    ],
    'open': ['Kholo', 'Open'],
    // data
    'data_title': ['Dholu kya jaanta hai', 'What Dholu knows'],
    'data_intro': [
      'Ye sab sirf aapke phone par hai. {n} notifications, 7 din baad apne aap delete.',
      'All of this is only on your phone. {n} notifications, auto-deleted after 7 days.',
    ],
    'data_no_otp': [
      'OTP, password aur bank messages kabhi save nahi hote.',
      'OTPs, passwords and bank messages are never saved.',
    ],
    'delete_all': ['Sab delete karo', 'Delete everything'],
    'delete_confirm': [
      'Saare saved notifications aur seekha hua data delete ho jayega.',
      'All saved notifications and learned data will be deleted.',
    ],
    'deleted': ['Delete ho gaya', 'Deleted'],
    'no_data': ['Abhi kuch saved nahi hai', 'Nothing saved yet'],
    'muted_label': ['chhupa', 'hidden'],
    // misc
    'error_generic': [
      'Kuch gadbad hui. Dobara koshish karo.',
      'Something went wrong. Please try again.',
    ],
    'close': ['Band karo', 'Close'],
    'ok': ['Theek hai', 'OK'],
    'tab_home': ['Home', 'Home'],
    'tab_talk': ['Dholu', 'Dholu'],
    'tab_settings': ['Settings', 'Settings'],
  };

  static Set<String> get keys => _t.keys.toSet();
}
