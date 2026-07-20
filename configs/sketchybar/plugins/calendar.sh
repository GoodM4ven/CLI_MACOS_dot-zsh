#!/bin/bash

gregorian="$(date '+%d/%m/%y')"

case "$(date '+%u')" in
  1) weekday="الاثنين" ;;
  2) weekday="الثلاثاء" ;;
  3) weekday="الأربعاء" ;;
  4) weekday="الخميس" ;;
  5) weekday="الجمعة" ;;
  6) weekday="السبت" ;;
  7) weekday="الأحد" ;;
esac

hijri="$(
  /usr/bin/osascript -l JavaScript <<'JXA' 2>/dev/null
ObjC.import('Foundation');

const calendar = $.NSCalendar.calendarWithIdentifier(
  $.NSCalendarIdentifierIslamicCivil
);

const flags =
  $.NSCalendarUnitYear |
  $.NSCalendarUnitMonth |
  $.NSCalendarUnitDay;

const components = calendar.componentsFromDate(flags, $.NSDate.date);

const year = Number(components.year) % 100;
const month = Number(components.month);
const day = Number(components.day);

String(year).padStart(2, '0') + '/' +
String(month).padStart(2, '0') + '/' +
String(day).padStart(2, '0');
JXA
)"

[[ -z "$hijri" ]] && hijri="--/--/--"

sketchybar --set calendar label="$hijri | $weekday | $gregorian"
