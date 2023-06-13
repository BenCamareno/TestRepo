import datetime

def is_first_weekday_of_month(weekday):
    today = datetime.date.today()
    first_day_of_month = datetime.date(today.year, today.month, 1)

    if first_day_of_month.weekday() == weekday and today.day <= 7:
        return True
    else:
        return False

# Iterate over the months of the current year
for month in range(1, 13):
    # Create a datetime object representing the first day of the month
    first_day_of_month = datetime.date(datetime.date.today().year, month, 1)
    weekday = first_day_of_month.weekday()
    weekday_name = datetime.date.today().strftime('%A')

    # Check if it is the first occurrence of the weekday in the month
    if is_first_weekday_of_month(weekday):
        print(f"The first {weekday_name} of {first_day_of_month.strftime('%B')} is {first_day_of_month}")
    else:
        print(f"The first {weekday_name} of {first_day_of_month.strftime('%B')} is not {first_day_of_month}")
