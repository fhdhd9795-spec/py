import random
import string
import base64
import os
import json
import urllib.request
import urllib.error

# ============================
# 설정
# ============================
GITHUB_TOKEN = os.environ["GH_PAT"]        # GitHub Personal Access Token
SECRET_KEY   = os.environ["SECRET_KEY"]    # XOR 비밀키 (GitHub Secret에 저장)
REPO_OWNER   = "fhdhd9795-spec"
REPO_NAME    = "py"
FILE_PATH    = "py"                         # py 레포 안의 파일 이름

# ============================
# 1. 랜덤 비번 생성 (10자리)
# 대문자 + 소문자 + 숫자 + 특수문자 포함
# ============================
def generate_password(length=10):
    lower   = string.ascii_lowercase   # a-z
    upper   = string.ascii_uppercase   # A-Z
    digits  = string.digits            # 0-9
    special = "!@#$%^&*()"            # 특수문자

    # 각 종류에서 최소 1개씩 보장
    pwd = [
        random.choice(lower),
        random.choice(lower),
        random.choice(upper),
        random.choice(upper),
        random.choice(digits),
        random.choice(digits),
        random.choice(special),
        random.choice(special),
    ]
    # 나머지 2자리는 전체에서 랜덤
    all_chars = lower + upper + digits + special
    pwd += random.choices(all_chars, k=length - len(pwd))

    # 섞기
    random.shuffle(pwd)
    return ''.join(pwd)

# ============================
# 2. 암호화 (JS encryptor.html 과 동일 로직)
# 치환+반전 → Base64 → XOR → Base64
# ============================
NUM_TO_SYM = {'0':'!','1':'@','2':'#','3':'$','4':'%','5':'^','6':'&','7':'*','8':'(','9':')'}
SYM_TO_NUM = {'!':'0','@':'1','#':'2','$':'3','%':'4','^':'5','&':'6','*':'7','(':'8',')':'9'}

def cipher(text):
    result = []
    for c in text:
        if   c.islower():       result.append(c.upper())
        elif c.isupper():       result.append(c.lower())
        elif c in NUM_TO_SYM:  result.append(NUM_TO_SYM[c])
        elif c in SYM_TO_NUM:  result.append(SYM_TO_NUM[c])
        else:                  result.append(c)
    return ''.join(result[::-1])

def xor_str(text, key):
    result = bytearray()
    for i, c in enumerate(text.encode('latin-1')):
        result.append(c ^ ord(key[i % len(key)]))
    return result

def encrypt(plain, key):
    s1 = cipher(plain)
    s2 = base64.b64encode(s1.encode('utf-8')).decode('ascii')
    s3 = xor_str(s2, key)
    s4 = base64.b64encode(s3).decode('ascii')
    return s4

# ============================
# 3. GitHub API로 py 파일 업데이트
# ============================
def get_file_sha():
    url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/contents/{FILE_PATH}"
    req = urllib.request.Request(url, headers={
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
    })
    try:
        with urllib.request.urlopen(req) as res:
            data = json.loads(res.read())
            return data["sha"]
    except:
        return None

def update_file(content, sha):
    url     = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/contents/{FILE_PATH}"
    payload = {
        "message": "🔐 Auto: daily password update",
        "content": base64.b64encode(content.encode('utf-8')).decode('ascii'),
        "sha": sha,
    }
    data = json.dumps(payload).encode('utf-8')
    req  = urllib.request.Request(url, data=data, method="PUT", headers={
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
        "Content-Type": "application/json",
    })
    with urllib.request.urlopen(req) as res:
        return res.status == 200 or res.status == 201

# ============================
# 실행
# ============================
if __name__ == "__main__":
    # 비번 생성
    password  = generate_password(10)
    print(f"✅ 생성된 비번: {password}")

    # 암호화
    encrypted = encrypt(password, SECRET_KEY)
    print(f"🔐 암호화 완료: {encrypted}")

    # GitHub 파일 SHA 가져오기
    sha = get_file_sha()
    if not sha:
        print("❌ SHA 가져오기 실패")
        exit(1)

    # 파일 업데이트
    ok = update_file(encrypted, sha)
    if ok:
        print("✅ py 파일 업데이트 성공!")
    else:
        print("❌ 파일 업데이트 실패")
        exit(1)
