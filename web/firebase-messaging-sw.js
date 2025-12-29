importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

const firebaseConfig = {
    apiKey: "AIzaSyBu3zILgpmzKtPYZ1aBX67D2NTr7ztDyac",
    authDomain: "braand-app.firebaseapp.com",
    projectId: "braand-app",
    storageBucket: "braand-app.firebasestorage.app",
    messagingSenderId: "836218835970",
    appId: "1:836218835970:web:75d8253a1c94bfb161031b"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    // Customize notification here
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
