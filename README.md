# Bent Tree Tone Lab (pedal_apps)

Explore, save and recall settings for guitar and bass pedals and amps. Grew out of the
**Fraggles EQ** app on [lrrecords.com.au/fraggles-eq](https://lrrecords.com.au/fraggles-eq).

One self-contained `index.html`. No build step, no framework. Paste it into an
EasyFunnels Custom HTML element, or host it on Cloudflare Pages.

## What's in it

**Pedals**
| App id | Gear | Controls |
|---|---|---|
| `fraggles-eq` | MXR M108S 10-band EQ (the original Fraggles EQ) | 10 bands ±12 dB, Volume, Gain |
| `proco-rat` | Pro Co RAT 2 | Distortion, Filter, Volume |
| `ehx-bass-micro-synth` | Electro-Harmonix Bass Micro Synthesizer | Trig, Sub Oct, Guitar, Octave, Square, Attack Delay, Start/Stop Freq, Rate, Resonance |
| `digitech-bass-multi-chorus` | DigiTech Bass Multi Chorus | Level, Speed, Depth, Voice |
| `ibanez-ts9` | Ibanez TS9 Tube Screamer | Overdrive, Tone, Level |
| `ehx-big-muff` | Electro-Harmonix Big Muff Pi | Volume, Tone, Sustain |
| `mxr-dyna-comp` | MXR M102 Dyna Comp | Output, Sensitivity |
| `boss-ds1` | Boss DS-1 Distortion | Tone, Level, Dist |

**Amps**
| App id | Gear | Controls |
|---|---|---|
| `darkglass-ao900` | Darkglass Alpha·Omega 900 | Passive/Active, Engine on/off, Comp, Drive, Level, Blend, Alpha/Omega, Bite, Growl, Gain, Bass 80 / 250 / 500 / 1.5k / 3k / Treble 5k, Master |

Every device has 5–8 factory presets ("Tone Lab presets"). These are our own starting points, not manufacturer settings.

**Features**
- Knobs: drag up/down, arrow keys, or double-click to reset. Each one shows a value and a clock position ("2:30").
- Users save their own presets per device, next to the factory ones.
- Logins (email + password, magic link, password reset) through Supabase. Each user's presets follow them to any device.
- Without logins, presets save in the browser. When someone signs in, they get an offer to copy those browser presets into their account.
- Old Fraggles EQ presets (`fraggles_eq_user` in localStorage) are carried over automatically.
- A feedback and gear-request form that writes to Supabase, with a honeypot field and a 30-second cooldown against spam.
- "Copy settings" copies the current settings as text for forums and socials.
- Deep links: `…/page#proco-rat` opens straight to the RAT.

## Setup (one time, ~10 minutes)

1. **Supabase project.** Use an existing project (Artist-Pages is fine, because all tables are prefixed `tone_lab_`) or create a free one.
2. **Run the schema.** In the SQL Editor, paste `supabase/schema.sql` and click Run.
3. **Auth settings.** Go to Authentication › URL Configuration:
   - Site URL: the page the app lives on, e.g. `https://lrrecords.com.au/tone-lab`
   - Redirect URLs: add that same URL. Confirmation, magic-link and reset emails send people back there.
4. **Keys.** In Project Settings › API, copy the Project URL and the `anon` public key into `CONFIG` near the top of the `<script>` in `index.html`:
   ```js
   var CONFIG = {
     SUPABASE_URL: 'https://xxxx.supabase.co',
     SUPABASE_ANON_KEY: 'eyJ...',
     REDIRECT_URL: 'https://lrrecords.com.au/tone-lab'
   };
   ```
   The anon key is safe to publish. Row Level Security stops anyone reading or changing another user's presets, and nobody can read feedback through the public API.
5. **Embed.** Copy everything from `<div id="btlab">` to its closing `</div>` (it includes the `<style>` and `<script>`) into an EasyFunnels Custom HTML element. All styles are scoped to `#btlab`, so they won't restyle the rest of the page.

## Reading feedback

Use Supabase › Table Editor › `tone_lab_feedback`. Set `status` to `planned`, `done` or `declined` as you work through it.
The view `tone_lab_request_tally` ranks requested gear by count.

Optional: point a Supabase Database Webhook (on insert to `tone_lab_feedback`) at an n8n workflow that pings ntfy.

## Adding a pedal or amp

Add one object to the `DEVICES` array in `index.html`. The helpers make it short:

```js
{
  id: 'boss-bd2', kind: 'pedal', name: 'BLUES DRIVER', maker: 'Boss', model: 'BD-2 Blues Driver',
  category: 'Overdrive', inst: ['guitar'], acc: '#3b7bff',
  tag: 'OVERDRIVE // BD-2 STYLE',
  notes: 'Short player-facing tip.',
  groups: [{ title: 'CONTROLS', controls: [K('level','LEVEL',5), K('tone','TONE',5), K('gain','GAIN',5)] }],
  presets: [{ n: 'Edge of Breakup', v: { level: 6, tone: 5, gain: 3 } }]
}
```
- `K(id, label, default)` is a 0–10 knob
- `N(id, label, default)` is a 0–10 vertical slider
- `DB(id, label, range)` is a ±range dB fader
- `SW(id, label, ['A','B'], default)` is a switch

Never rename a control `id` or device `id` after release. Saved presets refer to them.

## Legal

Product names are trademarks of their owners and are used only to say which gear the settings are for.
The app draws its own generic enclosures and doesn't copy any manufacturer artwork. It isn't affiliated with any manufacturer.
