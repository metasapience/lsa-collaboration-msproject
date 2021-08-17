% Functions that will help perform LSA on sample data

classdef LSAFunctions
    
    %the methods are declared static so an object is not need to use
    %the functions.
    methods (Static)
        
        %Create the comments/title database from file 'fileName'.
        function database = generateDataBase(fileName)
            disp('This may take a few minutes for large data set.');
            disp('Please be patient while the database is being generated...');
            %creat an array of TitleComments objects to store the data
            titleComments = [];
            
            %add the first object to the array
            titleComments{1} = TitleComments;
            
            %open the file for reading (input file stream = ifs)
            ifs = fopen(fileName);
            
            %discard the first line (it contains headings for each column)
            %for our datafile
            fgetl(ifs);

            %capture a line from the data file.
            line = fgetl(ifs);
            
            %break the line down into tokens of string - using quotes (")
            %as delimiter. 
            breakline = regexpi(line, '\"', 'split');
            
            %from experimentation, it is known that the second index of
            %breakline is the title and forth index is the comment
            %associated with the title.  Convert the text into lowercase to
            %make comparison easier.
            titleComments{1}.title = lower(breakline{2});
            titleComments{1}.comments = lower(breakline{4});
                
            %at this point, one object exists in the array.  from this
            %point forward, we must compare the to all TitleComments
            %objects in the array.  if one of the object's title matches
            %with the title of current line, then this line's comment will
            %be added to that object.  If the title doesnt match with any
            %of the object in the array, then a new object will be created
            %with that title and the corresponding comment will be added to
            %that object. The process will continue with next line in
            %data file until end of file is reached (feof)
            while(~feof(ifs))
                
                %capture a line from the data file.
                line = fgetl(ifs);
                
                %break the line down into tokens of string - using quotes "
                %as delimiter. 
                breakline = regexpi(line, '\"', 'split');
                if(length(breakline) < 4)
                    continue;
                end
                %determine how many TitleComments objects are in the
                %totalTitles array.  and iterate through all of them to see
                %if the title matches with any of them.  Variable
                %titleContainedInArray will be set to 1 if the title
                %matches the title of one of the objects in titleComments
                %array
                titleContainedInArray = 0;
                totalTitles = length(titleComments);
                for i=1:totalTitles
                    if(strcmpi(titleComments{i}.title, breakline{2}) == 1)
                        titleComments{i}.comments = breakline{4};
                        titleContainedInArray = 1;
                        break;
                    end
                end
                %this portion of the code will likely need to be tweaked to
                %improve database generation time.  
                if(titleContainedInArray == 0) %new title
                    titleComments{totalTitles + 1} = TitleComments;
                    titleComments{totalTitles + 1}.title = breakline{2};
                    titleComments{totalTitles + 1}.comments = breakline{4};
                end
            end
            disp('Database generated successfully!');
            database = titleComments;
        end
        
                %Create the comments/title database from file 'fileName'.
        function database = generateDataBaseSortedFile(fileName)
            disp('This may take a few minutes for large data set.');
            disp('Please be patient while the database is being generated...');
            %creat an array of TitleComments objects to store the data
            titleComments = [];
            
            %add the first object to the array
            titleComments{1} = TitleComments;
            
            %open the file for reading (input file stream = ifs)
            ifs = fopen(fileName);
            
            %discard the first line (it contains headings for each column)
            %for our datafile
            %fgetl(ifs);

            %capture a line from the data file.
            line = fgetl(ifs);
            
            %break the line down into tokens of string - using quotes (")
            %as delimiter. 
            breakline = regexpi(line, '\"', 'split');
            
            %from experimentation, it is known that the second index of
            %breakline is the title and forth index is the comment
            %associated with the title.  Convert the text into lowercase to
            %make comparison easier.
            titleComments{1}.title = lower(breakline{2});
            titleComments{1}.comments = lower(breakline{4});
            titleCount = 2;
            %at this point, one object exists in the array.  from this
            %point forward, we must compare the to all TitleComments
            %objects in the array.  if one of the object's title matches
            %with the title of current line, then this line's comment will
            %be added to that object.  If the title doesnt match with any
            %of the object in the array, then a new object will be created
            %with that title and the corresponding comment will be added to
            %that object. The process will continue with next line in
            %data file until end of file is reached (feof)
            while(~feof(ifs))
                
                %capture a line from the data file.
                line = fgetl(ifs);
                
                %break the line down into tokens of string - using quotes "
                %as delimiter. 
                breakline = regexpi(line, '\"', 'split');
                if(length(breakline) < 4)
                    continue;
                end
                while(strcmpi(titleComments{titleCount-1}, breakline{2})==1 && ~feof(ifs))
                    titleComments{titleCount-1}.comments = breakline{4};
                    titleCount = titleCount + 1;
                    line = fgetl(ifs);
                     breakline = regexpi(line, '\"', 'split');
                        if(length(breakline) < 4)
                            continue;
                        end
                end
                titleComments{titleCount}.title = breakline{2};
                titleComments{titleCount}.comments = breakline{4};

            end
            disp('Database generated successfully!');
            database = titleComments;
        end
        
        function tom = tenOrMore(db, numComments)
            tenOrmore = zeros(40,1);
            inc = 1;
            for i=1:length(db)
                if(length(db{i}.comments) > numComments)
                   tenOrMore(inc) = i;
                   inc = inc + 1;
                end
            end
            tom = tenOrMore;
        end
%functions moved to TitleComment Object
    end
end