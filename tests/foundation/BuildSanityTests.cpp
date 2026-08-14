#include "Foundation/BuildInfo.h"

#include <cstdlib>
#include <iostream>

int main()
{
    if (wyd::modern::kModernizationTrack != "foundation")
    {
        std::cerr << "unexpected modernization track\n";
        return EXIT_FAILURE;
    }

    if (wyd::modern::kArchitectureRevision < 1)
    {
        std::cerr << "invalid architecture revision\n";
        return EXIT_FAILURE;
    }

    std::cout << "modern foundation sanity check passed\n";
    return EXIT_SUCCESS;
}
