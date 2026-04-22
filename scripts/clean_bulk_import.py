import pathlib
import re


SRC = pathlib.Path("bulk_import.sql")
OUT = pathlib.Path("bulk_import_clean.sql")


PATTERN = re.compile(
    r"VALUES \('(?P<type>instrument|reagent)', (?P<id>\d+), '(?P<name>(?:''|[^'])*)', "
    r"'(?P<serial>(?:''|[^'])*)', '(?P<cat>(?:''|[^'])*)', (?P<qty>-?\d+(?:\.\d+)?), "
    r"(?P<avail>-?\d+(?:\.\d+)?), '(?P<status>(?:''|[^'])*)', '(?P<cond>(?:''|[^'])*)', "
    r"'(?P<loc>(?:''|[^'])*)'\) ON DUPLICATE KEY UPDATE"
)


BAD_SUBSTRINGS = [
    "FOR MED, NURSING",
    "MIDWIFERY LAB",
    "WET AND DRY LAB",
    "MULTIDISCIPLINARY LABS",
    "MEDICAL AND SURGICAL INSTRUMENTS",
    "DENTAL INSTRUMENTS",
    "FIXTURES & APPLIANCES",
    "TEACHER'S DESK",
    "TEACHER'S SWIVEL CHAIR",
    "LED PROJECTORS",
    "LED TV 55 INCHES",
    "PREPARED BY",
    "NOTED BY",
    "REVOLVING STOOLS",
    "ANNUAL REQUEST",
    "STOCKROOM",
    "REMARKS",
]

BAD_EXACT = {
    "TEACHER",
    "EQUIPMENT",
    "SUPPLIES & CONSUMABLES",
    "TOTAL",
    "UPDATED",
    "FEATHER",
    "4X100",
    "AY 2024-2025",
    "AY 2025-2026",
    "LINK",
    "AUTOCLAVE",
    "MICRO LAB",
}


def unescape_sql(s: str) -> str:
    return s.replace("''", "'").strip()


def escape_sql(s: str) -> str:
    return s.replace("'", "''")


def is_noise(name: str) -> bool:
    n = name.upper().strip()
    if not n:
        return True
    if n in BAD_EXACT:
        return True
    if any(x in n for x in BAD_SUBSTRINGS):
        return True
    if re.search(r"^\d+\s+(EACH|FOR)\b", n):
        return True
    return False


def main() -> None:
    text = SRC.read_text(encoding="utf-8", errors="ignore")
    parsed = 0
    kept_by_name = {}
    order = []

    for m in PATTERN.finditer(text):
        parsed += 1
        d = m.groupdict()
        name = unescape_sql(d["name"])
        if is_noise(name):
            continue
        key = name.upper()
        if key not in kept_by_name:
            order.append(key)
        kept_by_name[key] = d

    with OUT.open("w", encoding="utf-8", newline="\n") as f:
        f.write("-- Auto-generated cleaned import from bulk_import.sql\n")
        f.write("-- Deduped by name; obvious non-item rows removed\n\n")
        for key in order:
            d = kept_by_name[key]
            row_type = d["type"]
            name = escape_sql(unescape_sql(d["name"]))
            serial = escape_sql(unescape_sql(d["serial"]))
            cat = escape_sql(unescape_sql(d["cat"]))
            qty = d["qty"]
            avail = d["avail"]
            status = escape_sql(unescape_sql(d["status"]))
            cond = escape_sql(unescape_sql(d["cond"]))
            loc = escape_sql(unescape_sql(d["loc"]))

            f.write(
                "INSERT INTO `instruments` (`type`, `name`, `serial_number`, `category`, `quantity`, `available`, `status`, `condition`, `location`) VALUES "
                f"('{row_type}', '{name}', '{serial}', '{cat}', {qty}, {avail}, '{status}', '{cond}', '{loc}') "
                "ON DUPLICATE KEY UPDATE "
                "`type`=VALUES(`type`), `serial_number`=VALUES(`serial_number`), `category`=VALUES(`category`), "
                "`quantity`=VALUES(`quantity`), `available`=VALUES(`available`), `status`=VALUES(`status`), "
                "`condition`=VALUES(`condition`), `location`=VALUES(`location`);\n"
            )

    print(f"parsed_rows={parsed}")
    print(f"clean_rows={len(kept_by_name)}")
    print(f"output={OUT.resolve()}")


if __name__ == "__main__":
    main()
