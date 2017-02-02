import java.util.Scanner;
import java.lang.Math;
public class Notes {
  public static void main(String args[]) {
    Scanner in = new Scanner(System.in);

    while (in.hasNext()) {
      String note = in.next().trim();
      double freq  = in.nextDouble();
      int div =(int) Math.round(40000000/freq); 
      System.out.println(note + "," + div + "," + ((int)(1000*Math.abs(freq - (40000000./div))))/1000.);

    }

    

  }



}
