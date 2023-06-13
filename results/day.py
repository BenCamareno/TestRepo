def is_first_weekday_of_month(weekday):
    today = datetime.date.today()
    first_day_of_month = datetime.date(today.year, today.month, 1)

    if first_day_of_month.weekday() == weekday and today.day <= 7:
        return True
    else:
        return False
