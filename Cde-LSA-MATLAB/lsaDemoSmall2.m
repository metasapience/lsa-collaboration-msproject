function lsaDemoSmall2()
% By Kevin Murphy
% Based on a tutorial by Genevieve Gorrell
% http://www.dcs.shef.ac.uk/~genevieve/lsa_tutorial.htm
% See also http://en.wikipedia.org/wiki/Latent_semantic_analysis

sentence{1} = 'the man walked the dog.';
sentence{2} = 'the man took the dog to the park';
sentence{3} = 'the dog went to the park';
N = length(sentence);
words = [];
for i=1:N
  w = regexp(sentence{i}, '(\w+)', 'match');
  words = [words w];
end
words = unique(words);

% to facilitate comparison with the tutorial, we sort the words as follows
words = {'the', 'man', 'walked', 'dog', 'took', 'to', 'park', 'went'};

% Now build term-document matrix
W =  length(words);
X = zeros(W, N);
for i=1:N
  X(:,i) = X(:,i) + sentenceToWordCount(sentence{i}, words);
end

% truncated SVD
K = 2;
[U, S, V] = svds(X, 2);

% add test data to word-document matrix
query = 'the dog walked';
x = sentenceToWordCount(query, words);
%x = x/norm(x);
X(:,N+1) = x;

% embed all data into low dim space and plot
Z = inv(S)*U'*X;
figure(1);clf;
ndoc = size(Z,2);
for i=1:ndoc
  plot(Z(1,i), Z(2,i), 'o');
  hold on
  h=text(Z(1,i), Z(2,i), sprintf('%d', i)); set(h,'fontsize',15);
  line([0 Z(1,i)], [0 Z(2,i)]);
end

% compute pairwise similarities  using dot product
%simMat = Z'*Z;

% compute pairwise similarities  using cosine measure
for i=1:ndoc
  for j=i+1:ndoc
    simMat2(i,j) = abs(Z(:,i)'*Z(:,j) / (norm(Z(:,i)) * norm(Z(:,j))));
  end
end

%%%%%%%%%


function v = sentenceToWordCount(s, words)

tokens = regexp(s, '(\w+)', 'match');
v = zeros(length(words),1);
for j=1:length(tokens)
  k = strmatch(tokens{j}, words, 'exact');
  v(k) = v(k) + 1;
end
