enum DAYTYPE = {Work, Saturday, Sunday, Holiday};
array[int] of DAYTYPE: calendar;

int : leave_days;
int : intervals;

enum LEAVE = {Start, End};

array[1..intervals, LEAVE] of var 1..length(calendar): leave;

% Os intervalos estão ordenados e com distância mínima
constraint forall(i in 2..intervals)(leave[i-1, End] + 7 <= leave[i, Start]);

%Os intervalos tem começo e fim consistentes
constraint forall(i in 1..intervals)(leave[i, Start] < leave[i, End]);

%Um intervalo tem mais de 15 dias
constraint exists(i in 1..intervals)(leave[i, End] - leave[i, Start] + 1 >= 14);

%Todos intervalos tem mais de 5 dias
constraint forall(i in 1..intervals)(leave[i, End] - leave[i, Start] + 1 >= 5);

%O total de dias é igual ao disponível
constraint sum(i in 1..intervals)(leave[i, End] - leave[i, Start] + 1) == leave_days;

%Garante que não começa antes de um feriado/fds
constraint forall(i in 1..intervals)(calendar[leave[i, Start]] == Work 
                                     /\ calendar[leave[i, Start] + 1] == Work
                                     /\ calendar[leave[i, Start] + 2] == Work);

%Garante que não termina um dia antes de outra folga 
constraint forall(i in 1..intervals)(calendar[leave[i, End] + 1] != Work);

var int : total_leisure = sum([calendar[day] != Work \/
                               exists(i in 1..intervals)(day >= leave[i, Start] 
                                                      /\ day <= leave[i, End]) 
                              | day in 1..length(calendar)]);

function var int: extra_leisure_after(int: offset, int: leave_seq) = forall(i in 1..offset)
                                                                        (if leave[leave_seq, End] + i <= length(calendar) 
                                                                         then calendar[leave[leave_seq, End] + i] != Work 
                                                                         else false endif);


function var int: extra_leisure_before(int: offset, int: leave_seq) = forall(i in 1..offset)
                                                                             (if leave[leave_seq, Start] - i >= 1
                                                                              then calendar[leave[leave_seq, Start] - i] != Work 
                                                                              else false endif);

var int : extra_leisure = sum(i in 1..intervals)(sum(j in 1..5)(extra_leisure_after(j, i))) +
                          sum(i in 1..intervals)(sum(j in 1..5)(extra_leisure_before(j, i)));

array[1..intervals-1] of var int : distances = [leave[i, Start] - leave[i-1, End] | i in 2..intervals];
var float : mean_distance = sum(distances) / intervals;
var float : variance = sum(i in 1..intervals-1)(abs(distances[i] - mean_distance)) / (intervals - 1);


solve maximize (total_leisure + extra_leisure) * 1000
               + mean_distance - variance;

output ["total_leisure = \(total_leisure)\n",
        "extra_leisure = \(extra_leisure)\n",
        "distances = \(distances)\n",
        "mean_distance = \(mean_distance)\n",
        "variance = \(variance)\n",
        ];