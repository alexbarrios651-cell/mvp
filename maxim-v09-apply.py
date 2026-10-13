#!/usr/bin/env python3
"""Aplica sobre el archivo fuente 0.8.1 el modelo comprobado offline v0.9."""
from pathlib import Path
root=Path(".")
core=root/"app/src/main/java/com/radarlocal/maxim/core"
(core/"TimeRiskModel.java").write_text(r'''package com.radarlocal.maxim.core;

/** Conservative, offline duration scenarios. These are heuristics, NOT actual routing. */
public final class TimeRiskModel {
    private TimeRiskModel() {}
    public static final class Estimate {
        public final TripMath.Input cautiousInput;
        public final TripMath.Result cautious, favorable;
        public final double cautiousMinutes, favorableMinutes;
        public final int tier, extraStops;
        private Estimate(TripMath.Input in, TripMath.Result slow, TripMath.Result fast, int tier, int stops) {
            this.cautiousInput=in;this.cautious=slow;this.favorable=fast;
            this.cautiousMinutes=slow.totalMin;this.favorableMinutes=fast.totalMin;
            this.tier=tier;this.extraStops=stops;
        }
    }
    public static Estimate assess(double fare,double pickupKm,double rideKm,double commissionPct,
                                  double minPerHour,double minPerKm,int reportedIntermediateStops) {
        if(!Double.isFinite(minPerHour)||minPerHour<=0||!Double.isFinite(minPerKm)||minPerKm<=0)
            throw new IllegalArgumentException("Metas invalidas");
        if(!Double.isFinite(pickupKm)||pickupKm<0||!Double.isFinite(rideKm)||rideKm<=0)
            throw new IllegalArgumentException("Distancias invalidas");
        int stops=Math.max(0,Math.min(5,reportedIntermediateStops));
        double fastPickup=pickupKm==0?0:Math.max(1.5,pickupKm*60.0/32.0);
        double fastRide=Math.max(2.5,rideKm*60.0/38.0);
        TripMath.Input fast=new TripMath.Input(fare,pickupKm,rideKm,fastPickup,fastRide,commissionPct,0,2.0+stops*1.5);
        double slowPickup=pickupKm==0?0:Math.max(3,pickupKm*60.0/13.0);
        double slowRide=Math.max(4,rideKm*60.0/17.0);
        TripMath.Input cautious=new TripMath.Input(fare,pickupKm,rideKm,slowPickup,slowRide,commissionPct,0,6.0+stops*4.0);
        TripMath.Result slowResult=TripMath.calculate(cautious);
        TripMath.Result fastResult=TripMath.calculate(fast);
        int tier=(slowResult.netPerKm>=minPerKm && slowResult.netPerHour>=minPerHour)?2:
                 (slowResult.netPerKm<minPerKm && fastResult.netPerHour<minPerHour)?0:1;
        return new Estimate(cautious,slowResult,fastResult,tier,stops);
    }
}
''',encoding="utf8")
def update(file,old,new):
    p=root/file
    s=p.read_text(encoding="utf8")
    if old not in s: raise RuntimeError("No se encontró marcador en "+str(file)+": "+old[:80])
    p.write_text(s.replace(old,new),encoding="utf8")

parser="app/src/main/java/com/radarlocal/maxim/core/OfferParser.java"
update(parser,"public Double fare, pickupKm, rideKm, pickupMin, rideMin;",
       "public Double fare, pickupKm, rideKm, pickupMin, rideMin;\n        public int intermediateStops=0;")
update(parser,'    private static final Pattern MIN=Pattern.compile',
       '    private static final Pattern STOPS=Pattern.compile("\\\\b([2-6])\\\\s*paradas?\\\\b",Pattern.CASE_INSENSITIVE);\n    private static final Pattern MIN=Pattern.compile')
