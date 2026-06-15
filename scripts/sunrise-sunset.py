#!/usr/bin/env python3
"""
Расчёт времени рассвета и заката по NOAA Solar Calculator.
Использует только stdlib. Возвращает HH:MM в локальном времени.
Использование: sunrise-sunset.py <lat> <lon> [sunrise|sunset]
"""
import sys, math, datetime, time as _time

def _jd(year, month, day):
    """Julian Day Number."""
    a = (14 - month) // 12
    y = year + 4800 - a
    m = month + 12 * a - 3
    return day + (153*m + 2)//5 + 365*y + y//4 - y//100 + y//400 - 32045

def _solar_event(lat, lon, jd, rising=True):
    """Returns solar event as decimal hours UTC."""
    lon_hour = lon / 15.0
    t = jd + ((6 if rising else 18) - lon_hour) / 24.0

    M = (0.9856 * t) - 3.289
    L = M + 1.916*math.sin(math.radians(M)) + 0.020*math.sin(math.radians(2*M)) + 282.634
    L %= 360

    RA = math.degrees(math.atan(0.91764 * math.tan(math.radians(L))))
    RA %= 360
    Lq = (L // 90) * 90
    RAq = (RA // 90) * 90
    RA = (RA + (Lq - RAq)) / 15.0

    sinDec = 0.39782 * math.sin(math.radians(L))
    cosDec = math.cos(math.asin(sinDec))

    zenith = 90.833  # official
    cosH = (math.cos(math.radians(zenith)) - sinDec * math.sin(math.radians(lat))) \
           / (cosDec * math.cos(math.radians(lat)))

    if cosH > 1:   return None  # всегда ночь
    if cosH < -1:  return None  # всегда день

    H = (360 - math.degrees(math.acos(cosH))) if rising else math.degrees(math.acos(cosH))
    H /= 15.0

    T = H + RA - 0.06571 * t - 6.622
    utc = (T - lon_hour) % 24
    return utc

def utc_to_local(utc_hours):
    """Конвертируем UTC часы в локальное время учитывая TZ."""
    now = datetime.datetime.now()
    tz_offset = (_time.timezone if not _time.daylight else _time.altzone) / -3600
    local = (utc_hours + tz_offset) % 24
    h = int(local)
    m = int((local - h) * 60)
    return f"{h:02d}:{m:02d}"

def main():
    if len(sys.argv) < 3:
        print("Использование: sunrise-sunset.py <lat> <lon> [sunrise|sunset|both]")
        sys.exit(1)

    lat = float(sys.argv[1])
    lon = float(sys.argv[2])
    mode = sys.argv[3] if len(sys.argv) > 3 else "both"

    today = datetime.date.today()
    jd = _jd(today.year, today.month, today.day) - 2415020  # NOAA uses different epoch

    sunrise_utc = _solar_event(lat, lon, jd, rising=True)
    sunset_utc  = _solar_event(lat, lon, jd, rising=False)

    if mode == "sunrise":
        print(utc_to_local(sunrise_utc) if sunrise_utc else "06:00")
    elif mode == "sunset":
        print(utc_to_local(sunset_utc) if sunset_utc else "20:00")
    else:
        sr = utc_to_local(sunrise_utc) if sunrise_utc else "06:00"
        ss = utc_to_local(sunset_utc) if sunset_utc else "20:00"
        print(f"{sr} {ss}")

if __name__ == "__main__":
    main()
