// Firebase web app settings for Sela Learning Hub.
// These values are public by design; security comes from Firestore rules and Authorized domains.
window.SELA_FIREBASE_CONFIG = {
  apiKey: "AIzaSyAsIQMGolR45BfVozJedg_ebAWwPtxdNX0",
  authDomain: "sela-learning-hub.firebaseapp.com",
  projectId: "sela-learning-hub",
  storageBucket: "sela-learning-hub.firebasestorage.app",
  messagingSenderId: "472453341104",
  appId: "1:472453341104:web:47eb71f3d768acd6f9c075",
  measurementId: "G-QQDDVMLFKC"
};

// Address of the Sela verification server (Google Apps Script web app). See SETUP-SERVER.md.
// Leave empty until the server is deployed: assessments cannot be marked without it.
window.SELA_SERVER_URL = "https://script.google.com/macros/s/AKfycbxbEUcykU18cvtFH4gaYhSykgGv4z3z_T4YB5B6v49DGn0L2xkYsYPfyuZ0z07Ecs7sMg/exec";

// Direct uploads of videos and PDFs (free Cloudinary account). Fill in both values, keep the quotes.
// cloud = your Cloudinary "Cloud name"; preset = the name of an UNSIGNED upload preset.
window.SELA_UPLOAD = { cloud: "smrbgyia", preset: "sela_upload" };
