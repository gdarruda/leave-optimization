from datetime import datetime, timedelta
import minizinc
import enum

holidays = ['2021-01-25',
            '2021-02-15',
            '2021-02-16',
            '2021-03-26',
            '2021-03-29',
            '2021-03-30',
            '2021-03-31',
            '2021-04-01',
            '2021-04-21',
            '2021-05-01',
            '2021-06-03',
            '2021-09-07',
            '2021-10-12',
            '2021-11-02',
            '2021-11-15',
            '2021-11-20',
            '2021-12-25']

holidays = set([datetime.strptime(holiday, "%Y-%m-%d").date() for holiday in holidays])

def day_type(day: datetime):
    
    weekday = day.strftime('%A')
    
    if day in holidays:
        return 'Holiday'

    if weekday not in set(['Sunday', 'Saturday']):
        return 'Work'
    
    return weekday

def add_offset(day: datetime, offset: int):
    return (day + timedelta(days=offset-1))

start_day = datetime.strptime('2021-01-01', '%Y-%m-%d').date()
days = [start_day + timedelta(days=i) for i in range(365)]
calendar = [day_type(i) for i in days]
leave_days = 30
intervals = 3

model = minizinc.Model()
model.add_file('leave.mzn')

gecode = minizinc.Solver.lookup('gecode')
inst = minizinc.Instance(gecode, model)

inst['leave_days'] = leave_days
inst['intervals'] = intervals
inst['calendar'] = calendar

print(f"Início: {datetime.now()}")
result = inst.solve()
print(f"Fim: {datetime.now()}")

print(result)

leave_days = []

for seq, interval in enumerate(result['leave']):
    
    start_date = add_offset(start_day, interval[0])
    end_date = add_offset(start_day, interval[1])

    print(f'Intervalo {seq+1}: {start_date} - {end_date}')
    
    while (start_date <= end_date):
        leave_days.append(start_date)
        start_date = start_date + timedelta(days=1)
