from pathlib import Path
root=Path(".")
src=root/"app/src/main/java/com/radarlocal/maxim"
core=src/"core"
def replace_file(p,a,b):
    x=p.read_text()
    if a not in x:raise RuntimeError("Pattern absent in "+str(p)+": "+a[:70])
    p.write_text(x.replace(a,b))

(core/"RealOfferModel.java").write_text(r'''package com.radarlocal.maxim.core;

/** Only a labelled delivery ETA enables a credible hourly estimate. */
public final class RealOfferModel {
  private RealOfferModel(){}
  public static final class Outcome {
    public final double perKm;
    public final Double perHour;
    public final TripMath.Input input;
    public final int tier;
    public Outcome(double km,Double h,TripMath.Input in,int tier){
      perKm=km;perHour=h;input=in;this.tier=tier;
    }
  }
  public static Outcome assess(double fare,double pickupKm,double rideKm,Double deliveryMinutes,
                               double commission,double minHour,double minKm,int stops) {
    if(!Double.isFinite(fare)||fare<=0||!Double.isFinite(pickupKm)||pickupKm<0||
       !Double.isFinite(rideKm)||rideKm<=0||!Double.isFinite(commission)||
       commission<0||commission>=100||minHour<=0||minKm<=0)
       throw new IllegalArgumentException("invalid offer");
    double afterCommission=fare*(1-commission/100.0);
    double perKm=afterCommission/(pickupKm+rideKm);
    if(deliveryMinutes==null || !Double.isFinite(deliveryMinutes) ||
       deliveryMinutes<2 || deliveryMinutes>180)
       return new Outcome(perKm,null,null,perKm>=minKm?1:0);
    // Maxim "Tiempo de entrega" refers to the passenger leg, NOT pickup.
    // Weakly adjust pickup speed from the zone's passenger-leg average.
    double zoneKmh=rideKm*60/deliveryMinutes;
    double pickupKmh=Math.max(14,Math.min(32,18+.25*(zoneKmh-20)));
    double pickupMin=pickupKm==0?0:pickupKm*60/pickupKmh+1.5;
    double rideMin=deliveryMinutes*1.12+1;
    double extra=2+Math.max(0,Math.min(5,stops))*3.0;
    TripMath.Input in=new TripMath.Input(fare,pickupKm,rideKm,pickupMin,
                                        rideMin,commission,0,extra);
    TripMath.Result result=TripMath.calculate(in);
    int tier=result.netPerKm>=minKm && result.netPerHour>=minHour?2:
      (result.netPerKm>=minKm || result.netPerHour>=minHour?1:0);
    return new Outcome(perKm,result.netPerHour,in,tier);
  }
}
''')
service=src/"LiveCaptureService.java"
s=service.read_text()
s=s.replace('import com.radarlocal.maxim.core.TimeRiskModel;','import com.radarlocal.maxim.core.TimeRiskModel;\nimport com.radarlocal.maxim.core.RealOfferModel;')
s=s.replace('    private long lastHealthFrame=0,lastHealthOcr=0;', '    private long lastHealthFrame=0,lastHealthOcr=0;\n    private long lastFrameArrived=0;')
s=s.replace('            display=projection.createVirtualDisplay("MaximRadarCapture",', '''            reader.setOnImageAvailableListener(this::newFrame,worker);
            display=projection.createVirtualDisplay("MaximRadarCapture",''')
s=s.replace('            worker.postDelayed(pollFrames,180L);', '            worker.postDelayed(frameWatchdog,5000L);')
s=s.replace('            reader=next;\n            if(old!=null)old.close();','            reader=next;\n            next.setOnImageAvailableListener(this::newFrame,worker);\n            if(old!=null)old.close();')
# event-driven capture replaces polling timer
start=s.index("    private final Runnable pollFrames=new Runnable() {")
end=s.index("    private Bitmap convertImage(Image image)",start)
s=s[:start]+'''    // Samsung-specific stabilization: accept new buffers on arrival, no aggressive polling.
    private void newFrame(ImageReader source){
        Image image=null;
        try{
            image=source.acquireLatestImage();
            if(image==null || !running)return;
            long now=SystemClock.elapsedRealtime();
            lastFrameArrived=now;
            if(now-lastHealthFrame>4500){
                RadarHealth.frame(this);lastHealthFrame=now;
            }
            if(busy.get() || now-lastOcrAt<750L)return;
            if(!busy.compareAndSet(false,true))return;
            Bitmap bitmap=convertImage(image);
            if(bitmap==null){busy.set(false);RadarHealth.set(this,"Formato de imagen no compatible");return;}
            if(!frameUsable(bitmap)){
                bitmap.recycle();busy.set(false);
                RadarHealth.set(this,"La pantalla está vacía o protegida");hideBubble();return;
            }
            long hash=visualHash(bitmap);
            if(stableKey!=null && hash==lastVisualHash &&
                 now-lastOcrAt<RECHECK_IDENTICAL_MS){
                bitmap.recycle();busy.set(false);return;
            }
            lastVisualHash=hash;lastOcrAt=now;
            analyze(bitmap);
        }catch(Exception ex){
            busy.set(false);RadarHealth.set(this,"Error fotograma: "+ex.getClass().getSimpleName());
            android.util.Log.w("MaximRadar","Error Samsung frame",ex);
        }finally{if(image!=null)image.close();}
    }
    private final Runnable frameWatchdog=new Runnable(){
        @Override public void run(){
            if(!running)return;
            long now=SystemClock.elapsedRealtime();
            if(lastFrameArrived==0 || now-lastFrameArrived>7000L){
                RadarHealth.set(LiveCaptureService.this,
                   "Sin imágenes recientes. Volvé a iniciar y autorizá pantalla completa");
                hideBubble();
            }
            worker.postDelayed(this,5000L);
        }
    };

''' + s[end:]
# Replace calculation while preserving input for local history (only list rides)
start=s.index('            TimeRiskModel.Estimate risk=TimeRiskModel.assess(')
end=s.index('        }catch(Exception e){',start)
s=s[:start]+'''            RealOfferModel.Outcome outcome=RealOfferModel.assess(
                    offer.fare,offer.pickupKm,offer.rideKm,offer.rideMin,
                    Prefs.commission(this),Prefs.minHour(this),Prefs.minKm(this),
                    offer.intermediateStops);
            int tier=outcome.tier;
            if(outcome.input!=null && tier==2){
                LearningEngine.Advice advice=LearningEngine.evaluate(
                    TripMath.calculate(outcome.input),
                    store.observedSamples(Prefs.commission(this)),
                    Prefs.minHour(this),Prefs.minKm(this),true);
                if(advice.tier==3)tier=3;
            }
            String first=outcome.perHour==null?"— /h":"~"+money(outcome.perHour)+"/h";
            String second=money(outcome.perKm)+"/km";
            if(tier==3)first="★ "+first;
            showBubble(first+"\\n"+second,tier);
            stableKey=key;stableAnchor=offer.anchor;
            stableFare=offer.fare;stablePickupKm=offer.pickupKm;stableRideKm=offer.rideKm;
            stableStops=offer.intermediateStops;
            pendingKey=null;pendingCount=0;lastValidOffer=now;
            // Automatic confirmations do not enter the hourly learning sample.
            if(outcome.input!=null)store.saveOffer(outcome.input,false);
            RadarHealth.offer(this);
''' + s[end:]
s=s.replace('        return Math.round(offer.fare/10.0)+"|"+Math.round(offer.pickupKm*5)+"|"+Math.round(offer.rideKm*5)',
'''        return Math.round(offer.fare/10.0)+"|"+Math.round(offer.pickupKm*5)+"|"+Math.round(offer.rideKm*5)''')
# The previous code appended stop and ETA fields in a following line.
service.write_text(s)

