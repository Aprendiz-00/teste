#pragma once

#include <cerrno>
#include <cstdlib>
#include <string>

namespace wyd::platform::database
{
	struct DatabaseConfig
	{
		std::string host;
		std::string user;
		std::string password;
		std::string database;
		unsigned int port;
		unsigned int connectTimeoutSeconds;
	};

	inline std::string EnvironmentOrDefault(const char* name, const char* fallback)
	{
		const char* value = std::getenv(name);
		if (value != nullptr && value[0] != '\0')
			return value;

		return fallback != nullptr ? fallback : "";
	}

	inline unsigned int ParseBoundedUnsignedOrDefault(
		const char* rawValue,
		unsigned int fallback,
		unsigned int minimum,
		unsigned int maximum) noexcept
	{
		if (rawValue == nullptr || rawValue[0] == '\0')
			return fallback;

		errno = 0;
		char* end = nullptr;
		const unsigned long parsed = std::strtoul(rawValue, &end, 10);

		if (errno != 0 || end == rawValue || *end != '\0')
			return fallback;

		if (parsed < minimum || parsed > maximum)
			return fallback;

		return static_cast<unsigned int>(parsed);
	}

	inline DatabaseConfig LoadFromEnvironment(
		const char* defaultHost,
		const char* defaultUser,
		const char* defaultPassword,
		const char* defaultDatabase,
		unsigned int defaultPort,
		unsigned int defaultConnectTimeoutSeconds)
	{
		DatabaseConfig config{};

		config.host = EnvironmentOrDefault("WYD_DB_HOST", defaultHost);
		config.user = EnvironmentOrDefault("WYD_DB_USER", defaultUser);
		config.password = EnvironmentOrDefault("WYD_DB_PASSWORD", defaultPassword);
		config.database = EnvironmentOrDefault("WYD_DB_NAME", defaultDatabase);
		config.port = ParseBoundedUnsignedOrDefault(
			std::getenv("WYD_DB_PORT"),
			defaultPort,
			1,
			65535);
		config.connectTimeoutSeconds = ParseBoundedUnsignedOrDefault(
			std::getenv("WYD_DB_CONNECT_TIMEOUT_SECONDS"),
			defaultConnectTimeoutSeconds,
			1,
			3600);

		return config;
	}
}
