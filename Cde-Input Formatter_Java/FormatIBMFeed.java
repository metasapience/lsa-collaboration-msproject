

import java.io.*;
import java.util.StringTokenizer;

public class FormatIBMFeed {


	public static void main(String[] args) {
		File inputFile = new File("IBMFeed.dat");
		File outputFile = new File("IBMFeed_Matlab.dat");
		FileReader fr;
		BufferedReader br;
		FileWriter fw;
		BufferedWriter bw;
		try{
			fr = new FileReader(inputFile);
			fw = new FileWriter(outputFile);
			br = new BufferedReader(fr);
			bw = new BufferedWriter(fw);
			String tempStr;
			String tempToken;
			String title;
			StringTokenizer st;
			int firstIndex = 0;
			int lastIndex = 0;
			while((tempStr = br.readLine()) != null){
				st = new StringTokenizer(tempStr);
				if(st.countTokens() < 4){
					continue;
				}
				tempToken = st.nextToken();
				if(!tempToken.equalsIgnoreCase("from")){
					continue;
				}
				System.out.println(tempStr);
				firstIndex = tempStr.indexOf('\'');
				lastIndex = tempStr.lastIndexOf('\'');
				title = tempStr.substring(firstIndex+1, lastIndex);
				System.out.println(title);
				bw.write("\"" + title + "\",\"");
				
				if((tempStr = br.readLine()) != null){
					System.out.println(tempStr);
					bw.write(tempStr);
					while((tempStr = br.readLine()) != null){
						st = new StringTokenizer(tempStr);
						if(st.countTokens() < 1){
							break;
						}
						tempToken = st.nextToken();
						if(tempToken.equalsIgnoreCase("add")){
							tempToken = st.nextToken();
							if(tempToken.equalsIgnoreCase("starLikeShareShare")){
								break;
							}
							else{
								System.out.println(tempStr);
								bw.write(" " + tempStr);
							}
						}
					}
					bw.write(" \"\n");
				}
				
				
			}
			bw.flush();
			bw.close();
			fw.close();
			br.close();
			fr.close();
		} catch (Exception e){e.printStackTrace();}

	}

}
