classdef TitleComments
    %a new TitleComments object will be created for each new title in the
    %data file.  The comments corresponding to the same title will be
    %placed in the same object.

    properties
        %title will store the title of a topic as char array
        title
        
        %comments is an array of char array.
        %all of the comments associated with the title will be placed in
        %the comments array
        comments = []
    end

    %we want to be able to access the word bank for displaying purposes but
    %not be able to add any word to word bank externally.
    properties (GetAccess = public, SetAccess = private)
    wordsBank = [];
 %   TF_IDF = [];
    end

    methods

        %determine what happends when the value of property 'comments' is
        %set.  In this case, the 'comments' property is an array.  Evey
        %time a new comment is added to the object, a new cell is appended
        %to the end of the array and the comment is placed into that cell.
        function obj = set.comments(obj, value)
            totalComment = length(obj.comments);
            obj.comments{totalComment+1} = value;
        end

        %to return the wordBank, the following function is called.
        function wordB = get.wordsBank(obj)
            wordB = obj.generateWordBank();
        end

        %to get the TF_IDF matrix, the following function is called.
  %      function tf_mat = get.TF_IDF(obj)
   %         tf = obj.getTF_IDFMat();
    %        tf_mat = tf;
     %   end
        
        %return the word count matrix for the given set of title/comments
        function mat = getWordCountMatrix(obj)
            
            %generate a wordbank.
            wordBank = obj.generateWordBank();
            
            %get the total number of words in the word bank and create a
            %temporary array  of zeroz that has equal length as word bank
            %array and width equal to the number of comments.
            countMat = [];
            wordBankLength = length(wordBank);
            totalComments = length(obj.comments);
            
            %go through each comment.
            for i=1:totalComments
                tempCountMat = zeros(wordBankLength, 1);
                
                %break the comment into its words
                wordsInComment = regexp(obj.comments{i}, '(\w)*('')?(\w)*', 'match');
                wordsInComment = lower(wordsInComment);
                commentLength = length(wordsInComment);
                
                %match all the words in comment to the word bank and
                %increment the appropriate index.
                for j=1:commentLength
                    wordIndex = strmatch(wordsInComment{j}, wordBank, 'exact');
                    tempCountMat(wordIndex) = tempCountMat(wordIndex) + 1;
                end
                
                %combine the comment word count with other comments word
                %count to create a 2D matrix.
                countMat = [countMat tempCountMat];
            end
            
            %return the 2D word count matrix.
            mat = countMat;
        end

                %return the word count matrix for the given set of title/comments
        function mat = getWCCommentTitleMatrix(obj)
            
            %generate a wordbank.
            wordBank = obj.generateWordBank();
            
            %get the total number of words in the word bank and create a
            %temporary array  of zeroz that has equal length as word bank
            %array and width equal to the number of comments.
            countMat = [];
            wordBankLength = length(wordBank);
            totalComments = length(obj.comments);
            
            %go through each comment.
            for i=1:totalComments
                tempCountMat = zeros(wordBankLength, 1);
                
                %break the comment into its words
                wordsInComment = regexp(obj.comments{i}, '(\w)*('')?(\w)*', 'match');
                wordsInComment = lower(wordsInComment);
                commentLength = length(wordsInComment);
                
                %match all the words in comment to the word bank and
                %increment the appropriate index.
                for j=1:commentLength
                    wordIndex = strmatch(wordsInComment{j}, wordBank, 'exact');
                    tempCountMat(wordIndex) = tempCountMat(wordIndex) + 1;
                end
                
                %combine the comment word count with other comments word
                %count to create a 2D matrix.
                countMat = [countMat tempCountMat];
            end
            
            tempCountMat = zeros(wordBankLength, 1);

            %break the title into its words
            wordsInTitle = regexp(obj.title, '(\w)*('')?(\w)*', 'match');
            wordsInTitle = lower(wordsInTitle);
            titleLength = length(wordsInTitle);

            %match all the words in title to the word bank and
            %increment the appropriate index.
            for j=1:titleLength
                wordIndex = strmatch(wordsInTitle{j}, wordBank, 'exact');
                tempCountMat(wordIndex) = tempCountMat(wordIndex) + 1;
            end

            %combine the title word count with other comments word
            %count to create a 2D matrix.
            countMat = [countMat tempCountMat];

            %return the 2D word count matrix.
            mat = countMat;
        end
        
        %the input to this funtion is the title, and all of the comments
        %associated with that title as one long array of chars.
        %output is an array of the set of all the words contained in the
        %comments/title.  no duplicates allowed.
        function wb = generateWordBank(obj)
            
            %combine all of the words into one long array of chars
            allWords = obj.title;
            numComments = length(obj.comments);
            for i=1:numComments
                allWords = strcat(allWords, char('*'), obj.comments{i});
            end
            
            %break the char array down into words that match the pattern of
            %'(\w+)' which includes letter, numbers, and underscore.
            wordBank = regexpi(allWords, '(\w)*('')?(\w)*', 'match');
            
            %remove all repeats
            wordBank = unique(wordBank);
            
            %convert all words to lowercase
            wordBank = lower(wordBank);
            
            %return the list of unique words that were found in
            %title/comments group.
            wb = wordBank;
        end
        
        %this function returns the Term Frequency - Inverse Document
        %Frequency matrix.  Each element in this matrix corresponds with
        %the word count matrix.  The formula used is tf*idf.  where, tf =
        %wordCount/totalWordsInComment, idf =
        %log(totalDocCount/numDocsGivenWordAppearsIn+1) (plus 1 used to
        %prevent division by zero.
        function tf_idfMat = getTF_IDFMat(obj)
            
            %get the word Count matrix, total number of comments
            %(tempDimen[2]) and total words in word bank (tempDimen[1]).
            tempWcMat = obj.getWordCountMatrix();
            tempDimen = size(tempWcMat);
            
            %create a temporary matrix filled with zeros that corresponds
            %to the words in the word count.
            tempTF = zeros(tempDimen(1),tempDimen(2));
            
            %totalWordsPerComment will hold the total number of words
            %contained in the comment.  totalWordsDocument variable will
            %hold the total number of documents (comments) a word appears
            %in.
            totalWordsPerComment = zeros(tempDimen(2), 1);
            totalWordsDocument = zeros(tempDimen(1), 1);
            
            %populate totalWordPerComment and totalWordsDocument variables
            for i=1:tempDimen(2)
                tempSum = 0;
                
                %add all of the number in the word count matrix columns
                %(each column represents words in single comment)
                for j=1:tempDimen(1)
                    if(tempWcMat(j,i) > 0)
                        tempSum = tempSum + tempWcMat(j,i);
                        totalWordsDocument(j)  = totalWordsDocument(j) + 1;
                    end
                end
                totalWordsPerComment(i) = tempSum;
                
                %get the TF portion of the TF-IDF formula and store the
                %value into tempTF. then repeat the process of remaining
                %comments.
                for j=1:tempDimen(1)
                    tempTF(j, i) = tempWcMat(j, i)/totalWordsPerComment(i);
                end
            end
            
            %calculate the IDF portion of TF-IDF and combine the TF and IDF
            %portions of the formula and save the value back into tempTF
            %matrix.
            for i=1:tempDimen(2)
                for j=1:tempDimen(1)
                    if(tempWcMat(j,i) > 0)
                        tempTF(j,i)  = tempTF(j,i)*log(abs((tempDimen(2))/(1+abs(totalWordsDocument(i)))));
                    end
                end
            end
            
            %return the matrix 
            tf_idfMat = tempTF;
        end
        
        function tf_idfMat = getTF_IDFMatTitle(obj)
            
            %get the word Count matrix, total number of comments n title
            %(tempDimen[2]) and total words in word bank (tempDimen[1]).
            tempWcMat = obj.getWCCommentTitleMatrix();
            tempDimen = size(tempWcMat);
            
            %create a temporary matrix filled with zeros that corresponds
            %to the words in the word count.
            tempTF = zeros(tempDimen(1),tempDimen(2));
            
            %totalWordsPerComment will hold the total number of words
            %contained in the comment or title.  totalWordsDocument 
            %variable will hold the total number of documents (comments) 
            %a word appears in.
            totalWordsPerComment = zeros(tempDimen(2), 1);
            totalWordsDocument = zeros(tempDimen(1), 1);
            
            %populate totalWordPerComment and totalWordsDocument variables
            for i=1:tempDimen(2)
                tempSum = 0;
                
                %add all of the number in the word count matrix columns
                %(each column represents words in single comment)
                for j=1:tempDimen(1)
                    if(tempWcMat(j,i) > 0)
                        tempSum = tempSum + tempWcMat(j,i);
                        totalWordsDocument(j)  = totalWordsDocument(j) + 1;
                    end
                end
                totalWordsPerComment(i) = tempSum;
                
                %get the TF portion of the TF-IDF formula and store the
                %value into tempTF. then repeat the process of remaining
                %comments.
                for j=1:tempDimen(1)
                    tempTF(j, i) = tempWcMat(j, i)/totalWordsPerComment(i);
                end
            end
            
            %calculate the IDF portion of TF-IDF and combine the TF and IDF
            %portions of the formula and save the value back into tempTF
            %matrix.
            for i=1:tempDimen(2)
                for j=1:tempDimen(1)
                    if(tempWcMat(j,i) > 0)
                        tempTF(j,i)  = tempTF(j,i)*log(abs((tempDimen(2))/(1+abs(totalWordsDocument(i)))));
                    end
                end
            end
            
            %return the matrix 
            tf_idfMat = tempTF;
        end
        
        function CCMat = getCommentComparisonMat(obj, perLen, angleDeg, tl)
            %get the wordcount matrix
            wordCount = obj.getWCCommentTitleMatrix();
            
             %produce the singular value decomposition
            [U, S, V] = svds(wordCount, 2);
            
            %prepare data for 2D plot
            Z = inv(S)*U'*wordCount;
            
            tempMat = zeros(size(Z,2),3);
            for i=1:length(tempMat)
                tempMat(i,1) = distance(Z(1,i), 0, Z(2,i), 0);
                tempAngle = atan2(Z(2,i),Z(1,i))*180/pi;
                if(tempAngle <0)
                    tempMat(i,2) = 360+tempAngle;
                else
                    tempMat(i,2) = tempAngle;
                end
            end
            leng = length(tempMat);
            for i=1:leng-1
                if(tempMat(i,1)<(1+perLen/100)*tempMat(leng,1) && tempMat(i,1)>(1-perLen/100)*tempMat(leng,1))
                    if(tempMat(i,2) < tempMat(leng,2)+angleDeg && tempMat(i,2) > tempMat(leng,2)-angleDeg)
                        tempMat(i,3) = 1;
                    else
                        tempMat(i,3) = 3;
                    end
                else
                    tempMat(i,3) = 3;
                end
                if(length(obj.comments{i})<tl)
                    tempMat(i,3) = 2;
                end
            end
            CCMat = tempMat;
        end
        
        function producePlot(obj)
            
            %get the wordcount matrix
            wordCount = obj.getWCCommentTitleMatrix();
            
            %produce the singular value decomposition
            [U, S, V] = svds(wordCount, 2);
            
            %prepare data for 2D plot
            Z = inv(S)*U'*wordCount;
            
            %create a figure
            figA = figure(1);
            
            %set the figure window title to title from object
            set(figA, 'name', obj.title);
            %clear the figure
            clf;
            
            %get the total number of comments in object
            totalComments = size(Z,2);
            
            %plot the lines
            for i=1:totalComments
                
              %use 'o' as the symbol for plot
              plotA = plot(Z(1,i), Z(2,i), 'o');
              title(obj.title, 'Color', 'black', 'FontSize', 12);
              
              %if the current line to be plotted is the last line, its the
              %title.  Color it red, else color the line blue
              if(i == totalComments)
                  set(plotA, 'Color', 'red');
                  hold on
                  
                  %plot 'T'
                  textA=text(Z(1,i), Z(2,i), sprintf('%s', 'T'));
                  set(textA, 'Color', 'red');
                  lineA = line([0 Z(1,i)], [0 Z(2,i)]);
                  set(lineA, 'Color', 'red');
              else
                  set(plotA, 'Color', 'blue');
                  hold on
                  
                  %plot 'Cx' where x is the comment number.
                  textA=text(Z(1,i), Z(2,i), sprintf('%s%d', 'C', i));
                  set(textA, 'Color', 'blue');
                  lineA = line([0 Z(1,i)], [0 Z(2,i)]);
                  set(lineA, 'Color', 'blue');
              end
            end
        end
        
        function producePlotCoded(obj, perLen, angleDeg, tl)
            
            %get the wordcount matrix
            wordCount = obj.getWCCommentTitleMatrix();
            colorCode = obj.getCommentComparisonMat(perLen,angleDeg,tl);
            
            %produce the singular value decomposition
            [U, S, V] = svds(wordCount, 2);
            
            %prepare data for 2D plot
            Z = inv(S)*U'*wordCount;
            
            %create a figure
            figA = figure(1);
            
            %set the figure window title to title from object
            set(figA, 'name', obj.title);
            %clear the figure
            clf;
            
            %get the total number of comments in object
            totalComments = size(Z,2);
            
            %plot the lines
            for i=1:totalComments
                
              %use 'o' as the symbol for plot
              plotA = plot(Z(1,i), Z(2,i), 'o');
              title(obj.title, 'Color', 'black', 'FontSize', 12);
              
              %if the current line to be plotted is the last line, its the
              %title.  Color it red, else color the line blue
              if(i == totalComments)
                  color = 'red';
                  set(plotA, 'Color', color);
                  hold on
                  
                  %plot 'T'
                  textA=text(Z(1,i), Z(2,i), sprintf('%s', 'T'));
                  set(textA, 'Color', color);
                  lineA = line([0 Z(1,i)], [0 Z(2,i)]);
                  set(lineA, 'Color', color);
              else
                  if(colorCode(i,3) == 1)
                      color = 'green';
                  else if(colorCode(i,3) == 2)
                        color = 'blue';
                      else
                          color = 'magenta';
                      end
                  end
                  set(plotA, 'Color', color);
                  hold on
                  
                  %plot 'Cx' where x is the comment number.
                  textA=text(Z(1,i), Z(2,i), sprintf('%s%d', 'C', i));
                  set(textA, 'Color', color);
                  lineA = line([0 Z(1,i)], [0 Z(2,i)]);
                  set(lineA, 'Color', color);
              end
            end
        end
        
        function producePlotTFIDF(obj)
            
            %get the wordcount matrix
            tfidfMat = obj.getTF_IDFMatTitle();
            
            %produce the singular value decomposition
            [U, S, V] = svds(tfidfMat, 2);
            
            %prepare data for 2D plot
            Z = inv(S)*U'*tfidfMat;
            
            %create a figure
            figA = figure(1);
            
            %set the figure window title to title from object
            set(figA, 'name', obj.title);
            
            %clear the figure
            clf;
            
            %get the total number of comments in object
            totalComments = size(Z,2);
            
            %plot the lines
            for i=1:totalComments
                
              %use 'o' as the symbol for plot
              plotA = plot(Z(1,i), Z(2,i), 'o');
              title(obj.title, 'Color', 'black', 'FontSize', 12);
              
              %if the current line to be plotted is the last line, its the
              %title.  Color it red, else color the line blue
              if(i == totalComments)
                  set(plotA, 'Color', 'red');
                  hold on
                  
                  %plot 'T'
                  textA=text(Z(1,i), Z(2,i), sprintf('%s', 'T'));
                  set(textA, 'Color', 'red');
                  lineA = line([0 Z(1,i)], [0 Z(2,i)]);
                  set(lineA, 'Color', 'red');
              else
                  set(plotA, 'Color', 'blue');
                  hold on
                  
                  %plot 'Cx' where x is the comment number.
                  textA=text(Z(1,i), Z(2,i), sprintf('%s%d', 'C', i));
                  set(textA, 'Color', 'black');
                  lineA = line([0 Z(1,i)], [0 Z(2,i)]);
                  set(lineA, 'Color', 'blue');
              end
            end
        end
        
        function producePlotTFIDFCoded(obj, perLen, angleDeg, tl)
            
            %get the wordcount matrix
            tfidfMat = obj.getTF_IDFMatTitle();
            colorCode = obj.getCommentComparisonMat(perLen,angleDeg,tl);
            
            %produce the singular value decomposition
            [U, S, V] = svds(tfidfMat, 2);
            
            %prepare data for 2D plot
            Z = inv(S)*U'*tfidfMat;
            
            %create a figure
            figA = figure(1);
            
            %set the figure window title to title from object
            set(figA, 'name', obj.title);
            
            %clear the figure
            clf;
            
            %get the total number of comments in object
            totalComments = size(Z,2);
            
            %plot the lines
            for i=1:totalComments
                
              %use 'o' as the symbol for plot
              plotA = plot(Z(1,i), Z(2,i), 'o');
              title(obj.title, 'Color', 'black', 'FontSize', 12);
              
              %if the current line to be plotted is the last line, its the
              %title.  Color it red, else color the line blue
              if(i == totalComments)
                  color = 'red';
                  set(plotA, 'Color', color);
                  hold on
                  
                  %plot 'T'
                  textA=text(Z(1,i), Z(2,i), sprintf('%s', 'T'));
                  set(textA, 'Color', color);
                  lineA = line([0 Z(1,i)], [0 Z(2,i)]);
                  set(lineA, 'Color', color);
              else
                  if(colorCode(i,3) == 1)
                      color = 'green';
                  else if(colorCode(i,3) == 2)
                        color = 'blue';
                      else
                          color = 'magenta';
                      end
                  end
                  set(plotA, 'Color', color);
                  hold on
                  
                  %plot 'Cx' where x is the comment number.
                  textA=text(Z(1,i), Z(2,i), sprintf('%s%d', 'C', i));
                  set(textA, 'Color', color);
                  lineA = line([0 Z(1,i)], [0 Z(2,i)]);
                  set(lineA, 'Color', color);
              end
            end
        end
        
        function generateTable(obj)
            compMat = obj.getCommentComparisonMat(200, 10, 5);
            wc = obj.getWCCommentTitleMatrix();
            wordsincommon = zeros(size(wc, 2),1);
            wordcount = zeros(size(wc, 2), 1);
            percentCommon =  zeros(size(wc, 2), 1);
            commentCode = [length(wordcount),1];
            commentNames = {length(wordcount)};
            tabledata = zeros(size(wc, 2), 3);
            for i=1:length(wc)
                for j=1:length(wordcount)
                    wordcount(j) = wordcount(j) + wc(i,j);
                end
                if(wc(i,length(wordsincommon)) > 0)
                    for j=1:length(wordsincommon)
                        wordsincommon(j) = wordsincommon(j) + wc(i,j);
                    end
                end
            end
            for i=1:length(wordcount)
                if(i == length(wordcount))
                    commentNames{i} = 'T';
                else
                    commentNames{i} = sprintf('%s%d', 'C', i);
                end
            end
            
            for i=1:length(wordcount)
                percentCommon(i) = wordsincommon(i)/wordcount(i)*100;
            end
            
            for i=1:length(wordcount)
                tabledata(i,1) = wordcount(i);
                tabledata(i,2) = wordsincommon(i);
                tabledata(i,3) = round(percentCommon(i));
            end
            
            clf;
            uiTbl = uitable;
            set(uiTbl, 'Position', [0 0 337 400]);
            uiTblName = {'Total Words', 'Words in Common', 'Percent in Common'};
        %    set(uiTbl, 'PaperUnits','inches','PaperPosition',[0 0 4 3]);
            set(uiTbl, 'Data', tabledata, 'ColumnName', uiTblName, 'RowName', commentNames, 'ColumnWidth', {'auto'});

            
        end
    end
end

