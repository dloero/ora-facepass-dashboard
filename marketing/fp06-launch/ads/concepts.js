/* Ora FacePass FP06 launch — static ad concepts.
   Shared by the render template, the creative-kit gallery, and the swipe file.
   Copy rules: no em dashes, sentence case, one claim per ad, face is always one option among several. */
window.FP06_CONCEPTS = [
  {
    id: "H01", set: "homeowner", name: "Hero: face + solar", format: "Thesis / hero",
    layout: "poster", theme: "light", img: "front-angle",
    eyebrow: "New · Ora FacePass FP06",
    h1: "Your face opens it. The sun charges it.",
    sub: "3D face unlock in under half a second. A solar panel that charges in daylight. One device on your front door.",
    cta: "Reserve your spot",
    chips: ["3D face unlock", "Solar charging", "Video doorbell", "IP65 outdoor"],
    meta: {
      primary: "Your face opens it. The sun charges it.\n\nThe new Ora FacePass FP06 is a smart lock, a video doorbell, a package camera, and a peephole screen in one device. Walk up and it recognizes you in under half a second. A solar panel on the front keeps the batteries topped up in daylight.\n\nNo keys to lose. No codes to share. Your face data stays encrypted on the lock, never in a cloud.\n\nThe launch list is open. Reserve your spot and be first to order.",
      headline: "Face unlock. Solar charged.",
      description: "Smart lock, doorbell cam and package cam in one."
    },
    verify: ["Solar charging and dual battery confirmed by Jacky (Aug 30). Do not say 'never needs charging'."]
  },
  {
    id: "H02", set: "homeowner", name: "Three devices, one install", format: "Consolidation",
    layout: "slab", theme: "light", img: "front-back-straight",
    eyebrow: "New · Ora FacePass FP06",
    h1: "Doorbell cam. Smart lock. Peephole screen. One device.",
    sub: "Outside: face unlock and two cameras. Inside: a 4-inch HD screen with two-way talk.",
    cta: "Reserve your spot",
    chips: [],
    meta: {
      primary: "Right now your front door probably has a doorbell camera, a smart lock or a keypad, and a peephole. Three devices. Three apps. Three sets of batteries.\n\nThe new Ora FacePass FP06 does all of it in one install. Outside: 3D face unlock, a full-body doorbell camera, and a second camera that watches your packages. Inside: a 4-inch HD screen so you can see and talk to whoever is at the door without opening it.\n\nReserve your spot on the launch list.",
      headline: "Three devices. Now one.",
      description: "Lock, doorbell cam, package cam, peephole screen."
    },
    verify: []
  },
  {
    id: "H03", set: "homeowner", name: "Package camera", format: "Problem / solution",
    layout: "callout", theme: "dark", img: "front-angle",
    eyebrow: "New · Ora FacePass FP06",
    h1: "It sees who's at the door. And whether your package is still there.",
    sub: "",
    cta: "",
    chips: [],
    callouts: [
      { y: 5.5, side: "r", t: "Doorbell camera", d: "Full-body view of who rang" },
      { y: 94, side: "r", t: "Package camera", d: "Watches your deliveries" }
    ],
    meta: {
      primary: "Most doorbell cameras see a face. They miss the box on the ground.\n\nThe new Ora FacePass FP06 has two cameras. The top one gives you a full-body view of whoever rings. The bottom one watches your deliveries. Both live in the same device as your lock, so there is nothing extra to mount, charge, or pair.\n\nSee who's there. See what's there. Reserve your spot on the launch list.",
      headline: "Two cameras. One lock.",
      description: "Full-body doorbell view plus package monitoring."
    },
    verify: ["Dual camera (full-body doorbell cam + package delivery monitoring) confirmed by Jacky (Aug 30)."]
  },
  {
    id: "H04", set: "homeowner", name: "Interior screen", format: "Feature / demo",
    layout: "screen", theme: "dark", img: "interior-screen-closeup",
    eyebrow: "New · Ora FacePass FP06",
    h1: "See who's there before you open the door.",
    sub: "A 4-inch HD screen on the inside of your door. Two-way talk built in. No phone required.",
    cta: "Reserve your spot",
    chips: [],
    meta: {
      primary: "The peephole has not changed in decades. Your door deserves better.\n\nThe new Ora FacePass FP06 puts a 4-inch HD screen on the inside of your door. See a full-body view of whoever is outside. Talk to them through the two-way intercom. Decide, then open. No phone required.\n\nReserve your spot on the launch list.",
      headline: "A peephole with a screen.",
      description: "4-inch HD interior display with two-way talk."
    },
    verify: ["Inner panel 4-inch HD screen with two-way intercom confirmed by Jacky (Aug 30)."]
  },
  {
    id: "H05", set: "homeowner", name: "Solar + dual battery", format: "Objection killer (dead batteries)",
    layout: "callout", theme: "light", img: "front-straight",
    eyebrow: "New · Ora FacePass FP06",
    h1: "Charges in daylight. Runs on two batteries after dark.",
    sub: "",
    cta: "",
    chips: [],
    callouts: [
      { y: 70, side: "l", t: "Solar panel", d: "Charges in daylight" },
      { y: 57, side: "r", t: "Dual batteries", d: "Power after dark" }
    ],
    meta: {
      primary: "The biggest complaint about smart locks and doorbell cams is the same one: dead batteries.\n\nThe new Ora FacePass FP06 has a solar panel built into the front and a dual-battery design inside. Daylight keeps it charged. The batteries carry it through the night. And if you ever run it all the way down, a USB-C port on the bottom gets you in.\n\nReserve your spot on the launch list.",
      headline: "Solar-charged smart lock",
      description: "Solar panel outside. Dual batteries inside."
    },
    verify: ["USB-C emergency port is a MY26-line feature. Confirm it carried over to FP06 before running the primary text as written."]
  },
  {
    id: "H06", set: "homeowner", name: "Privacy", format: "Trust / objection",
    layout: "slab", theme: "dark", img: "front-straight",
    eyebrow: "Ora FacePass FP06",
    h1: "Your face never leaves your door.",
    sub: "Face data is encrypted on the lock itself. It is never uploaded to a cloud.",
    cta: "Reserve your spot",
    chips: ["Encrypted on-device", "No cloud biometrics", "Face is optional"],
    meta: {
      primary: "A lock that knows your face should not send your face anywhere.\n\nOra FacePass stores your face as an encrypted 3D model on the lock itself. No photo. No cloud copy. No account to breach. If you would rather not use your face at all, use a fingerprint, a code, a card, a key, or the app.\n\nThe new FP06 is coming. Reserve your spot on the launch list.",
      headline: "Privacy built in",
      description: "Face data stays encrypted on the lock."
    },
    verify: ["On-device-only biometric storage is documented for the MY26 smart locks. Confirm the FP06 uses the same architecture."]
  },
  {
    id: "H07", set: "homeowner", name: "Eight ways in", format: "Benefit stack",
    layout: "grid8", theme: "light", img: "front-straight",
    eyebrow: "New · Ora FacePass FP06",
    h1: "Eight ways in. Zero keys required.",
    sub: "Everyone in the house gets the way in that suits them.",
    cta: "",
    chips: [],
    pills: ["3D face", "Palm vein", "Fingerprint", "Access code", "Card or fob", "Physical key", "App unlock", "Doorbell entry"],
    meta: {
      primary: "Everyone in your house opens the door a different way.\n\nGrandparents want a key. Kids get a code. You just look at it. The new Ora FacePass FP06 gives you eight ways in: 3D face, palm vein, fingerprint, access code, card or fob, physical key, the app, and remote unlock from the doorbell call.\n\nOne lock. Everyone's way in. Reserve your spot.",
      headline: "Eight ways to unlock",
      description: "Face, fingerprint, code, card, key, app and more."
    },
    verify: ["8-in-1 is documented for FP02MY26 and FP01MY26. Palm vein on the FP06 is NOT confirmed. Hold this ad until Jacky confirms the FP06 unlock list."]
  },
  {
    id: "H08", set: "homeowner", name: "Before / after", format: "Before / after",
    layout: "split", theme: "light", img: "front-angle-only",
    eyebrow: "New · Ora FacePass FP06",
    h1: "The front door, simplified.",
    sub: "",
    cta: "Reserve your spot",
    chips: [],
    before: ["Doorbell camera", "Smart lock or keypad", "Peephole", "Three apps, three sets of batteries"],
    after: "One device. One app. Charges in the sun.",
    meta: {
      primary: "Before: a doorbell camera, a smart lock, a peephole, and three apps that never quite talk to each other.\n\nAfter: one Ora FacePass FP06. Face unlock, a full-body doorbell camera, a package camera, and a 4-inch screen inside your door. One app. One install. And a solar panel so you are not swapping batteries every few months.\n\nReserve your spot on the launch list.",
      headline: "One install replaces three",
      description: "Smart lock, doorbell cam, package cam, peephole."
    },
    verify: []
  },
  {
    id: "H09", set: "homeowner", name: "Annotated product", format: "Spec callout",
    layout: "callout", theme: "dark", img: "front-straight",
    eyebrow: "New · Ora FacePass FP06",
    h1: "Everything your front door needed. One install.",
    sub: "",
    cta: "",
    chips: [],
    callouts: [
      { y: 5.5, side: "l", t: "3D face unlock", d: "Plus full-body doorbell cam" },
      { y: 21, side: "r", t: "Keypad + card", d: "Codes and fobs" },
      { y: 36.5, side: "l", t: "Doorbell", d: "Keyway hidden behind it" },
      { y: 51, side: "r", t: "Fingerprint", d: "Under half a second" },
      { y: 70, side: "l", t: "Solar panel", d: "Charges in daylight" },
      { y: 94, side: "r", t: "Package camera", d: "Watches deliveries" }
    ],
    meta: {
      primary: "Here is everything on the front of the new Ora FacePass FP06:\n\n• 3D face unlock and a full-body doorbell camera\n• Keypad and card reader\n• Doorbell button with the keyway hidden behind it\n• Fingerprint reader\n• Solar panel\n• A second camera for packages\n\nInside your door: a 4-inch HD screen with two-way talk. Reserve your spot on the launch list.",
      headline: "Meet the FP06",
      description: "Face unlock, two cameras, solar, and a screen inside."
    },
    verify: ["Hidden keyway behind the doorbell is a MY26-line detail. Confirm for FP06."]
  },
  {
    id: "H10", set: "homeowner", name: "Hands full", format: "Moment / lifestyle",
    layout: "slab", theme: "light", img: "front-angle",
    eyebrow: "New · Ora FacePass FP06",
    h1: "Groceries in both hands? Just look at the door.",
    sub: "3D face unlock in under half a second. Works in the dark. Works when the Wi-Fi is down.",
    cta: "Reserve your spot",
    chips: ["Under 0.5 s", "Works in darkness", "Works offline"],
    meta: {
      primary: "Keys in the bag. Bag in one hand. Kid in the other.\n\nThe new Ora FacePass FP06 recognizes your face in under half a second and unlocks. It works in the dark, in the rain, and when the Wi-Fi is down, because recognition happens on the lock, not in a cloud.\n\nWalk up. Walk in. Reserve your spot on the launch list.",
      headline: "Walk up. Walk in.",
      description: "3D face unlock in under half a second."
    },
    verify: ["Under 0.5 s, works in darkness and offline are documented for the MY26 line. Confirm for FP06."]
  },
  {
    id: "H11", set: "homeowner", name: "Launch list", format: "Offer / launch",
    layout: "poster", theme: "dark", img: "front-angle",
    eyebrow: "Launch list open",
    h1: "The new Ora FacePass FP06.",
    sub: "Be first to order. No payment, no commitment.",
    cta: "Reserve your spot",
    chips: ["Face unlock", "Solar", "2 cameras", "Interior screen"],
    meta: {
      primary: "The new Ora FacePass FP06 is almost here.\n\nSmart lock, video doorbell, package camera, and a 4-inch screen inside your door. 3D face unlock. Solar charging. Eight ways in.\n\nJoin the launch list to be first to order. No payment and no commitment.",
      headline: "Reserve the FP06",
      description: "First to know. First to order."
    },
    verify: ["'Eight ways in' in the primary text depends on the FP06 unlock list. Swap to 'multiple ways in' if unconfirmed at launch."]
  },
  {
    id: "P01", set: "pm", name: "Turnover without a locksmith", format: "Pain hook (rekey)",
    layout: "slab", theme: "dark", img: "front-back-angle",
    eyebrow: "Ora FacePass · For property managers",
    h1: "Tenant moves out. Access is gone in 30 seconds.",
    sub: "No locksmith. No rekey. Revoke from your phone.",
    cta: "Book a walkthrough",
    chips: ["Face, code, or app", "Entry log by identity", "5-door minimum"],
    meta: {
      primary: "Every move-out costs you a locksmith call, a new set of keys, and a unit that sits empty while you wait.\n\nOra FacePass turns turnover into a 30-second task from your phone. Delete the outgoing resident. Add the new one at lease signing. Residents open the door with their face, a code, or the app. Every entry is logged by identity.\n\nColorado property managers: book a 15-minute walkthrough. We work with buildings that have five or more doors.",
      headline: "Stop rekeying at turnover",
      description: "Revoke and grant access from your phone."
    },
    verify: []
  },
  {
    id: "P02", set: "pm", name: "Audit trail", format: "Liability / control",
    layout: "slab", theme: "light", img: "front-straight",
    eyebrow: "Ora FacePass · For property managers",
    h1: "Know exactly who entered 4B.",
    sub: "Every entry is logged by identity. Residents choose face, code, card, or app.",
    cta: "Book a 15-minute walkthrough",
    chips: ["Identity-based log", "No shared codes", "One dashboard"],
    meta: {
      primary: "\"Who had access to that unit?\" should never be a guess.\n\nOra FacePass logs every entry by identity and time. No shared codes floating around. No copied keys. Residents choose how they enter: face, code, card, or app. You get the record.\n\nColorado property managers: book a 15-minute walkthrough. Five-door minimum.",
      headline: "An entry log for every door",
      description: "Identity-based access records."
    },
    verify: []
  },
  {
    id: "P03", set: "pm", name: "One device per door", format: "Consolidation + price anchor",
    layout: "split", theme: "dark", img: "front-angle-only",
    eyebrow: "Ora FacePass · For property managers",
    h1: "Lock. Doorbell. Camera. Access log. One device per door.",
    sub: "",
    cta: "Book a walkthrough",
    chips: [],
    before: ["Smart lock", "Doorbell camera", "Security camera", "Separate access system"],
    after: "The Ora FacePass line starts at $299.99 per door at MSRP.",
    meta: {
      primary: "Stacking a smart lock, a doorbell camera, a security camera, and a separate access system on every door adds up fast.\n\nOra FacePass puts all of it in one device per door: 3D face unlock, video doorbell with two-way talk, camera, and an identity-based entry log you manage from one dashboard. The line starts at $299.99 per door at MSRP.\n\nColorado property managers with five or more doors: book a 15-minute walkthrough.",
      headline: "One device per door",
      description: "From $299.99 per door at MSRP."
    },
    verify: ["$299.99 is the FP02MY26 MSRP. The image shows the FP06. If FP06 pricing lands higher, swap the image for FP02MY26 or remove the price line."]
  }
];
