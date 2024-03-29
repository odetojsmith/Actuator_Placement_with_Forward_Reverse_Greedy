%adjf = [0 5 2 0 5; 0 0 0 0 5; 0 0 0 4 0; 0 0 2 0 4; 0 0 0 2 0];
%adjcf = [0 5 5 0 5; 0 0 0 0 5; 0 0 0 5 0; 0 0 0 0 5; 0 5 0 0 0];

%[a,b]=AugmentShortestPath(adjf,adjcf);

% ##adjcf = [0 3 6 0 0 0;
% ##         0 0 0 0 5 0;
% ##         0 0 0 8 0 0;
% ##         0 0 0 0 9 3;
% ##         0 0 0 0 0 2;
% ##         0 0 0 0 0 0];
% ##[valf, adjMf] = findMaxflow(adjcf)
% 
% ##adjG = [0 1 1; 1 0 0; 1 0 0];
% ##inputNode = [2];
% ##tellSCornot(adjG, inputNode)

% load the data
clear all
addpath('./NetworkAnalysisTool');
load A_118_1.mat % 118-bus power system data
% Prelimary information
adjG = A;
% load adjDegree.mat
adjG = adjG - diag(diag(adjG));
adjG = adjG;
%adjGO = randomGraph(10,0.4);
%adjG = giantComponent(adjGO);
K = 50;                  % Cardinality constraints  
ep = 1e-10;              % Epsilon
T = 1;                  % Integration termination time
Div = 100;              % Integration resolution (division of the total time)
switchM = 1;
n_uncon = 54;

% Measure the graph 
[x_1,y_1] = size(adjG);
adjG_topo = zeros(x_1,y_1);
adjG_topo = (adjG ~= 0);
if x_1 ~= y_1 
  error('Adj not square!');
end
if isConnected(abs(adjG)) == 0
    error(' The graph entered is not connected.');
end

% Give the topological information for the graph.

% Determine whether the cardinality constraint is adequate.
CardEnoicon = isCardEnough(adjG_topo,K,x_1);
if CardEnoicon == 0
  error(' The allowed cardinality is too small! ');
end

% Initialize the flow graph
tic
inputNode = [];
potSelection = [];
auxGSTadj = zeros(3 * x_1 + 2,3 * x_1 + 2);
auxGSTadj(2 : (x_1 + 1) , (2 * x_1+2):(3 * x_1 + 1)) = adjG_topo;
auxGSTadj(1 , 2 : (2 * x_1 + 1) ) = ones(1,2 * x_1);
auxGSTadj((2 * x_1 + 2) : (3 * x_1 + 1) , 3 * x_1 + 2) = ones(x_1,1);

% Augment the node set
for i = 1 : K
    i
   % List all the feasible nodes to add
  for j = n_uncon+1 : y_1
    if ismember(j,inputNode) ~= 1
      % Modify the flow graph
      inputNode_copy = inputNode;
      inputNode_copy = [inputNode_copy j];
      auxGSTadj_copy = auxGSTadj;
      auxGSTadj_copy(x_1 + j + 1, 2 * x_1 + j + 1) = 1; 
    else
      continue
    end
    % Use mas flow to verify whether feasible
    [valf,adjMf] = findMaxflow(auxGSTadj_copy);
    if valf < (x_1 - K + i) && min(switchM,1) > 0
      continue
    else
    potSelection = [potSelection j];
    end
  end
  
  % Calculate costs for each actuator set and pick the set with the least
  % energy costs
  multiObj = [];
  for k = 1 : length(potSelection)
    valobj = obj2(T,Div,adjG,[inputNode potSelection(k)],ep);
    multiObj = [multiObj valobj];
  end
  [maxobj,newSelectionind] = min(multiObj);
  newSelection = potSelection(newSelectionind);
  inputNode = [inputNode newSelection];
  auxGSTadj(x_1 + newSelection + 1 , 2 * x_1 + newSelection + 1) = 1;
  potSelection = [];
end
toc

% Print the nodes and the costs
inputNode
objep = obj2(T,Div,adjG,inputNode,ep)
obj0 = obj2(T,Div,adjG,inputNode,0)