update(parser,'        String all=normalize(raw);\n',
       '        String all=normalize(raw);\n        Matcher stops=STOPS.matcher(all);\n        if(stops.find()) out.intermediateStops=Math.max(0,Integer.parseInt(stops.group(1))-1);\n')
p=root/parser;s=p.read_text()
start=s.index('                // "Tiempo de entrega" refers to travel TO PICKUP')
end=s.index('            }\n        }\n        out.fare=',start)
s=s[:start]+'                // Tiempo de entrega is ambiguous: do not infer pickup ETA.\n'+s[end:]
s=s.replace('''                    && (pickupMin==null || (Double.isFinite(pickupMin) && pickupMin>=0 && pickupMin<=240))
                    && (rideMin==null || (Double.isFinite(rideMin) && rideMin>0 && rideMin<=600)); }''',
'''                    ; }''')
p.write_text(s)
assembler="app/src/main/java/com/radarlocal/maxim/core/OfferAssembler.java"
update(assembler,"        if(joined.rideMin==null)joined.rideMin=previous.rideMin;",
       "        if(joined.rideMin==null)joined.rideMin=previous.rideMin;\n        joined.intermediateStops=Math.max(joined.intermediateStops,previous.intermediateStops);")
update(assembler,"c.pickupMin=x.pickupMin;c.rideMin=x.rideMin;return c;",
       "c.pickupMin=x.pickupMin;c.rideMin=x.rideMin;\n        c.intermediateStops=x.intermediateStops;return c;")
service="app/src/main/java/com/radarlocal/maxim/LiveCaptureService.java"
update(service,"import com.radarlocal.maxim.core.TripMath;",
       "import com.radarlocal.maxim.core.TripMath;\nimport com.radarlocal.maxim.core.TimeRiskModel;")
update(service,"    private double learnedKmh=25;\n    private int newOffersSinceSpeedRefresh=0;\n","")
update(service,"            worker.post(()->learnedKmh=store.observedPickupSpeedKmh());\n","")
update(service,"    private double stableFare=0,stablePickupKm=0,stableRideKm=0;",
       "    private double stableFare=0,stablePickupKm=0,stableRideKm=0;\n    private int stableStops=0;")
update(service,"                    || Math.abs(offer.rideKm-stableRideKm)>1.5;",
       "                    || Math.abs(offer.rideKm-stableRideKm)>1.5\n                    || offer.intermediateStops!=stableStops;")
p=root/service;s=p.read_text()
start=s.index("            TripMath.Input input=Prefs.inputForOffer")
end=s.index("\n        }catch(Exception e){",start)
s=s[:start]+'''            TimeRiskModel.Estimate risk=TimeRiskModel.assess(
                    offer.fare,offer.pickupKm,offer.rideKm,Prefs.commission(this),
                    Prefs.minHour(this),Prefs.minKm(this),offer.intermediateStops);
            TripMath.Input input=risk.cautiousInput;
            TripMath.Result result=risk.cautious;
            int tier=risk.tier;
            if(tier==2) {
                LearningEngine.Advice advice=LearningEngine.evaluate(result,
                        store.observedSamples(Prefs.commission(this)),
                        Prefs.minHour(this),Prefs.minKm(this),true);
                if(advice.tier==3) tier=3;
            }
            String first=(tier==3?"★ ":tier>=2?"✓ ":tier==1?"! ":"× ")+"~"+money(result.netPerHour)+"/h";
            String second=money(result.netPerKm)+"/km";
            showBubble(first+"\\n"+second,tier);
            stableKey=key;stableAnchor=offer.anchor;
            stableFare=offer.fare;stablePickupKm=offer.pickupKm;stableRideKm=offer.rideKm;
            stableStops=offer.intermediateStops;
            pendingKey=null;pendingCount=0;lastValidOffer=now;
            store.saveOffer(input,false);
'''+s[end:]
s=s.replace('return Math.round(offer.fare/10.0)+"|"+Math.round(offer.pickupKm*5)+"|"+Math.round(offer.rideKm*5);',
'''return Math.round(offer.fare/10.0)+"|"+Math.round(offer.pickupKm*5)+"|"+Math.round(offer.rideKm*5)
                +"|"+offer.intermediateStops;''')
