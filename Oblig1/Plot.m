%want to achive something like the following:
s = [1 2 4 5 6 7];
t = [2 3 5 6 7 8];
w = [1 1 2 2 2 2];
names = {'H1' 'p10' 'd10' 'H2' 'p4' 'p8' 'd8' 'd4'};
G = digraph([1 1], [2 3]);
G = addnode(G,1);

plot(G);



