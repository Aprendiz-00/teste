#include "ProcessClientMessage.h"
#include "wMySQL.h"
#include "../LegacyDatabaseConfig.h"

HANDLE hThread;
HANDLE ThreadLog;

unsigned long iID;
int contador = 0;

char xQuery[1000];
char mQuery[1000];
char hQuery[1000];
char xMsg[1000];
char xRow[400];
char xMAC[400];
char xIP[400];
char* xPass;

unsigned long lID;

MYSQL* cSQL::wStart()
{
	MYSQL* wSQL = mysql_init(NULL);

	try
	{
		my_bool reconnect = 1;
		const auto config = wyd::legacy::database::LoadFromEnvironment(
			HOST,
			USER,
			PASS,
			DB,
			PORT,
			300);
		unsigned int connectTimeoutSeconds = config.connectTimeoutSeconds;

		mysql_options(wSQL, MYSQL_OPT_RECONNECT, &reconnect);
		mysql_options(wSQL, MYSQL_OPT_COMPRESS, 0);
		mysql_options(wSQL, MYSQL_OPT_CONNECT_TIMEOUT, &connectTimeoutSeconds);

		if (!mysql_real_connect(
			wSQL,
			config.host.c_str(),
			config.user.c_str(),
			config.password.c_str(),
			config.database.c_str(),
			config.port,
			NULL,
			0))
		{
			printf("[wMySQL][TMSVR] Ocorreu um erro na conexão.\n\t\tErro: %s\n", mysql_error(wSQL));
			return wSQL;
		}

		return wSQL;
	}
	catch (...)
	{
		return wSQL;
	}
}

MYSQL_RES *cSQL::wRes(MYSQL *sql, char* query)
{
	try {
		if (mysql_query(sql, query))
		{
			printf("[wMySQL][wRes] Erro na execução da wRes.\nQuery: %s\n\t\tErro: %s\n", query, mysql_error(sql));
			mysql_close(sql);
			return NULL;
		}

		MYSQL_RES* result = mysql_store_result(sql);

		// Legacy ownership contract: wRes closes the MYSQL connection and
		// transfers ownership of the buffered MYSQL_RES to the caller.
		mysql_close(sql);

		if (result)
			return result;

		return NULL;
	}
	catch (...)
	{
		return NULL;
	}
}

void cSQL::wLog(char* acc, char* pers, char* mensagem, char* type)
{

	time_t rawtime;
	struct tm * timeinfo;

	time(&rawtime);
	timeinfo = localtime(&rawtime);

	sprintf(logQuery, "INSERT INTO `log` (`ID`, `Conta`, `Char`, `Mensagem`, `Data`, `Tipo`) VALUES(NULL, '%s', '%s', '%s', '%d/%d/%d %d:%d:%d', '%s')", acc, pers, mensagem, timeinfo->tm_mday, (timeinfo->tm_mon + 1), (timeinfo->tm_year + 1900), timeinfo->tm_hour, timeinfo->tm_min, timeinfo->tm_sec, type);
	////ThreadLog = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)wQuery, (void*)logQuery, 0, &lID);
	//cSQL::wQuery(xQuery);

	auto& pc = cSQL::instance();

	MYSQL* wSQL = pc.wStart();

	if (mysql_query(wSQL, logQuery))
	{
		printf("[wMySQL][Log] Erro na execução da wQuery.\n\t\tErro: %s\n", mysql_error(wSQL));
		mysql_close(wSQL);
		//ExitThread(0);
		return;
	}

	mysql_close(wSQL);

	printf("[%02d/%02d/%d][%02d:%02d:%02d][%s - %s] %s\n", timeinfo->tm_mday, (timeinfo->tm_mon + 1), (timeinfo->tm_year + 1900), timeinfo->tm_hour, timeinfo->tm_min, timeinfo->tm_sec, acc, pers, mensagem);
	return;
}

/// Executes a query.
bool cSQL::wQuery(char* query)
{
	try
	{
		auto& pc = cSQL::instance();

		MYSQL* wSQL = pc.wStart();

		if (mysql_query(wSQL, query))
		{
			printf("[wMySQL][wQuery] Erro na execução da wQuery.\n\t\tErro: %s\n", mysql_error(wSQL));
			mysql_close(wSQL);
			//ExitThread(0);
			return FALSE;
		}

		mysql_close(wSQL);
		//ExitThread(0);
		return TRUE;
	}
	catch (...)
	{
		return FALSE;
	}
}

int cSQL::Cont(char* query)
{
	int res = 0;
	auto& cnt = cSQL::instance();

	MYSQL* wSQL = cnt.wStart();
	MYSQL_RES* result = cnt.wRes(wSQL, query);

	if (result == NULL)
	{
		printf("[wMySQL][wInfo]: Ocorreu um erro ao retornar Dados.\n");
		return res;
	}

	res = (int)mysql_num_rows(result);

	mysql_free_result(result);
	return res;
}

int cSQL::iInfo(char* query)
{
	int res = 0;
	MYSQL_ROW row;

	auto& cnt = cSQL::instance();

	MYSQL* wSQL = cnt.wStart();
	MYSQL_RES* result = cnt.wRes(wSQL, query);

	if (result == NULL)
	{
		printf("[wMySQL][wInfo]: Ocorreu um erro ao retornar Dados.\n");
		return res;
	}

	while ((row = mysql_fetch_row(result)) != NULL)
		res = atoi(row[0]);

	mysql_free_result(result);
	return res;
}

long long cSQL::lInfo(char* query)
{
	long long res = 0;
	MYSQL_ROW row;

	auto& cnt = cSQL::instance();

	MYSQL* wSQL = cnt.wStart();
	MYSQL_RES* result = cnt.wRes(wSQL, query);

	if (result == NULL)
	{
		printf("[wMySQL][wInfo]: Ocorreu um erro ao retornar Dados.\n");
		return res;
	}

	while ((row = mysql_fetch_row(result)) != NULL)
		res = atoll(row[0]);

	mysql_free_result(result);
	return res;
}

char *cSQL::wInfo(char* query)
{
	static thread_local char res[1000];
	static char noResult[] = "0";

	memset(res, 0, sizeof(res));

	MYSQL_ROW row;

	auto& cnt = cSQL::instance();

	MYSQL* wSQL = cnt.wStart();
	MYSQL_RES* result = cnt.wRes(wSQL, query);

	if (result == NULL)
	{
		printf("[wMySQL][wInfo]: Ocorreu um erro ao retornar Dados.\n");
		return noResult;
	}

	while ((row = mysql_fetch_row(result)) != NULL)
	{
		if (row[0] == NULL)
			continue;

		strncpy(res, row[0], sizeof(res) - 1);
		res[sizeof(res) - 1] = 0;
	}

	mysql_free_result(result);
	return res;
}

uint32_t convert(const char* name)
{
	uint32_t val = uint32_t(name[3])
		+ (uint32_t(name[2]) << 8)
		+ (uint32_t(name[1]) << 16)
		+ (uint32_t(name[0]) << 24);
	return val;
}
