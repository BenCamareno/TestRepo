def first_week_of_month():
    # Returns true if the current day is within the first week of the month
    os.environ['TZ'] = 'Australia/Sydney'
    time.tzset()
    date = time.strftime('%d', time.localtime())
    if int(date) <= 7:
        return True
    else:
        return False
