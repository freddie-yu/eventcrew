importScripts("https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyD4RXH9Y_NZ84Uyk8S9pG3f0MAfqw43-58",
  authDomain: "eventcrew-demo.firebaseapp.com",
  projectId: "eventcrew-demo",
  storageBucket: "eventcrew-demo.firebasestorage.app",
  messagingSenderId: "1015453781744",
  appId: "1:1015453781744:web:5dc0778cc6f055f9b47c35",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  const title = message.notification?.title ?? "EventCrew";
  const options = {
    body: message.notification?.body ?? "Shift update",
    data: message.data ?? {},
  };

  self.registration.showNotification(title, options);
});
