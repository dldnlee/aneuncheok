# 아는척

A Flutter app that teaches everyday common sense in short, swipeable cards —
built to be fun enough to open every day.

## What's in it

- **Swipe feed** of 240+ cards in 10 categories, with a "몰랐어요! / 알고 있었어요" reaction on every card.
- **Progression:** XP, 11 levels, a daily goal, a daily streak, category mastery bonuses and 28 badges. A level "journey" and badge wall live on the profile tab.
- **Review mode (spaced repetition):** a card you mark "몰랐어요" comes back after 1, 3, 7, 14 and then 30 days. You see the title first, try to recall it, tap to reveal, and rate it "기억나요" (moves up a step, earns XP) or "헷갈려요" (back to day 1). After the last step the card graduates. At most 20 cards per session. Cards you marked "알고 있었어요" are never reviewed.
- **Quiz challenge (replayable):** "which topic is this explanation about?" — the card's explanation with its own title hidden, and four look-alike titles from the same category to choose from. Built from the cards you have learned (cards you marked "몰랐어요" come up more often), 10 questions and 3 hearts per round, with a combo bonus. Right answers pay XP (capped at 100 a day so it can't be ground); wrong answers cost a heart and send the card to review. Unlocks after 5 learned cards.
- **Social:** an anonymous profile, friend codes, weekly friend and global leaderboards, and head-to-head comparison.

## Adding cards

Cards live in one file per category under `lib/data/cards/`. To add one, append a
`KnowledgeItem` to the matching list with the next free id for that category
(e.g. `d31`). A new category needs an entry in `categories`
(`lib/data/dummy_data.dart`), a new file in `cards/`, and an id prefix of its own.

- **Never rename or delete an existing id.** Saved progress points at ids.
- Keep titles short and bodies to a sentence or two. Only add facts you can
  verify; many readers are teenagers, so be careful with health, safety, money
  and legal claims, and mention a source in `source:` when you have one.
- `flutter test test/knowledge_data_test.dart` checks ids, categories, length
  limits and duplicates for every card.

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
