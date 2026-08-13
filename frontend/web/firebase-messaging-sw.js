importScripts('https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBjnV0WsMs3FhL9VC7kXxATwl3Du61fElg",
  authDomain: "smartkrishi-e068d.firebaseapp.com",
  projectId: "smartkrishi-e068d",
  storageBucket: "smartkrishi-e068d.appspot.com",
  messagingSenderId: "662989758480",
  appId: "1:662989758480:web:8e3d6f78ea1b9bc3f1e6fd" // fallback web app ID
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
