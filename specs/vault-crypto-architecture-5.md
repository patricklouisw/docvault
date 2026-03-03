# Vault Crypto — Explain Like I'm 5

## What is DocVault?

Imagine you have a **treasure box** where you keep all your important drawings (documents). You want to keep them safe so nobody else can look at them — not even the person who built the box for you.

So you put a **secret password lock** on the box. Only you know the password. The box builder? They can hold the box for you, but they can't open it. They don't have the password.

That's DocVault. Your phone is the box. Our servers just hold it for you. They can never peek inside.

---

## The Keys — There Are Three of Them

Think of it like this:

```
YOU REMEMBER THIS
       |
       v
  Your Secret Password        "open sesame"
       |
       | (a slow, hard math puzzle turns it into...)
       v
  A Special Key (PDK)         (exists only for a moment, then poof — gone)
       |
       | (this key opens a smaller box inside...)
       v
  The REAL Key (Master Key)   (this one actually locks and unlocks your drawings)
       |
       | (each drawing has its own tiny lock)
       v
  Drawing Keys (File Keys)    (one per drawing — not built yet, coming later)
```

### Why not just use your password directly?

Because if you ever change your password, you'd have to re-lock every single drawing with the new password. That would take forever if you have 100 drawings.

Instead, your password just opens a small box that holds the **real key**. Change your password? Just put the real key in a new small box with a new lock. All your drawings stay locked the same way.

---

## The Recovery Phrase — Your Spare Key

When you first set up your treasure box, the app gives you **12 random words** like:

> apple banana cherry dolphin elephant fish grape hamster igloo jungle kite lemon

This is your **spare key**. Think of it like a spare house key you hide under a rock in the garden.

If you forget your password, you can use these 12 words to open the box instead.

**Important:** You write these words down on paper and keep them somewhere safe. The app shows them to you ONCE and then forgets them forever.

---

## What Happens When You Sign Up (First Time)

```
Step 1: Tell us your name, phone, birthday
        (just normal profile stuff)

Step 2: Pick an email and password for your account
        (this is your ACCOUNT password — for logging into Firebase)

Step 3: Pick a VAULT password (passphrase)
        (this is DIFFERENT — it's for your treasure box)

        Behind the scenes, the app:
        - Makes a brand new Real Key (Master Key) — totally random
        - Scrambles your vault password into a Special Key (PDK)
        - Uses the Special Key to LOCK the Real Key
        - Makes up 12 random words (your spare key)
        - Scrambles those words into ANOTHER Special Key
        - Uses that to ALSO lock the Real Key (a second lock)
        - Sends the locked-up Real Key to the server
          (the server can hold it but can't open it!)

Step 4: The app shows you the 12 words
        You write them down, check "I saved them", and you're in!
```

The Real Key is now in your phone's memory. You can use the app.

---

## What Happens When You Come Back (Unlock)

```
You open the app
  → App says "Hey, you're logged in, but I forgot the Real Key"
    (it always forgets when you close the app — on purpose!)
  → "Type your vault password please"

You type your vault password
  → App scrambles it into the Special Key (same math as before)
  → Uses it to UNLOCK the Real Key from the server
  → Real Key is back in memory
  → You can see your drawings again!
```

**What if you type the wrong password?**

The Special Key will be wrong. When it tries to unlock the Real Key, the lock says "NOPE, wrong key!" and the app shows "Incorrect passphrase."

---

## What Happens When You Use the Spare Key (Recovery)

This is the important one. Using the spare key is a **big deal** — it's an emergency.

### Part 1: Open the Box

```
You're on the Unlock screen
  → You tap "Use recovery phrase instead"
  → You type your 12 words
  → App scrambles the words into a Special Key
  → Uses it to UNLOCK the Real Key
  → Real Key is back in memory — your box is open!
```

### Part 2: Change the Locks (Mandatory!)

But wait — you DON'T go to the home screen yet. Why?

Think about it: if someone ELSE found your 12 words written on that paper, they could use them too. So the spare key is now "used up." We need to:

1. Put a **new lock** on the box (you pick a new vault password)
2. Make a **new spare key** (app gives you 12 new words)
3. Throw away the old lock and old spare key

```
After recovery unlock, the app sends you to:

  → "Secure Your Vault" screen (pick a NEW vault password)
     Behind the scenes:
     - The Real Key is still the SAME one (your drawings still work!)
     - But it gets wrapped in a NEW lock (new password → new Special Key)
     - App makes 12 NEW random words (new spare key)
     - The new spare key ALSO gets a lock on the Real Key
     - All the OLD lock stuff on the server is REPLACED

  → "Your Recovery Phrase" screen (12 NEW words shown)
     Write them down! The old words are now USELESS.

  → Home — you're in!
```

### Why does the Real Key stay the same?