# Preserve configured commission, but first-use default is 5% for this driver.
prefs=src/"Prefs.java"
replace_file(prefs,'getNumber(c,"commission",0)','getNumber(c,"commission",5)')
db=src/"LocalStore.java"
replace_file(db,'"maxim_radar.db"','"maxim_radar_v094.db"')
d=db.read_text()
start=d.index('    public synchronized List<LearningEngine.Sample> observedSamples(')
end=d.index('    /** Robust average',start)
d=d[:start]+'''    public synchronized List<LearningEngine.Sample> observedSamples(double commissionPct){
        List<LearningEngine.Sample> out=new ArrayList<>();
        try(Cursor c=getReadableDatabase().rawQuery(
          "SELECT net_h,net_km FROM rides WHERE source='maxim' AND completed=0 ORDER BY ts DESC LIMIT 80",null)){
            while(c.moveToNext()){
                double h=c.getDouble(0),km=c.getDouble(1);
                if(Double.isFinite(h)&&Double.isFinite(km)&&h>0&&km>0)
                    out.add(new LearningEngine.Sample(h,km));
            }
        }
        return out;
    }
''' + d[end:]
db.write_text(d)
# Add launcher vector. Android 11+ supports vector on launcher and adaptive icon.
res=root/"app/src/main/res"
(res/"drawable").mkdir(exist_ok=True)
(res/"mipmap-anydpi-v26").mkdir(exist_ok=True)
(res/"values/colors.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<resources><color name="radar_navy">#101822</color></resources>''')
(res/"drawable/ic_radar_foreground.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
  <path android:fillColor="#00000000" android:strokeColor="#FFDE26" android:strokeWidth="2.8"
      android:pathData="M28,52 A26,26 0,1 1,80 52"/>
  <path android:fillColor="#00000000" android:strokeColor="#FFDE26" android:strokeWidth="2.2"
      android:pathData="M34,52 A20,20 0,1 1,74 52"/>
  <path android:fillColor="#FFDE26" android:pathData="M35,56 L38,43 Q40,38 48,38 L60,38 Q68,38 70,43 L73,56 L73,67 Q73,70 70,70 L65,70 L63,65 L45,65 L43,70 L38,70 Q35,70 35,67 Z"/>
  <path android:fillColor="#101822" android:pathData="M42,46 L65,46 L62,42 L46,42 Z"/>
  <path android:fillColor="#101822" android:pathData="M40,57 A3,3 0,1 0,46 57 A3,3 0,1 0,40 57 M62,57 A3,3 0,1 0,68 57 A3,3 0,1 0,62 57"/>
  <path android:strokeColor="#FFDE26" android:strokeWidth="2.3" android:pathData="M54,15 L54,35 M21,53 L34,53 M74,53 L87,53"/>
</vector>''')
(res/"mipmap-anydpi-v26/ic_launcher.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/radar_navy"/>
  <foreground android:drawable="@drawable/ic_radar_foreground"/>
</adaptive-icon>''')
manifest=root/"app/src/main/AndroidManifest.xml"
replace_file(manifest,'<application android:label="Maxim Radar"',
    '<application android:icon="@mipmap/ic_launcher" android:roundIcon="@mipmap/ic_launcher" android:label="Maxim Radar"')
gradle=root/"app/build.gradle"
replace_file(gradle,"versionCode 12","versionCode 14")
replace_file(gradle,"0.9.2-samsung-beta","0.9.4-samsung-clean")
print("Clean Samsung v0.9.4 patch applied")
