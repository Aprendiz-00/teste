from pathlib import Path


def encoded(data: bytes, text: str) -> bytes:
    """Convert text to bytes using the same line ending as the source file."""
    # Detect line ending from the file
    if b"\r\n" in data:
        nl = "\r\n"
    else:
        nl = "\n"
    
    # Normalize the text to use \n, then convert to file's line ending
    normalized = text.replace("\r\n", "\n").replace(nl, "\n")
    return normalized.encode("utf-8").replace(b"\n", nl.encode("utf-8"))


def replace_exact(path: str, old: str, new: str, expected: int = 1) -> None:
    """Replace exact text in a file, preserving line endings."""
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
	int count = 0;

	while (count < 7)
	{
		int value[17] = {};

		const int parsed = fscanf(fp, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
			&value[0], &value[1], &value[2], &value[3], &value[4], &value[5],
			&value[6], &value[7], &value[8], &value[9], &value[10], &value[11],
			&value[12], &value[13], &value[14], &value[15], &value[16]);

		if (parsed == EOF)
			break;

		if (parsed != 17)
		{
			char invalidLine[512];
			fgets(invalidLine, sizeof(invalidLine), fp);
			continue;
		}

		const auto fitsShort = [](int v) { return v >= -32768 && v <= 32767; };
		const auto fitsByte = [](int v) { return v >= 0 && v <= 255; };

		if (!fitsShort(value[0]) || !fitsShort(value[1]) ||
			!fitsShort(value[2]) || !fitsShort(value[3]) ||
			!fitsShort(value[4]) || !fitsShort(value[5]) ||
			!fitsShort(value[6]) || !fitsShort(value[7]) ||
			!fitsShort(value[10]) ||
			!fitsByte(value[11]) || !fitsByte(value[12]) ||
			!fitsByte(value[13]) || !fitsByte(value[14]) ||
			!fitsByte(value[15]) || !fitsByte(value[16]))
			continue;

		STRUCT_QUEST& quest = QuestDiaria[count];
		quest.IndexQuest = static_cast<short>(value[0]);
		quest.Nivel = static_cast<short>(value[1]);
		quest.IdMob1 = static_cast<short>(value[2]);
		quest.QtdMob1 = static_cast<short>(value[3]);
		quest.IdMob2 = static_cast<short>(value[4]);
		quest.QtdMob2 = static_cast<short>(value[5]);
		quest.IdMob3 = static_cast<short>(value[6]);
		quest.QtdMob3 = static_cast<short>(value[7]);
		quest.ExpReward = value[8];
		quest.GoldReward = value[9];
		quest.Item[0].sIndex = static_cast<short>(value[10]);
		quest.Item[0].stEffect[0].cEffect = static_cast<unsigned char>(value[11]);
		quest.Item[0].stEffect[0].cValue = static_cast<unsigned char>(value[12]);
		quest.Item[0].stEffect[1].cEffect = static_cast<unsigned char>(value[13]);
		quest.Item[0].stEffect[1].cValue = static_cast<unsigned char>(value[14]);
		quest.Item[0].stEffect[2].cEffect = static_cast<unsigned char>(value[15]);
		quest.Item[0].stEffect[2].cValue = static_cast<unsigned char>(value[16]);
		count++;
	}
'''

quest_new = '''\
	int count = 0;
	char line[1024];

	while (count < 7 && fgets(line, sizeof(line), fp) != NULL)
	{
		int value[17] = {};

		const int parsed = sscanf(line, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
			&value[0], &value[1], &value[2], &value[3], &value[4], &value[5],
			&value[6], &value[7], &value[8], &value[9], &value[10], &value[11],
			&value[12], &value[13], &value[14], &value[15], &value[16]);

		if (parsed != 17)
			continue;

		const auto fitsShort = [](int v) { return v >= -32768 && v <= 32767; };
		const auto fitsByte = [](int v) { return v >= 0 && v <= 255; };

		if (!fitsShort(value[0]) || !fitsShort(value[1]) ||
			!fitsShort(value[2]) || !fitsShort(value[3]) ||
			!fitsShort(value[4]) || !fitsShort(value[5]) ||
			!fitsShort(value[6]) || !fitsShort(value[7]) ||
			!fitsShort(value[10]) ||
			!fitsByte(value[11]) || !fitsByte(value[12]) ||
			!fitsByte(value[13]) || !fitsByte(value[14]) ||
			!fitsByte(value[15]) || !fitsByte(value[16]))
			continue;

		STRUCT_QUEST& quest = QuestDiaria[count];
		quest.IndexQuest = static_cast<short>(value[0]);
		quest.Nivel = static_cast<short>(value[1]);
		quest.IdMob1 = static_cast<short>(value[2]);
		quest.QtdMob1 = static_cast<short>(value[3]);
		quest.IdMob2 = static_cast<short>(value[4]);
		quest.QtdMob2 = static_cast<short>(value[5]);
		quest.IdMob3 = static_cast<short>(value[6]);
		quest.QtdMob3 = static_cast<short>(value[7]);
		quest.ExpReward = value[8];
		quest.GoldReward = value[9];
		quest.Item[0].sIndex = static_cast<short>(value[10]);
		quest.Item[0].stEffect[0].cEffect = static_cast<unsigned char>(value[11]);
		quest.Item[0].stEffect[0].cValue = static_cast<unsigned char>(value[12]);
		quest.Item[0].stEffect[1].cEffect = static_cast<unsigned char>(value[13]);
		quest.Item[0].stEffect[1].cValue = static_cast<unsigned char>(value[14]);
		quest.Item[0].stEffect[2].cEffect = static_cast<unsigned char>(value[15]);
		quest.Item[0].stEffect[2].cValue = static_cast<unsigned char>(value[16]);
		count++;
	}
'''
replace_exact("Source/Code/TMSrv/Server.cpp", quest_old, quest_new)

replace_exact(
    "Source/Code/TMSrv/Server.cpp",
    '''\
		Item.stEffect[0].cEffect = ival2;
		Item.stEffect[0].cValue = ival3;
		Item.stEffect[1].cEffect = ival4;
		Item.stEffect[1].cValue = ival5;
		Item.stEffect[2].cEffect = ival6;
		Item.stEffect[2].cValue = ival7;
''',
    '''\
		Item.stEffect[0].cEffect = static_cast<unsigned char>(ival2);
		Item.stEffect[0].cValue = static_cast<unsigned char>(ival3);
		Item.stEffect[1].cEffect = static_cast<unsigned char>(ival4);
		Item.stEffect[1].cValue = static_cast<unsigned char>(ival5);
		Item.stEffect[2].cEffect = static_cast<unsigned char>(ival6);
		Item.stEffect[2].cValue = static_cast<unsigned char>(ival7);
'''
)
