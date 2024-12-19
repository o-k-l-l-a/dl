#!/bin/bash

# دریافت لیست ID های اسکرین‌های باز
screen -ls | grep -o '[0-9]*\.[a-zA-Z0-9]*' | while read session; do
    # بستن هر اسکرین با استفاده از session ID
    screen -X -S "$session" quit
done

echo "تمامی اسکرین‌ها بسته شدند."
