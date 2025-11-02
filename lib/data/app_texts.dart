/// English texts for the app
/// 
/// This file contains all English text strings used in the app.
/// When you add new text here, it will automatically be translated
/// to Hindi when the user clicks the globe icon.
/// 
/// How to add new text:
/// 1. Add a new entry with a unique key: "key_name": "Your English Text"
/// 2. Use it in your code: loc.getText("key_name")
/// 
/// Rules:
/// - Use descriptive, unique keys (snake_case recommended)
/// - The value is the English text that will be translated
/// - Keep entries organized by category/feature

const Map<String, String> appEnglishTexts = {
  // App Title
  "app_title": "Nyaaya Vaani",

  // Main Module Titles
  "legal_services": "Legal Services",
  "nyaaya_whistle": "Nyaaya Whistle",
  "statistics": "Statistics & Strategy",
  "youth": "Youth Association",
  "legal_library": "Legal Library",

  // Legal Services Module
  "available_advocates": "Available Advocates",
  "request_help": "Request Help",
  "add_review_for": "Add Review for",
  "cancel": "Cancel",
  "submit": "Submit",
  "review_added_for": "Review added for",
  "no_reviews_yet": "No reviews yet",
  "reviews": "Reviews:",
  "add_review": "Add Review",
  "hide_reviews": "Hide Reviews",
  "view_reviews": "View Reviews",

  // Nyaaya Whistle Module
  "submit_complaint": "Submit a Complaint",
  "complaint_submit": "Submit Complaint",
  "complaint_details": "Complaint Details",
  "complaint_submitted_successfully": "Complaint submitted successfully!",
  "selected_location": "Selected Location",
  "location_reporting": "Location Reporting (tap map to mark location)",
  "upload_image": "Upload Image",
  "upload_image_feature_coming_soon": "Upload image feature coming soon",

  // Statistics Module
  "poll_results": "Poll Results",
  "sentiment_analysis": "Sentiment Analysis",
  "ai_prediction": "AI Prediction: Public opinion likely to shift towards SUPPORT.",
  "oppose": "Oppose",
  "support": "Support",

  // Youth Association Module
  "upcoming_events": "Upcoming Events",
  "gamification": "Gamification",
  "join": "Join",
  "points": "Points",
  "badge": "Badges: Civic Star, Volunteer Hero",
  "date": "Date:",
  "signed_up_for": "Signed up for",

  // Legal Library Module
  "library_text": "A simplified repository of key Indian legal resources for awareness and learning",
  "library_search": "Search legal resources",
  "no_result": "No results found",
  "could_not_open_pdf": "Could not open pdf",

  // AI Assistant Module
  "ai_assistant": "AI Assistant",
  "typing": "Typing...",
  "type_your_question": "Type your question...",

  // User Menu & Settings
  "logout": "Logout",
  "admin_panel": "Admin Panel (placeholder)",
  "admin_features_coming_soon": "Admin features coming soon",

  // ============================================
  // ADD YOUR NEW ENGLISH TEXTS BELOW THIS LINE
  // ============================================
  // 
  // Example:
  // "welcome_message": "Welcome to Nyaaya Vaani",
  // "settings": "Settings",
  // "profile": "Profile",
  // "help": "Help",
  //
};

