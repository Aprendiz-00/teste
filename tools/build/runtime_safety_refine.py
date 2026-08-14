from pathlib import Path


def encoded(data: bytes, text: str) -> bytes:
    nl = "\r\n" if b"\r\n" in data else "\n"
    return text.replace("\r\n", "\n").replace("\n", nl).encode("utf-8")


def replace_exact(path: str, old: str, new: str, expected: int = 1) -> None:
    p = Path(path)
    data = p.read_bytes()
    old_b = encoded(data, old)
    new_b = encoded(data, new)
    count = data.count(old_b)
    if count != expected:
        raise RuntimeError(f"{path}: expected {expected} exact match(es), found {count}")
    p.write_bytes(data.replace(old_b, new_b))
    print(f"patched {path}: {count} replacement(s)")


quest_old = '''\
\tint count = 0;

\twhile (count < 7)
\t{
\t\tint value[17] = {};

\t\tconst int parsed = fscanf(fp, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
\t\t\t&value[0], &value[1], &value[2], &value[3], &value[4], &value[5],
\t\t\t&value[6], &value[7], &value[8], &value[9], &value[10], &value[11],
\t\t\t&value[12], &value[13], &value[14], &value[15], &value[16]);

\t\tif (parsed == EOF)
\t\t\tbreak;

\t\tif (parsed != 17)
\t\t{
\t\t\tchar invalidLine[512];
\t\t\tfgets(invalidLine, sizeof(invalidLine), fp);
\t\t\tcontinue;
\t\t}

\t\tconst auto fitsShort = [](int v) { return v >= -32768 && v <= 32767; };
\t\tconst auto fitsByte = [](int v) { return v >= 0 && v <= 255; };

\t\tif (!fitsShort(value[0]) || !fitsShort(value[1]) ||
\t\t\t!fitsShort(value[2]) || !fitsShort(value[3]) ||
\t\t\t!fitsShort(value[4]) || !fitsShort(value[5]) ||
\t\t\t!fitsShort(value[6]) || !fitsShort(value[7]) ||
\t\t\t!fitsShort(value[10]) ||
\t\t\t!fitsByte(value[11]) || !fitsByte(value[12]) ||
\t\t\t!fitsByte(value[13]) || !fitsByte(value[14]) ||
\t\t\t!fitsByte(value[15]) || !fitsByte(value[16]))
\t\t\tcontinue;

\t\tSTRUCT_QUEST& quest = QuestDiaria[count];
\t\tquest.IndexQuest = static_cast<short>(value[0]);
\t\tquest.Nivel = static_cast<short>(value[1]);
\t\tquest.IdMob1 = static_cast<short>(value[2]);
\t\tquest.QtdMob1 = static_cast<short>(value[3]);
\t\tquest.IdMob2 = static_cast<short>(value[4]);
\t\tquest.QtdMob2 = static_cast<short>(value[5]);
\t\tquest.IdMob3 = static_cast<short>(value[6]);
\t\tquest.QtdMob3 = static_cast<short>(value[7]);
\t\tquest.ExpReward = value[8];
\t\tquest.GoldReward = value[9];
\t\tquest.Item[0].sIndex = static_cast<short>(value[10]);
\t\tquest.Item[0].stEffect[0].cEffect = static_cast<unsigned char>(value[11]);
\t\tquest.Item[0].stEffect[0].cValue = static_cast<unsigned char>(value[12]);
\t\tquest.Item[0].stEffect[1].cEffect = static_cast<unsigned char>(value[13]);
\t\tquest.Item[0].stEffect[1].cValue = static_cast<unsigned char>(value[14]);
\t\tquest.Item[0].stEffect[2].cEffect = static_cast<unsigned char>(value[15]);
\t\tquest.Item[0].stEffect[2].cValue = static_cast<unsigned char>(value[16]);
\t\tcount++;
\t}
'''

