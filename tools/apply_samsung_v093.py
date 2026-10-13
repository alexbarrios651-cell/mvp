from pathlib import Path

root = Path(".")
svc = root/"app/src/main/java/com/radarlocal/maxim/LiveCaptureService.java"
s = svc.read_text()
s = s.replace('            showBubble("● RADAR ACTIVO",-1);','            hideBubble();')
s = s.replace('                assembler.clear();showBubble("● RADAR ACTIVO",-1);','                assembler.clear();hideBubble();')
s = s.replace('                                showBubble("SIN IMAGEN LEGIBLE",-1);','                                hideBubble();')
s = s.replace('        else showBubble("● RADAR ACTIVO",-1);','        else hideBubble();')
s = s.replace('        if(SystemClock.elapsedRealtime()-lastRecognizedMaxim<STALE_OFFER_MS)showBubble("Abrí detalles",-1);','        if(SystemClock.elapsedRealtime()-lastRecognizedMaxim<STALE_OFFER_MS)hideBubble();')
s = s.replace('            showBubble("Analizando…",-1);','            hideBubble();')
s = s.replace('            if(significant)showBubble("Analizando…",-1);','            if(significant)hideBubble();')
s = s.replace('                    p.gravity=Gravity.TOP|Gravity.LEFT;', '                    p.gravity=Gravity.TOP|Gravity.RIGHT;')
s = s.replace('                    p.x=dp(12);','                    p.x=dp(10);')
s = s.replace('        boolean maxim=normalized.contains("maxim argentina") || normalized.contains("ar maxim") ||', '        boolean maxim=OfferParser.looksLikeMaximScreen(raw) || normalized.contains("ar maxim") ||')
s = s.replace('        if(!offer.complete()) {\n', '        if(!offer.complete()) {\n            RadarHealth.missing(this,offer.describeMissing());\n')
s = s.replace('                    acceptText(output.getText());','                    RadarHealth.text(LiveCaptureService.this,output.getText()==null?0:output.getText().length());\n                    acceptText(output.getText());')
s = s.replace('            RadarHealth.set(this,"Oferta leída correctamente");','            RadarHealth.offer(this);')
s = s.replace('            showBubble("ABRÍ DETALLES",-1);','            hideBubble();')  # quiet on calculation failures
svc.write_text(s)

health = root/"app/src/main/java/com/radarlocal/maxim/RadarHealth.java"
s=health.read_text()
s=s.replace('    public static void clear(Context c){', '''    public static void text(Context c,int length){
        p(c).edit().putInt("ocr_chars",Math.max(0,length)).apply();
    }
    public static void missing(Context c,String fields){
        String safe=fields==null?"campos":fields.replaceAll("[^a-zA-ZáéíóúñÁÉÍÓÚÑ ]","");
        p(c).edit().putString("missing_fields",safe).apply();
    }
    public static void offer(Context c) {
        p(c).edit().putString("missing_fields","").apply();
        set(c,"Oferta leída correctamente");
    }
    public static void clear(Context c){''')
s=s.replace('        return state+" · Imagen y OCR activos";','''        int chars=s.getInt("ocr_chars",0);
        if(chars==0)return "OCR activo, pero sin texto. Revisá autorización de pantalla completa.";
        String missing=s.getString("missing_fields","");
        return state+" · OCR: "+chars+" caracteres"+(missing.isEmpty()?"":" · faltan "+missing);''')
health.write_text(s)

parser = root/"app/src/main/java/com/radarlocal/maxim/core/OfferParser.java"
s=parser.read_text()
s=s.replace('    public static Offer parse(String raw) {','''    public static boolean looksLikeMaximScreen(String raw) {
        if(raw==null || raw.isEmpty())return false;
        String a=normalize(raw);
        if(contains(a,"maxim argentina","ar maxim","maxim mendoza"))return true;
        return contains(a,"solicitar","aceptar","rechazar") &&
               contains(a,"hasta la direccion","hasta direccion","long. de la") &&
               contains(a,"en efectivo","mercado pago","tarjeta") && a.contains("$");
    }
    public static Offer parse(String raw) {''')
s=s.replace('        Double moneyWithLabel=null;','        Double moneyWithLabel=null;\n        int fareDistance=99;')
s=s.replace('                    if(paymentNext || paymentSame) moneyWithLabel=val;', '''                    int gap=paymentSame?0:paymentNext?1:99;
                    for(int j=i+2;j<=i+3 && gap==99 && j<lines.length;j++){
                        if(contains(normalize(lines[j]),"en efectivo","mercado pago","tarjeta","transferencia"))gap=j-i;
                        if(lines[j].contains("$"))break;
                    }
                    if(gap<fareDistance){moneyWithLabel=val;fareDistance=gap;}''')
s=s.replace('        if((out.pickupKm==null || out.rideKm==null) && all.contains("hasta la direccion")\n                && all.contains("long. de la")) {', '''        boolean labels=contains(all,"hasta la direccion","hasta direccion") &&
                contains(all,"long. de la","long de la","longitud de la");
        boolean confirmation=contains(all,"confirmacion","en el lugar dentro") &&
                contains(all,"aceptar","rechazar") && contains(all,"maxim","estandar");
        if((out.pickupKm==null || out.rideKm==null) && (labels || confirmation)) {''')
parser.write_text(s)

gradle=root/"app/build.gradle"
s=gradle.read_text().replace("versionCode 12","versionCode 13").replace("0.9.2-samsung-beta","0.9.3-samsung-hotfix")
gradle.write_text(s)
print("Samsung hotfix applied: OCR diagnostics, quieter overlay, resilient two-distance parser")