p.write_text(s)
store="app/src/main/java/com/radarlocal/maxim/LocalStore.java"
update(store,"import com.radarlocal.maxim.core.TripMath;",
       "import com.radarlocal.maxim.core.TripMath;\nimport com.radarlocal.maxim.core.TimeRiskModel;")
update(store,"SELECT fare,pickup_km,ride_km,pickup_min,ride_min FROM rides WHERE source=",
       "SELECT fare,pickup_km,ride_km FROM rides WHERE source=")
update(store,'''                double time=c.getDouble(3)+c.getDouble(4);
                if(Double.isFinite(income)&&income>0&&km>0&&time>0)
                    out.add(new LearningEngine.Sample(income*60.0/time,income/km));''',
'''                if(Double.isFinite(income)&&income>0&&km>0){
                    try{
                        // Ignore prior version's optimistic estimated ETAs.
                        TimeRiskModel.Estimate estimate=TimeRiskModel.assess(
                                c.getDouble(0),c.getDouble(1),c.getDouble(2),commissionPct,1,1,0);
                        out.add(new LearningEngine.Sample(estimate.cautious.netPerHour,estimate.cautious.netPerKm));
                    }catch(IllegalArgumentException ignored){}
                }''')
update("app/build.gradle","versionCode 9","versionCode 10")
update("app/build.gradle","versionName '0.8.1-live-beta'","versionName '0.9-live-beta'")
tests="tests/CoreTests.java"
update(tests,"import com.radarlocal.maxim.core.OfferAssembler;",
       "import com.radarlocal.maxim.core.OfferAssembler;\nimport com.radarlocal.maxim.core.TimeRiskModel;")
update(tests,"        near(screenshot3.pickupMin,14);",
       '        check(screenshot3.pickupMin==null,"Never infer pickup from Tiempo de entrega");')
update(tests,'        System.out.println("CORE TESTS:',
'''        TimeRiskModel.Estimate sample=TimeRiskModel.assess(3900,1.6,2.7,12,12000,850,0);
        near(sample.cautious.netPerKm,3900*.88/4.3);
        check(sample.cautiousMinutes>sample.favorableMinutes,"Cautious duration must be greater");
        check(sample.tier==1,"Uncertain ride should be yellow, not false green");
        check(TimeRiskModel.assess(3900,1.6,2.7,12,50000,900,0).tier==0,"Failing both -> red");
        check(TimeRiskModel.assess(10000,2,3,10,10000,500,0).tier==2,"Strong ride -> green");
        check(TimeRiskModel.assess(10000,2,3,10,10000,500,2).cautiousMinutes>sample.cautiousMinutes,
              "Extra stops should add time");
        check(OfferParser.parse("Maxim Argentina Mendoza\\\\n$10000\\\\nen efectivo\\\\n3 paradas\\\\n"+
                "1.8 km\\\\n7.2 km\\\\nHasta la direccion\\\\nLong. de la ruta\\\\nSolicitar").intermediateStops==2,
                "Multistop parser");
        System.out.println("CORE TESTS:''')
Path("README-v09.md").write_text("""Maxim Radar v0.9 - beta informativa.\nLa estimacion horaria usa un escenario lento conservador y otro rapido favorable, ambos heuristicas sin mapas.\nVerde solo si ambas metas pasan el escenario lento; rojo solo si ambas fallan aun con el rapido; amarillo si es incierto.\nMinutos ambiguos de Maxim no se interpretan como ETA. No se entrenan estimaciones con otras estimaciones.\nNo cambia los permisos, preferencias, ni la pantalla de inicio de v0.8.1.\n""")
print("Applied v0.9 source patch.")
