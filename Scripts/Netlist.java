import java.util.Scanner;
import java.util.ArrayList;
public class Netlist {
  public static void main(String args[]) {
    Scanner in = new Scanner(System.in);
    //NET ADC_Busy 	LOC=P19;
    String line;

    ArrayList<String> list = new ArrayList<>();
    ArrayList<String> list2 = new ArrayList<>();
    while (!(line = in.nextLine()).equals("end")) {
      list.add(line);
      
    }

    
    while (!(line = in.nextLine()).equals("end")) {
      list2.add(line);
    }
    for (int i=0;i<list.size();i++)System.out.println("NET " + list.get(i) + "\t" + "LOC=P" + list2.get(i) + ";");;	

  }



}
