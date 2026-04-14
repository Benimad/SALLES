# Configuration Firebase pour Android

## Étapes pour configurer Firebase:

1. **Créer un projet Firebase:**
   - Allez sur https://console.firebase.google.com/
   - Cliquez sur "Ajouter un projet"
   - Suivez les étapes de création

2. **Ajouter une application Android:**
   - Dans la console Firebase, cliquez sur l'icône Android
   - Nom du package: `com.example.salles`
   - Téléchargez le fichier `google-services.json`
   - Placez-le dans `android/app/`

3. **Modifier build.gradle (Project level):**
   ```gradle
   buildscript {
       dependencies {
           classpath 'com.google.gms:google-services:4.4.0'
       }
   }
   ```

4. **Modifier build.gradle (App level):**
   ```gradle
   plugins {
       id 'com.android.application'
       id 'com.google.gms.google-services'
   }

   dependencies {
       implementation platform('com.google.firebase:firebase-bom:32.7.0')
       implementation 'com.google.firebase:firebase-messaging'
   }
   ```

5. **Modifier AndroidManifest.xml:**
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   
   <application>
       <service
           android:name="com.google.firebase.messaging.FirebaseMessagingService"
           android:exported="false">
           <intent-filter>
               <action android:name="com.google.firebase.MESSAGING_EVENT"/>
           </intent-filter>
       </service>
   </application>
   ```

6. **Obtenir la clé serveur Firebase:**
   - Dans la console Firebase > Paramètres du projet
   - Onglet "Cloud Messaging"
   - Copiez la "Clé du serveur"
   - Collez-la dans `backend/api/send_notification.php`

## Note:
Le fichier `google-services.json` doit être placé dans `android/app/` avant de compiler l'application.
