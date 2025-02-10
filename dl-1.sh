#!/bin/bash

# پارامترهای دانلود
ulimit -v $((100 * 1024))  # محدودیت 100 مگابایت رم

# بررسی وجود فایل dl-sev1.txt
if [ ! -f dl-sev1.txt ]; then
    echo "فایل dl-sev1.txt وجود ندارد!"
    exit 1
fi

# محدودیت سرعت تصادفی (بین 5000K تا 10000K)
MIN_RATE=200000
MAX_RATE=200000

# محدودیت حجم کل دانلود (500 گیگابایت = 500 * 1024 * 1024 مگابایت)
MAX_TOTAL_SIZE=$((500 * 1024 * 1024 * 1024))  # 500GB به بایت
TOTAL_DOWNLOADED=0

# ارسال پیام شروع دانلود
echo "فرآیند دانلود آغاز شد."

# خواندن هر خط از dl-sev1.txt
while IFS= read -r line; do
    if [ -z "$line" ]; then
        continue
    fi

    # نام فایل خروجی را از لینک استخراج کنید
    filename=$(echo "$line" | grep -oE '[^/]+\.mkv' | head -n 1)
    if [ -z "$filename" ]; then
        echo "نام فایل از لینک استخراج نشد: $line"
        continue
    fi

    # تولید یک سرعت تصادفی بین MIN_RATE و MAX_RATE
    LIMIT_RATE=$(shuf -i $MIN_RATE-$MAX_RATE -n 1)

    # دریافت حجم فایل از طریق HTTP header
    FILE_SIZE=$(curl -L --silent --head "$line" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')

    if [ -z "$FILE_SIZE" ]; then
        echo "خطا در دریافت حجم فایل از: $line"
        continue
    fi

    # بررسی اینکه آیا حجم کل دانلود از حد مجاز عبور کرده است
    if [ $((TOTAL_DOWNLOADED + FILE_SIZE)) -gt $MAX_TOTAL_SIZE ]; then
        echo "حجم کل دانلود به حد مجاز (500GB) رسید. دانلود متوقف می‌شود."
        break
    fi

    # دانلود فایل با محدودیت سرعت به /dev/null
    echo "در حال دانلود: $filename با محدودیت سرعت $LIMIT_RATE K"

    curl -L --limit-rate "${LIMIT_RATE}K" -o /dev/null "$line"
    
    # بررسی موفقیت دانلود
    if [ $? -eq 0 ]; then
        echo "دانلود $filename با موفقیت انجام شد."
        
        # اضافه کردن حجم دانلود شده به حجم کل
        TOTAL_DOWNLOADED=$((TOTAL_DOWNLOADED + FILE_SIZE))
        echo "حجم کل دانلود شده: $((TOTAL_DOWNLOADED / 1024 / 1024 / 1024)) GB"
    else
        echo "خطا در دانلود: $line"
    fi

done < dl-sev1.txt

# ارسال پیام پایان
echo "🎉 تمامی لینک‌ها بررسی شدند. حجم کل دانلود شده: $((TOTAL_DOWNLOADED / 1024 / 1024 / 1024)) GB"

echo "تمامی لینک‌ها بررسی شدند."
