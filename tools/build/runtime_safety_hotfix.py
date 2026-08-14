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


replace_exact(
    "Source/Code/TMSrv/ProcessDBMessage.cpp",
    '" $s Slots Desbugados Inventario"',
    '" %s Slots Desbugados Inventario"'
)
replace_exact(
    "Source/Code/TMSrv/ProcessDBMessage.cpp",
    '" $s Slots Desbugados Bau"',
    '" %s Slots Desbugados Bau"'
)

replace_exact(
    "Source/Code/TMSrv/_MSG_MessageWhisper.cpp",
    "pMob[target].extra.Fame, pMob[conn].MOB.Guild);",
    "pMob[target].extra.Fame);",
    expected=2
)

quest_old = '''\
\tint count = 0;

\twhile (fscanf(fp, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
\t\t&QuestDiaria[count].IndexQuest,
\t\t&QuestDiaria[count].Nivel,
\t\t&QuestDiaria[count].IdMob1, &QuestDiaria[count].QtdMob1,
\t\t&QuestDiaria[count].IdMob2, &QuestDiaria[count].QtdMob2,
\t\t&QuestDiaria[count].IdMob3, &QuestDiaria[count].QtdMob3,
\t\t&QuestDiaria[count].ExpReward,
\t\t&QuestDiaria[count].GoldReward,
\t\t&QuestDiaria[count].Item->sIndex,
\t\t&QuestDiaria[count].Item->stEffect[0].cEffect,
\t\t&QuestDiaria[count].Item->stEffect[0].cValue,
\t\t&QuestDiaria[count].Item->stEffect[1].cEffect,
\t\t&QuestDiaria[count].Item->stEffect[1].cValue,
\t\t&QuestDiaria[count].Item->stEffect[2].cEffect,
\t\t&QuestDiaria[count].Item->stEffect[2].cValue) != EOF && count < 7)
\t\tcount++;
'''

quest_new = '''\
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
replace_exact("Source/Code/TMSrv/Server.cpp", quest_old, quest_new)

level_old = '''\
\t\tsscanf(tmp, "%d %d %d %d %d %d %d %d %d %d", &id, &level, &cls, &type, &ival1, &ival2, &ival3, &ival4, &ival5, &ival6, &ival7);

\t\tItem.sIndex = ival1;
'''
level_new = '''\
\t\tconst int parsed = sscanf(tmp, "%d %d %d %d %d %d %d %d %d %d %d", &id, &level, &cls, &type, &ival1, &ival2, &ival3, &ival4, &ival5, &ival6, &ival7);

\t\tif (parsed != 11 || level < 0 || level >= 400 || cls < 0 || cls > 4 || type < 0 || type > 4 ||
\t\t\tival1 < -32768 || ival1 > 32767 ||
\t\t\tival2 < 0 || ival2 > 255 || ival3 < 0 || ival3 > 255 ||
\t\t\tival4 < 0 || ival4 > 255 || ival5 < 0 || ival5 > 255 ||
\t\t\tival6 < 0 || ival6 > 255 || ival7 < 0 || ival7 > 255)
\t\t\tcontinue;

\t\tItem.sIndex = static_cast<short>(ival1);
'''
replace_exact("Source/Code/TMSrv/Server.cpp", level_old, level_new)

sicario_old = '''\
\t\t\t\t\t\t\tif (partyleader > 0 && partyleader < MAX_USER);
\t\t\t\t\t\t\tDoTeleport(partyleader, 2100, 2100);

\t\t\t\t\t\t\tfor (int i = 0; i < MAX_PARTY; i++)
\t\t\t\t\t\t\t{
\t\t\t\t\t\t\t\tint partymember = pMob[partyleader].PartyList[i];
\t\t\t\t\t\t\t\tif (pUser[partymember].Mode != USER_PLAY)
\t\t\t\t\t\t\t\t\tcontinue;
\t\t\t\t\t\t\t\tDoTeleport(partymember, 2100, 2100);
\t\t\t\t\t\t\t\tPutItem(partymember, &gift);
\t\t\t\t\t\t\t\tPutItem(partyleader, &gift);

\t\t\t\t\t\t\t\tpUser[partymember].Honra += 5;
\t\t\t\t\t\t\t\tpUser[partyleader].Honra += 5;
\t\t\t\t\t\t\t\tSendMsgExp(partymember, "+ 5 pontos de Honra", TNColor::NewYellow, false);
\t\t\t\t\t\t\t\tSendMsgExp(partyleader, "+ 5 pontos de Honra", TNColor::NewYellow, false);
\t\t\t\t\t\t\t}
'''
sicario_new = '''\
\t\t\t\t\t\t\tif (partyleader > 0 && partyleader < MAX_USER)
\t\t\t\t\t\t\t{
\t\t\t\t\t\t\t\tDoTeleport(partyleader, 2100, 2100);

\t\t\t\t\t\t\t\tfor (int i = 0; i < MAX_PARTY; i++)
\t\t\t\t\t\t\t\t{
\t\t\t\t\t\t\t\t\tint partymember = pMob[partyleader].PartyList[i];
\t\t\t\t\t\t\t\t\tif (partymember <= 0 || partymember >= MAX_USER || pUser[partymember].Mode != USER_PLAY)
\t\t\t\t\t\t\t\t\t\tcontinue;
\t\t\t\t\t\t\t\t\tDoTeleport(partymember, 2100, 2100);
\t\t\t\t\t\t\t\t\tPutItem(partymember, &gift);
\t\t\t\t\t\t\t\t\tPutItem(partyleader, &gift);

\t\t\t\t\t\t\t\t\tpUser[partymember].Honra += 5;
\t\t\t\t\t\t\t\t\tpUser[partyleader].Honra += 5;
\t\t\t\t\t\t\t\t\tSendMsgExp(partymember, "+ 5 pontos de Honra", TNColor::NewYellow, false);
\t\t\t\t\t\t\t\t\tSendMsgExp(partyleader, "+ 5 pontos de Honra", TNColor::NewYellow, false);
\t\t\t\t\t\t\t\t}
\t\t\t\t\t\t\t}
'''
replace_exact("Source/Code/TMSrv/MobKilled.cpp", sicario_old, sicario_new)
