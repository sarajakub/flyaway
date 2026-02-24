# FlyAway - Healing Journey App

A mindful iOS app for emotional healing and personal growth. Write your thoughts, track your emotions, and connect with others on their healing journey through supportive community features.

## Screenshots

<div align="center">
  <img width="240" height="524" alt="create-thought-020525" src="https://github.com/user-attachments/assets/da0a210b-3702-4cb4-90d7-31e4c4111b82">
  <br>
  <sub>Create and release your thoughts with customizable categories and expiration options</sub>
</div>

## Features

### 💭 Thought Expression
- **Write or Vocalize**: Express your thoughts through text or voice
- **Anonymous Posting**: Share publicly while maintaining privacy
- **Categorization**: Organize by Breakup, Grief, Anxiety, Healing, Gratitude, Reflection
- **Flexible Storage Options**:
  - Send to Ether (disappear immediately)
  - Temporary (1, 7, 30, or 90 days)
  - Permanent (keep forever)
  - Public or private visibility

### 🌱 Emotion Tracking
- **Daily Mood Check-in**: Track how you're feeling with a 5-point scale (😢 😔 😐 🙂 😊)
- **Contextual Notes**: Add notes to explain your emotional state
- **Visual Analytics**: 
  - Line graph showing mood trends over time
  - Period selector (Week, Month, 3 Months, Year)
  - Average mood calculation
  - Trend analysis (Improving/Declining/Stable)
- **History View**: Review past check-ins with your notes

### 👥 Community Support
- **Public Feed**: Browse thoughts from others on similar healing journeys
- **Smart Sorting**:
  - Recent: Latest thoughts first
  - Most Saved: Popular thoughts
  - For You: Personalized based on your active categories
- **Supportive Reactions**: Respond with healing-themed emojis
  - 💜 Support
  - 🌟 Inspiring
  - 🕊️ Peaceful
  - 🌱 Growth
- **Save Thoughts**: Bookmark meaningful thoughts for later
- **Category Filtering**: Focus on specific topics

### 📊 My Journey Analytics
- **Activity Dashboard**: Track your healing progress
  - Total thoughts created
  - Period-based statistics (Week/Month/Year/All Time)
  - Created, deleted, and expired thought counts
  - Active thought count
- **Daily Activity Visualization**: Bar chart showing thought creation patterns
- **Category Breakdown**: See which topics you engage with most
- **Milestone Tracking**: Mark important dates and track days since events

### 🆘 Help & Support
- **Crisis Resources**: 
  - 988 Suicide & Crisis Lifeline (call/text)
  - Crisis Text Line (text HOME to 741741)
  - SAMHSA National Helpline
- **How-To Guides**: Learn to use all features
- **Privacy & Safety**: Information about data protection
- **Feedback System**: Submit suggestions and report issues

### 🧘 Mindfulness Resources
- **Meditation**: Guided meditations for healing
- **Breathwork**: Breathing exercises for anxiety and stress
- **Journaling**: Prompts and guidance
- **Affirmations**: Positive affirmations for healing

## Design Philosophy

FlyAway is designed as a **healing tool, not a social network**. Features focus on:
- ✅ Personal growth and emotional processing
- ✅ Supportive community without comparison
- ✅ Mindful expression and reflection
- ❌ No follower counts or vanity metrics
- ❌ No endless scrolling or engagement optimization
- ❌ No productivity pressure (habits, streaks, checklists)

## Tech Stack

- **SwiftUI**: Modern declarative UI framework
- **Firebase**: Backend services
  - Authentication: User management
  - Firestore: Database (thoughts, moods, milestones, reactions)
  - Storage: Audio files
- **Charts**: Native SwiftUI charts for mood visualization
- **AVFoundation**: Audio recording and playback

## Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- CocoaPods
- Firebase account

### Installation

1. Clone the repository
```bash
cd flyaway
```

2. Install dependencies
```bash
pod install
```

3. Open the workspace
```bash
open FlyAway.xcworkspace
```

4. Configure Firebase
   - Create a new Firebase project at https://console.firebase.google.com
   - Add an iOS app to your Firebase project
   - Download `GoogleService-Info.plist`
   - Add the file to your Xcode project

5. Build and run the app

## Project Structure

```
FlyAway/
├── Models/
│   ├── Thought.swift
│   ├── User.swift
│   └── MindfulnessResource.swift
├── Services/
│   ├── AuthenticationManager.swift
│   └── ThoughtManager.swift
├── Views/
│   ├── Authentication/
│   │   └── AuthenticationView.swift
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── ThoughtCard.swift
│   ├── Create/
│   │   └── CreateThoughtView.swift
│   ├── Community/
│   │   └── CommunityView.swift
│   ├── Mindfulness/
│   │   ├── MindfulnessView.swift
│   │   └── MindfulnessDetailView.swift
│   └── Profile/
│       └── ProfileView.swift
├── FlyAwayApp.swift
└── ContentView.swift
```

## Usage

### Creating a Thought
1. Tap the "Create" tab
2. Write your thought or use voice input
3. Select a category
4. Choose visibility (public/private)
5. Decide to send to ether or keep for a duration
6. Release your thought

### Browsing Community
1. Navigate to "Community" tab
2. Filter by category
3. Search for specific topics
4. Save thoughts that resonate with you

### Mindfulness Practice
1. Go to "Mindfulness" tab
2. Choose a resource type
3. Select a practice
4. Follow the guided session

## Future Enhancements

- [ ] Voice recording and playback
- [ ] Push notifications for thought expiration
- [ ] Analytics and insights dashboard
- [ ] Custom meditation creation
- [ ] Chat/messaging between users
- [ ] Badges and achievements
- [ ] Dark mode optimization
- [ ] Offline mode support
- [ ] Export thoughts as PDF/journal

## Contributing

This is a personal project, but suggestions and feedback are welcome!

## License

Private - All rights reserved

## Privacy

FlyAway takes privacy seriously. Thoughts marked as "Send to Ether" are automatically deleted and cannot be recovered. Public thoughts are visible to all users. Private thoughts are only visible to you.

## Support

For support or questions, please contact the developer.

---

Built with ❤️ for healing and growth
