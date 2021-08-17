TO RUN: 
>> db = LSAFunctions.generateDataBase('IBMFeed_Matlab.dat');
 
Once you receive, "Database generated successfully!" Run 

>> db{12}.producePlot
>> db{12}.producePlotCoded(400, 10, 2)
>> db{12}.generateTable() 
%produces the table that lists the total words, and words in common with title.