import com.radarlocal.maxim.core.OfferParser;
import com.radarlocal.maxim.core.RealOfferModel;

public class CleanV094Tests {
    private static int checks=0;
    private static void check(boolean value,String note){checks++;if(!value)throw new AssertionError(note);}
    private static void near(double got,double expected,String note){check(Math.abs(got-expected)<0.02,note+": "+got+" vs "+expected);}
    public static void main(String[] args){
        String listed="Maxim Argentina Mendoza\n$3400\nen efectivo\nCalle Patricias Mendocinas,1385\n"+
           "Hospital Italiano\n4.6 km.\n11 min.\n1.3 km.\nHasta la dirección\nTiempo de entrega\nLong. de la ruta\nSolicitar";
        OfferParser.Offer list=OfferParser.parse(listed);
        check(list.complete(),"selected offer parsed");near(list.fare,3400,"price");
        near(list.pickupKm,4.6,"pickup distance");near(list.rideKm,1.3,"ride distance");
        near(list.rideMin,11,"delivery minutes really passenger leg");
        RealOfferModel.Outcome a=RealOfferModel.assess(3400,4.6,1.3,11.0,5,8000,450,0);
        near(a.perKm,3400*0.95/5.9,"5 percent per km");
        check(a.perHour!=null&&a.perHour>0,"hourly when Maxim provides ETA");
        String automatic="Confirmación ($2516)\nAR Maxim Mendoza, Estándar\n$6600\nen efectivo\n"+
             "Avenida San Martín 484\nEl Algarrobal\n1.5 km.\n11.1 km.\nHasta la dirección\n"+
             "Long. de la ruta\nEn el lugar dentro de 6 min.\nRechazar\nAceptar";
        OfferParser.Offer auto=OfferParser.parse(automatic);
        check(auto.complete(),"automatic confirmation parsed");
        near(auto.fare,6600,"header amount ignored");
        near(auto.pickupKm,1.5,"pickup auto");near(auto.rideKm,11.1,"ride auto");
        check(auto.rideMin==null,"arrival deadline not treated as duration");
        RealOfferModel.Outcome b=RealOfferModel.assess(6600,1.5,11.1,auto.rideMin,5,10000,450,0);
        near(b.perKm,6600*.95/12.6,"auto km computation");
        check(b.perHour==null,"no invented hourly figure");check(b.tier==1,"auto cannot be green");
        check(RealOfferModel.assess(6600,1.5,11.1,null,5,10000,800,0).tier==0,
              "auto red if km goal fails");
        check(RealOfferModel.assess(8000,2,3,9.0,5,6000,500,0).tier==2,
              "selected can be green when both goals pass");
        check(!OfferParser.parse("Confirmación ($2516)\nAceptar\nEn el lugar dentro de 6 min.").complete(),
              "never fabricate missing price or distances");
        System.out.println("CLEAN V0.9.4 TESTS: "+checks+" passed");
    }
}