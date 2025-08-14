# Allprocar — MVP Android (Backend + Flutter)

Monorepo listo para subir a tu GitHub. Incluye:

- **backend/**: API REST en Node.js/Express con persistencia simple en JSON (migrable a Go sin romper contrato).
- **app_flutter/**: App Flutter para **dueños de vehículos**. Es una versión demostrativa que crea un usuario y un vehículo predeterminados para permitir crear solicitudes y consultar el historial sin registro real.
- **app_provider/**: App Flutter para **talleres/proveedores**. También es demostrativa: inicia con un usuario y taller predeterminados, carga las especialidades configuradas y permite ver solicitudes disponibles, enviar ofertas y revisar solicitudes asignadas.

## Requisitos
- Node 18+ y npm
- Flutter 3.19+ (Dart 3)

## Ejecutar Backend
```bash
cd backend
cp .env.example .env
npm i
npm run dev
```
Healthcheck: `GET http://localhost:4000/api/health`

## Ejecutar App Flutter (Android)
### Dueños de vehículos
```bash
cd app_flutter
flutter pub get
flutter run
```
### Proveedores
```bash
cd app_provider
flutter pub get
flutter run
```
En emulador Android el host `localhost` del PC es `10.0.2.2`. Ya está configurado como default en `lib/core/env.dart` en ambas apps.

## Build APK (release)
Para generar un APK release en cualquiera de las apps:
```bash
# App de clientes
cd app_flutter
flutter build apk --release

# App de proveedores
cd app_provider
flutter build apk --release
```
Firma: crea keystore si no tenés y configúrala en el directorio `android/` de cada proyecto (guía estándar de Flutter).

## Estructura
```
allprocar-mvp/
├─ backend/
├─ app_flutter/
└─ app_provider/
```
