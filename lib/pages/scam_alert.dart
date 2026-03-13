// lib/data/scam_alerts_data.dart

const List<Map<String, dynamic>> scamAlertsData = [
  {
    "title": "Free Government 5G Mobile Recharge",
    "short_description":
        "A message claims the government is giving 3 months of free mobile recharge to all citizens to celebrate an event.",
    "why_it_is_fake":
        "The government does not provide free mobile recharges. The link in the message leads to a phishing site designed to secretly install malware and steal your personal data.",
    "how_to_stay_safe":
        "Never click on suspicious links offering free recharges. Verify any government scheme on the official MyGov website.",
    "scam_type": "WhatsApp Forward Misinformation",
    "risk_level": "High",
    "platform_spread": "WhatsApp",
  },
  {
    "title": "Account Blocked: Bank KYC PAN Update",
    "short_description":
        "An urgent SMS warns that your bank account will be blocked today if you don't click a link to update your PAN card.",
    "why_it_is_fake":
        "Banks never send SMS alerts with links to update KYC. The link opens a fake banking login page to steal your username, password, and OTP.",
    "how_to_stay_safe":
        "Do not click the link or call the sender's number. Use your official banking app or visit the nearest bank branch to check your KYC status.",
    "scam_type": "Bank KYC Scam",
    "risk_level": "High",
    "platform_spread": "SMS",
  },
  {
    "title": "Part-Time Job Liking YouTube Videos",
    "short_description":
        "Scammers offer easy daily earnings of ₹2,000 to ₹5,000 just for liking YouTube videos or providing Google Maps reviews.",
    "why_it_is_fake":
        "They pay a small amount initially to gain your trust. Later, they add you to VIP tasks where you must invest your own money to unlock bigger rewards, and then they disappear.",
    "how_to_stay_safe":
        "Ignore unexpected job offers that require zero skills or ask you to pay money to get paid. Report the numbers to the cyber crime portal.",
    "scam_type": "Fake Job Offers",
    "risk_level": "High",
    "platform_spread": "Telegram",
  },
  {
    "title": "Urgent Electricity Power Cut Notice",
    "short_description":
        "An SMS claims your electricity will be disconnected tonight at 9:30 PM because your previous bill was not updated.",
    "why_it_is_fake":
        "Official electricity boards always send notices from registered sender IDs, not from personal 10-digit mobile numbers. They want you to call them and download a screen-sharing app to steal your OTP.",
    "how_to_stay_safe":
        "Never download any remote access apps like AnyDesk. Verify your actual bill status on the official app of your state's electricity board.",
    "scam_type": "OTP Fraud",
    "risk_level": "High",
    "platform_spread": "SMS",
  },
  {
    "title": "Guaranteed Double Returns Crypto scheme",
    "short_description":
        "A social media page claims to double your investment in 24 hours through secret stock trading or crypto mining.",
    "why_it_is_fake":
        "No genuine investment can offer guaranteed returns so quickly. Once you transfer the money, the scammers show fake profit dashboards and demand more money for withdrawal fees before blocking you.",
    "how_to_stay_safe":
        "Only invest your money through SEBI-registered brokers and official platforms. Do not trust screenshots of huge profits on social media.",
    "scam_type": "Fake Investment Scheme",
    "risk_level": "High",
    "platform_spread": "Instagram",
  },
];