quest_new = '''\
\tint count = 0;
\tchar line[1024];

\twhile (count < 7 && fgets(line, sizeof(line), fp) != NULL)
\t{
\t\tint value[17] = {};

\t\tconst int parsed = sscanf(line, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
\t\t\t&value[0], &value[1], &value[2], &value[3], &value[4], &value[5],
\t\t\t&value[6], &value[7], &value[8], &value[9], &value[10], &value[11],
\t\t\t&value[12], &value[13], &value[14], &value[15], &value[16]);

\t\tif (parsed != 17)
\t\t\tcontinue;

\t\tconst auto fitsShort = [](int v) { return v >= -32768 && v <= 32767; };
\t\tconst auto fitsByte = [](int v) { return v >= 0 && v <= 255; };

\t\tif (!fitsShort(value[0]) || !fitsShort(value[1]) ||
\t\t\t!fitsShort(value[2]) || !fitsShort(value[3]) ||
\t\t\t!fitsShort(value[4]) || !fitsShort(value[5]) ||
\t\t\t!fitsShort(value[6]) || !fitsShort(value[7]) ||
\t\t\t!fitsShort(value[10]) ||
\t\t\t!fitsByte(value[11]) || !fitsByte(value[12]) ||
\t\t\t!fitsByte(value[13]) || !fitsByte(value[14]) ||
\t\t\t!fitsByte(value[15]) || !fitsByte(value[16]))
\t\t\tcontinue;

\t\tSTRUCT_QUEST& quest = QuestDiaria[count];
\t\tquest.IndexQuest = static_cast<short>(value[0]);
\t\tquest.Nivel = static_cast<short>(value[1]);
\t\tquest.IdMob1 = static_cast<short>(value[2]);
\t\tquest.QtdMob1 = static_cast<short>(value[3]);
\t\tquest.IdMob2 = static_cast<short>(value[4]);
\t\tquest.QtdMob2 = static_cast<short>(value[5]);
\t\tquest.IdMob3 = static_cast<short>(value[6]);
\t\tquest.QtdMob3 = static_cast<short>(value[7]);
\t\tquest.ExpReward = value[8];
\t\tquest.GoldReward = value[9];
\t\tquest.Item[0].sIndex = static_cast<short>(value[10]);
\t\tquest.Item[0].stEffect[0].cEffect = static_cast<unsigned char>(value[11]);
\t\tquest.Item[0].stEffect[0].cValue = static_cast<unsigned char>(value[12]);
\t\tquest.Item[0].stEffect[1].cEffect = static_cast<unsigned char>(value[13]);
\t\tquest.Item[0].stEffect[1].cValue = static_cast<unsigned char>(value[14]);
\t\tquest.Item[0].stEffect[2].cEffect = static_cast<unsigned char>(value[15]);
\t\tquest.Item[0].stEffect[2].cValue = static_cast<unsigned char>(value[16]);
\t\tcount++;
\t}
'''
replace_exact("Source/Code/TMSrv/Server.cpp", quest_old, quest_new)

replace_exact(
    "Source/Code/TMSrv/Server.cpp",
    '''\
\t\tItem.stEffect[0].cEffect = ival2;
\t\tItem.stEffect[0].cValue = ival3;
\t\tItem.stEffect[1].cEffect = ival4;
\t\tItem.stEffect[1].cValue = ival5;
\t\tItem.stEffect[2].cEffect = ival6;
\t\tItem.stEffect[2].cValue = ival7;
''',
    '''\
\t\tItem.stEffect[0].cEffect = static_cast<unsigned char>(ival2);
\t\tItem.stEffect[0].cValue = static_cast<unsigned char>(ival3);
\t\tItem.stEffect[1].cEffect = static_cast<unsigned char>(ival4);
\t\tItem.stEffect[1].cValue = static_cast<unsigned char>(ival5);
\t\tItem.stEffect[2].cEffect = static_cast<unsigned char>(ival6);
\t\tItem.stEffect[2].cValue = static_cast<unsigned char>(ival7);
'''
)
