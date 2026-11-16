import json
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
LOG_FILE = BASE_DIR / "audit.log"
OUTPUT_FILE = BASE_DIR / "audit-extract.json"


def is_suspicious(event):
    resource = event.get("objectRef", {}).get("resource")
    subresource = event.get("objectRef", {}).get("subresource")
    verb = event.get("verb")
    request = event.get("requestObject") or {}

    if resource == "secrets" and verb in ("get", "list"):
        return True

    if resource == "pods" and verb == "create":
        containers = request.get("spec", {}).get("containers", [])
        if any(
            container.get("securityContext", {}).get("privileged") is True
            for container in containers
        ):
            return True

    if resource == "pods" and subresource == "exec":
        return True

    if resource in ("rolebindings", "clusterrolebindings"):
        if verb in ("create", "update", "patch", "delete"):
            return True

    if "audit-policy" in json.dumps(event).lower():
        return True

    return False


def main():
    suspicious = []

    with LOG_FILE.open(encoding="utf-8") as file:
        for line in file:
            if not line.strip():
                continue

            event = json.loads(line)

            if event.get("stage") != "ResponseComplete":
                continue

            if is_suspicious(event):
                suspicious.append({
                    "timestamp": event.get("requestReceivedTimestamp"),
                    "user": event.get("user", {}).get("username"),
                    "impersonatedUser": (
                        event.get("impersonatedUser", {}) or {}
                    ).get("username"),
                    "verb": event.get("verb"),
                    "namespace": event.get("objectRef", {}).get("namespace"),
                    "resource": event.get("objectRef", {}).get("resource"),
                    "subresource": event.get("objectRef", {}).get("subresource"),
                    "name": event.get("objectRef", {}).get("name"),
                    "status": event.get("responseStatus", {}).get("code"),
                    "requestObject": event.get("requestObject"),
                })

    OUTPUT_FILE.write_text(
        json.dumps(suspicious, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"подозрительных событий: {len(suspicious)}")

if __name__ == "__main__":
    main()