enum WEEKDAY = {Work, Saturday, Sunday, Holiday};
array[int] of WEEKDAY: calendar;

int : leave_days;
int : intervals;

enum LEAVE = {Start, End};

array[1..intervals, LEAVE] of var 1..length(calendar): leave;

var int : total_leisure = sum([1 | day in 1..length(calendar) 
                               where calendar[day] != Work \/ 
                                     exists(i in 1..intervals)(day in leisure[i])]);

function var int: max_range(var int: i) = min(i, length(calendar));
function var int: min_range(var int: i) = max(i, length(calendar));

function var int: extra_leisure_after(int: offset, int: leave_seq) = forall(i in 1..offset)
                                                                        (if leave[leave_seq, End] + i < length(calendar) 
                                                                         then calendar[leave[leave_seq, End] + i] != Work 
                                                                         else false endif);


function var int: extra_leisure_before(int: offset, int: leave_seq) = forall(i in 1..offset)
                                                                             (if leave[leave_seq, Start] - i >= 1
                                                                              then calendar[leave[leave_seq, Start] - i] != Work 
                                                                              else false endif);

var int : extra_leisure = sum(i in 1..intervals)(sum(j in 1..5)(extra_leisure_after(j, i))) +
                          sum(i in 1..intervals)(sum(j in 1..5)(extra_leisure_before(j, i)));

var float : distance = product(i in 2..intervals)(leave[i, Start] - leave[i-1, End]);


% Os intervalos estão ordenados e com distância mínima
constraint forall(i in 2..intervals)(leave[i-1, End] + 5 < leave[i, Start]);

%Os intervalos tem começo e fim consistentes
constraint forall(i in 1..intervals)(leave[i, Start] < leave[i, End]);

%Um intervalo tem mais de 15 dias
constraint exists(i in 1..intervals)(leave[i, End] - leave[i, Start] + 1 >= 14);

%Todos intervalos tem mais de 5 dias
constraint forall(i in 1..intervals)(leave[i, End] - leave[i, Start] + 1 >= 5);

%O total de dias não é maior que o disponível
constraint sum(i in 1..intervals)(leave[i, End] - leave[i, Start] + 1) == leave_days;

%Garante que não começa antes de um feriado/fds
constraint forall(i in 1..intervals)(calendar[leave[i, Start]] == Work 
                                     /\ calendar[leave[i, Start] + 1] == Work
                                     /\ calendar[leave[i, Start] + 2] == Work);

%Garante que não termina na quinta-feira 
constraint forall(i in 1..intervals)(calendar[leave[i, End] + 1] != Work);

array[1..intervals] of var set of int: leisure = [{day | day in leave[i, Start]..leave[i, End]} | i in 1..intervals];

solve maximize total_leisure * 100 + extra_leisure;

% output ["\(sum(i in 1..intervals)(leave[i, End] - leave[i, Start] + 1))\n",
%         "\(extra_leisure)\n"];