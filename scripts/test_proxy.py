import json
import urllib.request

def main():
    body = json.dumps({
        "url": "https://httpbin.org/post",
        "data": {"hello": "world"},
        "headers": {}
    }).encode("utf-8")

    req = urllib.request.Request('http://127.0.0.1:7861/proxy', data=body, headers={'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            print(r.read().decode('utf-8'))
    except Exception as e:
        print('ERROR', e)

if __name__ == '__main__':
    main()
