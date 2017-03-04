import java.util.Scanner;
import java.io.File;

class ConvCopyRoutine {
	public static void main(String args[]) throws Exception {
		String buf = "";
		Scanner in = new Scanner(new File("../Assembly/CopyRoutine.S68"));
		int div = 0;
		while (in.hasNextLine()) {
			String line = in.nextLine();
			if (!line.startsWith("S2")) continue;
			for (int i = 10; i < line.length() - 2; i+=2) {
				if (div++ % 24 == 0) System.out.print("\n            DC.B ");
				else System.out.print(",");
				System.out.print("$" + line.charAt(i));
				System.out.print(line.charAt(i+1));


			}
			
		}
		System.out.println();


	}
}
