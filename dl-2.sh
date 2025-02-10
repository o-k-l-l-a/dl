#!/bin/bash

# پارامترهای تلگرام
ulimit -v $((100 * 1024))  # محدودیت 100 مگابایت رم
BOT_TOKEN="7195053307:AAFz1lECmd_SU-CDE3RdnxYTCPwPpOGZ-F4"
CHAT_ID="5809128095"
send_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${message}" > /dev/null
}

# بررسی وجود فایل dl-sev2.txt
if [ ! -f dl-sev2.txt ]; then
    echo "فایل dl-sev2.txt وجود ندارد!"
    send_message "❌ خطا: فایل dl-sev2.txt وجود ندارد!"
    exit 1
fi

# محدودیت سرعت تصادفی (بین 5000K تا 10000K)
MIN_RATE=200000
MAX_RATE=200000

# محدودیت حجم کل دانلود (500 گیگابایت = 500 * 1024 * 1024 مگابایت)
MAX_TOTAL_SIZE=$((500 * 1024 * 1024 * 1024))  # 500GB به بایت
TOTAL_DOWNLOADED=0

# ارسال پیام شروع دانلود
send_message "فرآیند دانلود آغاز شد."

# خواندن هر خط از dl-sev2.txt
while IFS= read -r line; do
    if [ -z "$line" ]; then
        continue
    fi

    # نام فایل خروجی را از لینک استخراج کنید
    filename=$(echo "$line" | grep -oE '[^/]+\.mkv' | head -n 1)
    if [ -z "$filename" ]; then
        echo "نام فایل از لینک استخراج نشد: $line"
        send_message "⚠️ خطا: نام فایل از لینک استخراج نشد: $line"
        continue
    fi

    # تولید یک سرعت تصادفی بین MIN_RATE و MAX_RATE
    LIMIT_RATE=$(shuf -i $MIN_RATE-$MAX_RATE -n 1)

    # دریافت حجم فایل از طریق HTTP header
    FILE_SIZE=$(curl -L --silent --head "$line" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')

    if [ -z "$FILE_SIZE" ]; then
        echo "خطا در دریافت حجم فایل از: $line"
        send_message "⚠️ خطا در دریافت حجم فایل از: $line"
        continue
    fi

    # بررسی اینکه آیا حجم کل دانلود از حد مجاز عبور کرده است
    if [ $((TOTAL_DOWNLOADED + FILE_SIZE)) -gt $MAX_TOTAL_SIZE ]; then
        echo "حجم کل دانلود به حد مجاز (500GB) رسید. دانلود متوقف می‌شود."
        send_message "🚫 حجم کل دانلود به حد مجاز رسید. دانلود متوقف شد."
        break
    fi

    # دانلود فایل با محدودیت سرعت به /dev/null
    echo "در حال دانلود: $filename با محدودیت سرعت $LIMIT_RATE K"
    send_message "⬇️ در حال دانلود: $filename با سرعت $LIMIT_RATE K"

    curl -L --limit-rate "${LIMIT_RATE}K" -o /dev/null "$line"
    
    # بررسی موفقیت دانلود
    if [ $? -eq 0 ]; then
        echo "دانلود $filename با موفقیت انجام شد."
        send_message "✅ فایل $filename با موفقیت دانلود و حذف شد."
        
        # اضافه کردن حجم دانلود شده به حجم کل
        TOTAL_DOWNLOADED=$((TOTAL_DOWNLOADED + FILE_SIZE))
        echo "حجم کل دانلود شده: $((TOTAL_DOWNLOADED / 1024 / 1024 / 1024)) GB"
    else
        echo "خطا در دانلود: $line"
        send_message "❌ خطا در دانلود فایل: $line"
    fi

done < dl-sev2.txt

# ارسال پیام پایان
send_message "🎉 تمامی لینک‌ها بررسی شدند. حجم کل دانلود شده: $((TOTAL_DOWNLOADED / 1024 / 1024 / 1024)) GB"

echo "تمامی لینک‌ها بررسی شدند."
