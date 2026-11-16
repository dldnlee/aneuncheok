# 아는척

A Flutter app that teaches everyday common sense in short, swipeable cards —
built to be fun enough to open every day.

## What's in it

- **Swipe feed** of 65 cards in 6 categories, with a "몰랐어요! / 알고 있었어요" reaction on every card.
- **Progression:** XP, 8 levels, a daily goal, a daily streak, category mastery bonuses and 17 badges. A level "journey" and badge wall live on the profile tab.
- **Social:** an anonymous profile, friend codes, weekly friend and global leaderboards, and head-to-head comparison.

## Run and test

```sh
flutter pub get
flutter run          # or: flutter run -d chrome
flutter test
```

## Social features are in demo mode

There is no backend yet. Friends and the global board come from
`DemoSocialRepository`, which simulates 30 players and is labeled as a demo
in the UI. Everything else (identity, friend codes, ranking, comparison)
is real client code.

To go live, implement `SocialRepository` (`lib/social/social_repository.dart`)
against a backend such as Firebase or Supabase and pass it to `SocialStore`
in `lib/main.dart`. The UI does not need to change:

| Method | What the backend needs to do |
| --- | --- |
| `publish(me)` | Store my public stats under my friend code |
| `friends()` | Return the current stats of the codes I added |
| `globalBoard(me)` | Return the top players this week and how many are ahead of me |
| `addFriend` / `removeFriend` | Manage my friend list |

Set `isDemo` to `false` and the demo banner disappears.

### Safety by design

The app is aimed at young people, so players never type free text: a nickname
is a word from a fixed list plus an animal, and the only thing others see is
that nickname, an emoji avatar and game stats. Keep it that way when adding a
backend, and validate on the server too.

## Layout

```
lib/
  data/      dummy cards and categories
  models/    Category, KnowledgeItem
  state/     ProgressStore (XP, streaks, badges), badge catalog
  social/    identity, friend codes, repository interface + demo, SocialStore
  screens/   home, feed, ranking, profile, tab shell
  widgets/   animations, confetti, shared bits
```
