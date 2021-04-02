from datetime import datetime, timedelta
from typing import List
import minizinc

start_date = '2021-01-01'
end_date = '2021-12-31'

leave_days = 30
intervals = 3

holidays = ['2021-01-25',
            '2021-02-15',
            '2021-02-16',
            # Feriado SP
            '2021-03-26',
            '2021-03-29',
            '2021-03-30',
            '2021-03-31',
            '2021-04-01',
            # Feriado SP
            '2021-04-02',
            '2021-04-21',
            '2021-05-01',
            '2021-06-03',
            '2021-09-07',
            '2021-10-12',
            '2021-11-02',
            '2021-11-15',
            '2021-11-20',
            '2021-12-25']

def day_type(day: datetime, 
             holidays: List[datetime]) -> str:
    
    weekday = day.strftime('%A')
    
    if day in holidays:
        return 'Holiday'

    if weekday not in set(['Sunday', 'Saturday']):
        return 'Work'
    
    return weekday

def build_calendar(start_date: str, 
                   end_date: str,
                   holidays: List[str]) -> List[float]:

    start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
    end_date = datetime.strptime(end_date, '%Y-%m-%d').date()
    holidays = set([datetime.strptime(holiday, "%Y-%m-%d").date() 
                    for holiday in holidays])

    return [day_type(start_date + timedelta(days=i), holidays)
            for i in range((end_date - start_date).days + 1)]

calendar = build_calendar(start_date, end_date, holidays)

with open('leave.dzn', 'w') as writer:
    writer.write(f"calendar = [{','.join(calendar)}];\n")
    writer.write(f"leave_days = {leave_days};\n")
    writer.write(f"intervals = {intervals};\n")

model = minizinc.Model()
model.add_file('leave.mzn')

gecode = minizinc.Solver.lookup('gecode')

inst = minizinc.Instance(gecode, model)
inst['leave_days'] = leave_days
inst['intervals'] = intervals
inst['calendar'] = calendar

print(f"Início: {datetime.now().strftime('%H:%M:%S')}")
result = inst.solve(processes=6)
print(f"Fim: {datetime.now().strftime('%H:%M:%S')}")
print("")
print(result)

def add_offset(day: str, offset: int):
    return (datetime.strptime(day, "%Y-%m-%d").date() + timedelta(days=offset-1))

for seq, interval in enumerate(result['leave']):
    
    start_day = add_offset(start_date, interval[0])
    end_day = add_offset(start_date, interval[1])

    print(f'Intervalo {seq+1}: {start_day} - {end_day}')

