#include "Platform/Configuration/DatabaseConfig.h"

#include <cstdlib>
#include <iostream>
#include <string>

namespace
{
	int failures = 0;

	void ExpectEqual(unsigned int actual, unsigned int expected, const char* message)
	{
		if (actual != expected)
		{
			std::cerr << message << ": expected " << expected << ", got " << actual << '\n';
			++failures;
		}
	}

	void ExpectString(const std::string& actual, const char* expected, const char* message)
	{
		if (actual != expected)
		{
			std::cerr << message << ": expected '" << expected << "', got '" << actual << "'\n";
			++failures;
		}
	}

	void SetEnvironment(const char* name, const char* value)
	{
#ifdef _WIN32
		_putenv_s(name, value);
#else
		setenv(name, value, 1);
#endif
	}

	void ClearEnvironment(const char* name)
	{
#ifdef _WIN32
		_putenv_s(name, "");
#else
		unsetenv(name);
#endif
	}

	void ClearDatabaseEnvironment()
	{
		ClearEnvironment("WYD_DB_HOST");
		ClearEnvironment("WYD_DB_USER");
		ClearEnvironment("WYD_DB_PASSWORD");
		ClearEnvironment("WYD_DB_NAME");
		ClearEnvironment("WYD_DB_PORT");
		ClearEnvironment("WYD_DB_CONNECT_TIMEOUT_SECONDS");
	}
}

int main()
{
	using namespace wyd::platform::database;

	ExpectEqual(ParseBoundedUnsignedOrDefault(nullptr, 3306, 1, 65535), 3306, "null port falls back");
	ExpectEqual(ParseBoundedUnsignedOrDefault("", 3306, 1, 65535), 3306, "empty port falls back");
	ExpectEqual(ParseBoundedUnsignedOrDefault("3307", 3306, 1, 65535), 3307, "valid port parses");
	ExpectEqual(ParseBoundedUnsignedOrDefault("0", 3306, 1, 65535), 3306, "zero port falls back");
	ExpectEqual(ParseBoundedUnsignedOrDefault("65536", 3306, 1, 65535), 3306, "overflow port falls back");
	ExpectEqual(ParseBoundedUnsignedOrDefault("3306x", 3306, 1, 65535), 3306, "partial numeric port falls back");
	ExpectEqual(ParseBoundedUnsignedOrDefault("abc", 3306, 1, 65535), 3306, "non numeric port falls back");

	ClearDatabaseEnvironment();
	{
		const auto config = LoadFromEnvironment(
			"legacy-host",
			"legacy-user",
			"legacy-pass",
			"legacy-db",
			3306,
			300);

		ExpectString(config.host, "legacy-host", "host default");
		ExpectString(config.user, "legacy-user", "user default");
		ExpectString(config.password, "legacy-pass", "password default");
		ExpectString(config.database, "legacy-db", "database default");
		ExpectEqual(config.port, 3306, "port default");
		ExpectEqual(config.connectTimeoutSeconds, 300, "timeout default");
	}

	SetEnvironment("WYD_DB_HOST", "db.internal");
	SetEnvironment("WYD_DB_USER", "wyd_game");
	SetEnvironment("WYD_DB_PASSWORD", "test-only-password");
	SetEnvironment("WYD_DB_NAME", "wyd_test");
	SetEnvironment("WYD_DB_PORT", "3307");
	SetEnvironment("WYD_DB_CONNECT_TIMEOUT_SECONDS", "15");
	{
		const auto config = LoadFromEnvironment(
			"legacy-host",
			"legacy-user",
			"legacy-pass",
			"legacy-db",
			3306,
			300);

		ExpectString(config.host, "db.internal", "host environment override");
		ExpectString(config.user, "wyd_game", "user environment override");
		ExpectString(config.password, "test-only-password", "password environment override");
		ExpectString(config.database, "wyd_test", "database environment override");
		ExpectEqual(config.port, 3307, "port environment override");
		ExpectEqual(config.connectTimeoutSeconds, 15, "timeout environment override");
	}

	SetEnvironment("WYD_DB_PORT", "70000");
	SetEnvironment("WYD_DB_CONNECT_TIMEOUT_SECONDS", "0");
	{
		const auto config = LoadFromEnvironment(
			"legacy-host",
			"legacy-user",
			"legacy-pass",
			"legacy-db",
			3306,
			300);

		ExpectEqual(config.port, 3306, "invalid environment port falls back");
		ExpectEqual(config.connectTimeoutSeconds, 300, "invalid environment timeout falls back");
	}

	ClearDatabaseEnvironment();

	if (failures != 0)
	{
		std::cerr << failures << " database configuration assertion(s) failed\n";
		return EXIT_FAILURE;
	}

	std::cout << "database configuration tests passed\n";
	return EXIT_SUCCESS;
}