Because all your drawings (files) are locked with the Real Key. If we made a new Real Key, we'd need to unlock every drawing with the old key and re-lock them with the new key. That's slow and complicated.

Instead, we just change the lock AROUND the Real Key. Same key inside, new box around it. All your drawings keep working perfectly.

```
BEFORE recovery:                    AFTER recovery:
┌─────────────────┐                ┌─────────────────┐
│ Old Password Lock│                │ NEW Password Lock│
│  ┌─────────────┐│                │  ┌─────────────┐│
│  │  Real Key    ││   ──────►     │  │  SAME Real   ││
│  │  (Master Key)││                │  │  Key inside! ││
│  └─────────────┘│                │  └─────────────┘│
│ Old Spare Key   │                │ NEW Spare Key    │
└─────────────────┘                └─────────────────┘

Old password: DEAD                  New password: ACTIVE
Old 12 words: DEAD                  New 12 words: ACTIVE
Your drawings: UNTOUCHED            Your drawings: UNTOUCHED
```

---

## What Happens When You Log Out

```
You tap "Log Out"
  → App ERASES the Real Key from memory (fills it with zeros)
  → Signs you out of Firebase
  → Sends you to the login screen

The Real Key is gone. It only existed in your phone's memory.
The server still has the locked-up version, but nobody can open it
without your password (or spare key).
```

---

## What Happens When the App Crashes

Same as logging out, but accidental. The Real Key was in memory, and when the app crashes, memory is cleared. Next time you open the app, you'll need to type your vault password again.

Your drawings are safe — they're still locked up on the server. You just need the password to get the Real Key back.

---

## What's Stored Where

```
ON THE SERVER (Firebase):
  ✅ Your locked-up Real Key (encrypted — useless without your password)
  ✅ The "salt" (random sprinkles that make the math unique to you)
  ✅ The settings for the math puzzle (how hard to scramble)
  ❌ NOT your password
  ❌ NOT your 12 words
  ❌ NOT the Real Key in unlocked form

ON YOUR PHONE (only while app is open):
  ✅ The Real Key (in memory — disappears when app closes)
  ❌ NOT your password (you typed it, it was used, then forgotten)
  ❌ NOT your 12 words (shown once, then forgotten)

IN YOUR BRAIN:
  ✅ Your vault password

ON YOUR PAPER (hidden somewhere safe):
  ✅ Your 12 recovery words
```

---

## What If a Bad Guy Steals the Server?

They get:
- Your locked-up Real Key (they can't open it)
- The salt (useless without your password)
- The math puzzle settings (these aren't secret)

To crack it, they'd have to guess your password and run it through a really slow math puzzle (Argon2id — uses 64MB of RAM and takes seconds per guess). If your password is good, it would take them millions of years to guess.

---

## The Whole Thing as a Story

1. **Sign up**: You build a treasure box. You pick a password for it. The app makes a Real Key, locks it with your password, makes a spare key (12 words), and sends the locked Real Key to the server.

2. **Every day use**: You type your password. The app gets the locked Real Key from the server, unlocks it with your password, and now you can see your drawings.

3. **You forget your password**: You use your 12 words to open the box. The app makes you pick a new password and gives you 12 new words. The old password and old words stop working forever.

4. **You log out**: The Real Key is erased from your phone. The server still has the locked version. Come back anytime with your password.

5. **The server gets hacked**: The hackers just get locked boxes they can't open. Your drawings are safe.

---

## Quick Reference — All the Flows

| What happened | What you do | Where you end up |
|---------------|-------------|-----------------|
| First time ever | Sign up (4 steps) | Home |
| App reopened (logged in) | Type vault password | Home |
| Forgot vault password | Type 12 recovery words | New password screen → New 12 words → Home |
| Wrong password | Try again | Stay on unlock screen |
| Wrong recovery words | Try again | Stay on unlock screen |
| Log out | Tap log out | Login screen |
| App crash | Reopen app | Vault unlock screen |

---

## Files That Make This Work

| File | What it does (in simple terms) |
|------|-------------------------------|
| `crypto_service.dart` | The math — scrambles passwords, locks/unlocks keys, picks random words |
| `vault_repository.dart` | The coordinator — tells the math what to do and saves results to the server |
| `vault_provider.dart` | The memory — remembers if the box is open or closed, holds the Real Key |
| `vault_unlock_screen.dart` | The door — where you type your password or 12 words |
| `sign_up_screen.dart` | The setup wizard — walks you through creating your box (steps 3-4 do the crypto) |
| `vault_check_screen.dart` | The bouncer — checks if you have a box before letting you in |
| `profile_screen.dart` | The exit — where you log out and the Real Key gets erased |
| `bip39_english.dart` | The dictionary — 2048 words the app picks from to make your 12-word spare key |
| `router.dart` | The traffic cop — sends you to the right screen based on what's happening |
