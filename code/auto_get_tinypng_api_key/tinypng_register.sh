#!/bin/bash

# Get new API key with TinyPNG

NEED_REGISTER_COUNT=10

# use temp email to register
declare -A email_acounts
email_acounts=()

# API_KEYS
API_KEYS_IDX=0
declare -a API_KEYS

function find_element_in_array() {
  for key in "${!email_acounts[@]}"; do
    if [[ "$key" == "$1" ]]; then
      echo "${email_acounts[$key]}"
      return 0
    fi
  done
  return 1
}

function register_new_email() {
  output_for_new_email=$(\
  curl -s 'https://api.internal.temp-mail.io/api/v3/email/new' \
    -H 'accept: */*' \
    -H 'accept-language: zh-CN,zh;q=0.6' \
    -H 'application-name: web' \
    -H 'application-version: 4.0.0' \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -H 'origin: https://temp-mail.io' \
    -H 'pragma: no-cache' \
    -H 'priority: u=1, i' \
    -H 'referer: https://temp-mail.io/' \
    -H 'sec-fetch-dest: empty' \
    -H 'sec-fetch-mode: cors' \
    -H 'sec-fetch-site: same-site' \
    -H 'sec-gpc: 1' \
    -H 'user-agent: Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1' \
    -H 'x-cors-header: iaWg3pchvFx48fY' \
    --data-raw '{"min_name_length":10,"max_name_length":10}'\
  )

  email=$(echo $output_for_new_email | sed -nE 's/.*"email":"([^"]+)".*/\1/p')
  token=$(echo $output_for_new_email | sed -nE 's/.*"token":"([^"]+)".*/\1/p')

  echo "Email: $email $token"
  find_element_in_array "$email"
  if [ $? -eq 0 ]; then
    return 1
  else
    email_acounts+=("$email" "$token")
    return 0
  fi
}

function get_message_from_email() {
  email=$1
  verifiy_token=$(\
    curl -s "https://api.internal.temp-mail.io/api/v3/email/$email/messages" \
  -H 'accept: */*' \
  -H 'accept-language: zh-CN,zh;q=0.6' \
  -H 'application-name: web' \
  -H 'application-version: 4.0.0' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'origin: https://temp-mail.io' \
  -H 'pragma: no-cache' \
  -H 'priority: u=1, i' \
  -H 'referer: https://temp-mail.io/' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-site' \
  -H 'sec-gpc: 1' \
  -H 'user-agent: Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1' \
  -H 'x-cors-header: iaWg3pchvFx48fY'\
  | sed -nE 's/.*href=\\"https:\/\/tinypng\.com\/login\?token=([^"]+)\\u0026amp;new=true.*/\1/p'\
)
  # 验证token不为空
  if [ -z "$verifiy_token" ]; then
    echo "Failed to get verification token from email"
    return 1
  fi

  echo "Get Verification token: $verifiy_token"

tinypng_cookies=$(\
curl -fsSLI "https://tinypng.com/login?token=${verifiy_token}&new=true&redirect=/dashboard/api" \
| sed -nE '/tinify.com\/dashboard\/api/,+2 p' \
| awk 'NR > 1 {print $2}' | tr '\n' ' '\
)
cookies_str=${tinypng_cookies%??}
echo 'Get cookies:' $cookies_str

token_for_request_api=$(\
curl -s 'https://tinify.com/web/session' \
  -H 'accept: */*' \
  -H 'accept-language: zh-CN,zh;q=0.8' \
  -H 'cache-control: no-cache' \
  -b "$cookies_str" \
  -H 'pragma: no-cache' \
  -H 'priority: u=1, i' \
  -H 'referer: https://tinify.com/dashboard/api' \
  -H 'sec-ch-ua: "Brave";v="141", "Not?A_Brand";v="8", "Chromium";v="141"' \
  -H 'sec-ch-ua-mobile: ?1' \
  -H 'sec-ch-ua-platform: "Android"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-gpc: 1' \
  -H 'user-agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36' \
| sed -nE 's/.*"token":"([^"]+)".*/\1/p'\
)

echo 'Get request api token:' $token_for_request_api

api_key=$(\
curl -s 'https://api.tinify.com/api' \
-H 'accept: */*' \
-H 'accept-language: zh-CN,zh;q=0.8' \
-H "authorization: Bearer $token_for_request_api" \
-H 'cache-control: no-cache' \
-H 'origin: https://tinify.com' \
-H 'pragma: no-cache' \
-H 'priority: u=1, i' \
-H 'referer: https://tinify.com/' \
-H 'sec-ch-ua: "Brave";v="141", "Not?A_Brand";v="8", "Chromium";v="141"' \
-H 'sec-ch-ua-mobile: ?1' \
-H 'sec-ch-ua-platform: "Android"' \
-H 'sec-fetch-dest: empty' \
-H 'sec-fetch-mode: cors' \
-H 'sec-fetch-site: same-site' \
-H 'sec-gpc: 1' \
-H 'user-agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36' \
| sed -nE 's/.*"key":"([^"]+)".*/\1/p'\
)

echo 'Get api key:' $api_key

API_KEYS[$API_KEYS_IDX]=$api_key
API_KEYS_IDX=$((API_KEYS_IDX+1))

return 0

}

function registe_tinypng_acount() {

email_entry=$1
response=$(\
  curl -s 'https://tinify.com/web/api' \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: zh-CN,zh;q=0.7' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'origin: https://tinify.com' \
  -H 'pragma: no-cache' \
  -H 'priority: u=1, i' \
  -H 'referer: https://tinify.com/developers' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-gpc: 1' \
  -H 'user-agent: Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1' \
  --data-raw "{\"fullName\":\"$email_entry\",\"mail\":\"$email_entry\"}" \
)
echo $response
if echo $response | grep -q 'error'; then
  return 1
else
  return 0
fi
}

function register_emails() {
  i=0
  while true; do
    echo "Registering $i/$NEED_REGISTER_COUNT"
    register_new_email
    if [ $? -eq 0 ]; then
      i=$((i+1))
      if [[ $i == $NEED_REGISTER_COUNT ]]; then
        break
      fi
    else
      echo "Failed to register email"
    fi
  done

  echo "All emails have been registered"
  # list all registered emails and tokens
  for email in "${!email_acounts[@]}"; do
    echo "$email ${email_acounts[$email]}"
    registe_tinypng_acount "$email"
    if [ $? -eq 0 ]; then
      echo "Email $email registered successfully"
    else
      echo "Failed to register email $email"
      break
    fi
    echo "Messages from $email:"
    while true; do
      sleep 1
      get_message_from_email "$email"
      if [ $? -eq 0 ]; then
        break
      else
        echo "暂时没收到验证邮件，正在重试..."
      fi
    done
  done
}

register_emails

# print API_KEYS
echo "API_KEYS: 成功获取到${API_KEYS_IDX}个"
for element in ${API_KEYS[@]}; do
  echo \"$element\",
done

